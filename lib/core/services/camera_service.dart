import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera permission and capture helpers used by scanner and QC flows.
class CameraService {
  const CameraService();

  Future<bool> ensurePermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<Uint8List?> capturePhoto(BuildContext context) async {
    final granted = await ensurePermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return null;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}

/// Shared instance for call sites that do not use DI yet.
const cameraService = CameraService();

Future<bool> ensureCameraPermission() => cameraService.ensurePermission();

Future<Uint8List?> capturePhoto(BuildContext context) =>
    cameraService.capturePhoto(context);
