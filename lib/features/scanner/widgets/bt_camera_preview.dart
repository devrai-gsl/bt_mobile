import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:bt_mobile/core/services/camera_service.dart';

/// Live rear-camera preview for QC recording and similar flows.
class BtCameraPreview extends StatefulWidget {
  const BtCameraPreview({super.key});

  @override
  State<BtCameraPreview> createState() => _BtCameraPreviewState();
}

class _BtCameraPreviewState extends State<BtCameraPreview> {
  CameraController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final granted = await ensureCameraPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _error = 'Camera permission denied');
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to open camera');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return CameraPreview(controller);
    }
    if (_error != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
