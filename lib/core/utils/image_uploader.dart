import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploader {
  static Future<String?> uploadImage({
    required String bucketName,
    required String pathPrefix,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      final client = Supabase.instance.client;
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$pathPrefix/$fileName';

      String contentType = 'image/jpeg';
      if (fileExt == 'png') {
        contentType = 'image/png';
      } else if (fileExt == 'gif') {
        contentType = 'image/gif';
      } else if (fileExt == 'webp') {
        contentType = 'image/webp';
      }

      await client.storage.from(bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );

      final String publicUrl = client.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
}
