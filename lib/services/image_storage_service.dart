import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Captura una imagen con la cámara o la galería y la guarda permanentemente
  /// en el almacenamiento local de la app.
  Future<String?> pickAndSaveImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/inventory_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = pickedFile.name.split('.').last;
      final fileName = 'img_${const Uuid().v4()}.$ext';
      final savedFile = File('${imagesDir.path}/$fileName');

      await File(pickedFile.path).copy(savedFile.path);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error al capturar/guardar imagen: $e');
      return null;
    }
  }

  /// Elimina una imagen del almacenamiento local si existe.
  Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error al eliminar imagen: $e');
    }
  }
}
