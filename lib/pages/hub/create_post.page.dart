import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/pages/hub/create_post.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final CreatePostComponent _component = CreatePostComponent();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _component.addListener(_onChanged);
    _component.initialize();
  }

  @override
  void dispose() {
    _component.removeListener(_onChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const ModeloNavbar(),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'hub'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.8),
            radius: 1.2,
            colors: [
              Color(0xFF273C67),
              Color(0xFF1a2847),
              Color(0xFF0d1525),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(bottom: false, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    if (_component.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (!_component.canCreatePosts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                color: VcomColors.oroLujoso,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No tienes permisos para publicar en Hub.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VcomColors.blancoCrema.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        _buildFieldLabel(icon: Icons.schedule, text: 'NOMBRE NOVEDAD'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: _component.setTitle,
          style: const TextStyle(color: VcomColors.blancoCrema, fontSize: 30),
          decoration: InputDecoration(
            hintText: 'Escribe aqui el titulo',
            hintStyle: TextStyle(
              color: VcomColors.blancoCrema.withValues(alpha: 0.45),
              fontSize: 32,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: VcomColors.oroLujoso, width: 1.2),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: VcomColors.oroLujoso, width: 1.2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: VcomColors.oroBrillante,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel(icon: Icons.grid_view_rounded, text: 'CATEGORIA'),
        const SizedBox(height: 8),
        _buildTagDropdown(),
        const SizedBox(height: 20),
        _buildFieldLabel(icon: Icons.edit_outlined, text: 'DESCRIPCION'),
        const SizedBox(height: 8),
        _buildDescriptionField(),
        const SizedBox(height: 20),
        _buildMediaPicker(),
        if (_component.media.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMediaPreview(),
        ],
        const SizedBox(height: 24),
        _buildPublishButton(),
        if (_component.error != null) ...[
          const SizedBox(height: 10),
          Text(
            _component.error!,
            style: const TextStyle(color: VcomColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldLabel({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: VcomColors.blancoCrema.withValues(alpha: 0.5),
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: VcomColors.blancoCrema.withValues(alpha: 0.35),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTagDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: VcomColors.azulOverlayTransparente50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButton<int>(
        value: _component.selectedTagId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF14223B),
        style: const TextStyle(color: VcomColors.blancoCrema, fontSize: 16),
        iconEnabledColor: VcomColors.blancoCrema.withValues(alpha: 0.6),
        items: _component.tags
            .map(
              (tag) =>
                  DropdownMenuItem<int>(value: tag.id, child: Text(tag.name)),
            )
            .toList(growable: false),
        onChanged: _component.setTag,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: VcomColors.oroLujoso, width: 1.1),
        ),
      ),
      child: TextField(
        controller: _descriptionController,
        onChanged: _component.setDescription,
        maxLines: 5,
        minLines: 4,
        style: const TextStyle(color: VcomColors.blancoCrema),
        decoration: InputDecoration(
          hintText: 'Comparte el detalle de tu publicacion...',
          hintStyle: TextStyle(
            color: VcomColors.blancoCrema.withValues(alpha: 0.45),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMediaPicker() {
    return InkWell(
      onTap: _openMediaPickerOptions,
      borderRadius: BorderRadius.circular(16),
      child: DottedBorder(
        color: Colors.white.withValues(alpha: 0.28),
        dashPattern: const [7, 5],
        strokeWidth: 1.2,
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: Container(
          height: 72,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 10),
              Text(
                'AGREGAR IMAGEN O VIDEO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _component.media.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = _component.media[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 110,
                  height: 96,
                  color: const Color(0xFF111D33),
                  child: item.type == HubMediaType.image
                      ? Image.file(
                          File(item.url),
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                          ),
                        )
                      : Container(
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: VcomColors.oroLujoso,
                            size: 34,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => _component.removeMedia(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _component.isSubmitting ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: VcomColors.oroLujoso,
          foregroundColor: VcomColors.azulMedianocheTexto,
          disabledBackgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _component.isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.1,
                  color: VcomColors.azulMedianocheTexto,
                ),
              )
            : const Text(
                'Publicar',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _openMediaPickerOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1528),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  onTap: () async {
                    Navigator.pop(context);
                    await _component.pickImage();
                  },
                  leading: const Icon(
                    Icons.image_outlined,
                    color: VcomColors.oroLujoso,
                  ),
                  title: const Text(
                    'Agregar imagen',
                    style: TextStyle(color: VcomColors.blancoCrema),
                  ),
                ),
                ListTile(
                  onTap: () async {
                    Navigator.pop(context);
                    await _component.pickVideo();
                  },
                  leading: const Icon(
                    Icons.movie_outlined,
                    color: VcomColors.oroLujoso,
                  ),
                  title: const Text(
                    'Agregar video',
                    style: TextStyle(color: VcomColors.blancoCrema),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _publish() async {
    final post = await _component.publish();
    if (!mounted) return;
    if (post == null) return;

    Navigator.pop(context, post);
  }
}
