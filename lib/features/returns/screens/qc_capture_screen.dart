import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/services/camera_service.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

enum _CaptureStep { viewfinder, preview }

class QcCaptureScreen extends StatefulWidget {
  const QcCaptureScreen({
    super.key,
    required this.itemName,
    required this.badReason,
  });

  final String itemName;
  final String badReason;

  @override
  State<QcCaptureScreen> createState() => _QcCaptureScreenState();
}

class _QcCaptureScreenState extends State<QcCaptureScreen> {
  final _repo = ReturnsRepository();
  late final Future<QcCaptureConfig> _configFuture = _repo.getQcCaptureConfig();

  _CaptureStep _step = _CaptureStep.viewfinder;
  String? _selectedTag;
  final List<String> _captured = [];
  Uint8List? _previewBytes;
  bool _capturing = false;

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    final bytes = await capturePhoto(context);
    if (!mounted) return;
    setState(() {
      _capturing = false;
      if (bytes != null) {
        _previewBytes = bytes;
        _step = _CaptureStep.preview;
      }
    });
  }

  void _saveCapture(QcCaptureConfig config) {
    if (_selectedTag == null) return;
    setState(() {
      _captured.add(_selectedTag!);
      _selectedTag = null;
      _previewBytes = null;
      _step = _CaptureStep.viewfinder;
    });
    if (_captured.length >= config.minImages) {
      Navigator.pop(context, _captured.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<QcCaptureConfig>(
        future: _configFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final config = snapshot.data!;

          if (_step == _CaptureStep.preview) {
            return _PreviewStep(
              title: config.previewTitle,
              itemName: widget.itemName,
              imageBytes: _previewBytes,
              tags: config.imageTags,
              selectedTag: _selectedTag,
              capturedCount: _captured.length,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
              onRetake: () => setState(() {
                _previewBytes = null;
                _step = _CaptureStep.viewfinder;
              }),
              onSave: () => _saveCapture(config),
            );
          }

          return _ViewfinderStep(
            hint: config.viewfinderHint,
            itemName: widget.itemName,
            badReason: widget.badReason,
            capturedCount: _captured.length,
            minImages: config.minImages,
            capturing: _capturing,
            onCapture: _capture,
            onClose: () => Navigator.pop(context, _captured.length),
          );
        },
      ),
    );
  }
}

class _ViewfinderStep extends StatelessWidget {
  const _ViewfinderStep({
    required this.hint,
    required this.itemName,
    required this.badReason,
    required this.capturedCount,
    required this.minImages,
    required this.capturing,
    required this.onCapture,
    required this.onClose,
  });

  final String hint;
  final String itemName;
  final String badReason;
  final int capturedCount;
  final int minImages;
  final bool capturing;
  final VoidCallback onCapture;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                BtColors.brandGreen.withValues(alpha: 0.2),
                Colors.black87,
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(BtSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capture Image',
                            style: BtTypography.headingLgSemibold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            itemName,
                            style: BtTypography.bodySmRegular.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$capturedCount captured',
                      style: BtTypography.bodySmSemibold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(BtSpacing.xl),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54, width: 2),
                      borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(BtSpacing.xl),
                        child: Text(
                          hint,
                          textAlign: TextAlign.center,
                          style: BtTypography.bodyMdMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BtSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bad reason: $badReason',
                      style: BtTypography.bodySmRegular.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: BtSpacing.md),
                    BtPrimaryButton(
                      label: capturedCount >= minImages ? 'Done' : 'Open Camera',
                      loading: capturing,
                      onPressed: capturedCount >= minImages ? onClose : onCapture,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.title,
    required this.itemName,
    required this.imageBytes,
    required this.tags,
    required this.selectedTag,
    required this.capturedCount,
    required this.onTagSelected,
    required this.onRetake,
    required this.onSave,
  });

  final String title;
  final String itemName;
  final Uint8List? imageBytes;
  final List<String> tags;
  final String? selectedTag;
  final int capturedCount;
  final ValueChanged<String> onTagSelected;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: Text(
                title,
                style: BtTypography.headingLgSemibold.copyWith(color: Colors.white),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: BtSpacing.lg),
                decoration: BoxDecoration(
                  color: BtColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : Center(child: Text(itemName, style: BtTypography.bodyMdMedium)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tag image',
                    style: BtTypography.bodyMdMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: BtSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      final selected = selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag),
                        selected: selected,
                        onSelected: (_) => onTagSelected(tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: BtSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: BtOutlineButton(
                          label: 'Retake',
                          onPressed: onRetake,
                        ),
                      ),
                      const SizedBox(width: BtSpacing.md),
                      Expanded(
                        child: BtPrimaryButton(
                          label: 'SAVE',
                          onPressed: selectedTag == null ? null : onSave,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BtSpacing.sm),
                  Text(
                    '$capturedCount image(s) captured',
                    style: BtTypography.bodySmRegular.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
