// lib/services/camera_service.dart
// Handles image picking from camera or gallery.

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the device camera and returns the captured image as a [File].
  /// Returns null if the user cancels.
  Future<File?> captureFromCamera() async {
    final XFile? xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Opens the image gallery and returns the selected image as a [File].
  /// Returns null if the user cancels.
  Future<File?> pickFromGallery() async {
    final XFile? xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }
}
