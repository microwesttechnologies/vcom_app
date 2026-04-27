import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';

/// Lógica de negocio para tags del Hub.
class TagsComponent extends ChangeNotifier {
  final HubTagsService _tagsService = HubTagsService();

  List<HubTag> _tags = const [];
  HubTag? _selectedTag;

  List<HubTag> get tags => _tags;
  HubTag? get selectedTag => _selectedTag;

  Future<void> loadTags() async {
    try {
      _tags = await _tagsService.fetchTags();
    } catch (_) {
      _tags = const [];
    } finally {
      notifyListeners();
    }
  }

  void selectTag(HubTag? tag) {
    _selectedTag = tag;
    notifyListeners();
  }
}
