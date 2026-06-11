import 'dart:io';
import 'package:cloudinary/cloudinary.dart';

class StorageService {
  late final Cloudinary _cloudinary;

  StorageService() {
    // Silakan isi kredensial Cloudinary Anda di sini
    _cloudinary = Cloudinary.signedConfig(
      apiKey: '282769561883655',
      apiSecret: '7tmyVVX3uQ9oUASKrXw4w2iOi9w',
      cloudName: 'dls3yehlx',
    );
  }

  Future<String> uploadTransactionEvidence(
    File imageFile,
    String userId,
  ) async {
    try {
      // Penamaan file agar rapi dan unik
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _cloudinary.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder:
            'evidences', // Akan membuat folder 'evidences' otomatis di Cloudinary
        fileName: fileName,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        // Mengembalikan URL HTTPS dari gambar yang diupload
        return response.secureUrl!;
      } else {
        throw Exception(
          response.error ?? 'Unknown error occurred during upload',
        );
      }
    } catch (e) {
      throw Exception('Gagal mengunggah gambar ke Cloudinary: ${e.toString()}');
    }
  }

  Future<String> uploadNewsImage(File imageFile) async {
    try {
      final String fileName = 'news_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _cloudinary.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'news', // Folder khusus berita di Cloudinary
        fileName: fileName,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl!;
      } else {
        throw Exception(
          response.error ?? 'Unknown error occurred during upload',
        );
      }
    } catch (e) {
      throw Exception('Gagal mengunggah gambar berita: ${e.toString()}');
    }
  }
}
