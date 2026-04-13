import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/core/models/hub_post.model.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';

class CreatePostComponent extends ChangeNotifier {
  CreatePostComponent({HubComponent? hubComponent})
    : _hubComponent = hubComponent ?? HubComponent();

  final HubComponent _hubComponent;
  final ImagePicker _picker = ImagePicker();
  final TokenService _tokenService = TokenService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<HubTagModel> _tags = const [];
  int? _selectedTagId;
  String _title = '';
  String _description = '';
  List<HubMediaModel> _media = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<HubTagModel> get tags => List.unmodifiable(_tags);
  int? get selectedTagId => _selectedTagId;
  String get title => _title;
  String get description => _description;
  List<HubMediaModel> get media => List.unmodifiable(_media);

  bool get canCreatePosts {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'ADMIN' || role == 'MONITOR';
  }

  bool get canPublish {
    final composedContent = _composeContent();
    return _selectedTagId != null &&
        (composedContent.isNotEmpty || _media.isNotEmpty);
  }

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_hubComponent.tags.isEmpty) {
        await _hubComponent.initialize();
      }
      _tags = _hubComponent.tags;
      _selectedTagId = _tags.isNotEmpty ? _tags.first.id : null;
    } catch (e) {
      _error = 'No fue posible cargar categorias: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setTag(int? id) {
    _selectedTagId = id;
    notifyListeners();
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    final entry = HubMediaModel(
      id: 'local-image-${DateTime.now().microsecondsSinceEpoch}',
      type: HubMediaType.image,
      url: file.path,
      sortOrder: _media.length + 1,
      isLocal: true,
    );
    _media = [..._media, entry];
    notifyListeners();
  }

  Future<void> pickVideo({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 2),
    );
    if (file == null) return;

    final entry = HubMediaModel(
      id: 'local-video-${DateTime.now().microsecondsSinceEpoch}',
      type: HubMediaType.video,
      url: file.path,
      sortOrder: _media.length + 1,
      isLocal: true,
    );
    _media = [..._media, entry];
    notifyListeners();
  }

  void removeMedia(String mediaId) {
    _media = _media.where((item) => item.id != mediaId).toList(growable: false);
    notifyListeners();
  }

  Future<HubPostModel?> publish() async {
    if (!canCreatePosts) {
      _error = 'Solo admin y monitor pueden crear publicaciones.';
      notifyListeners();
      return null;
    }

    if (!canPublish) {
      _error = 'Selecciona una categoria y agrega contenido o media.';
      notifyListeners();
      return null;
    }

    final tag = _tags.firstWhere(
      (entry) => entry.id == _selectedTagId,
      orElse: () => _tags.first,
    );

    _error = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      final post = await _hubComponent.createPost(
        tag: tag,
        content: _composeContent(),
        media: _media,
      );
      return post;
    } catch (e) {
      _error = 'No fue posible publicar: $e';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _composeContent() {
    final normalizedTitle = _title.trim();
    final normalizedDescription = _description.trim();

    if (normalizedTitle.isNotEmpty && normalizedDescription.isNotEmpty) {
      return '$normalizedTitle\n\n$normalizedDescription';
    }
    if (normalizedTitle.isNotEmpty) return normalizedTitle;
    return normalizedDescription;
  }
}
