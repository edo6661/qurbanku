import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<String> uploadTransactionEvidence(
    File imageFile,
    String userId,
  ) async {
    try {
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'evidences/$fileName';

      await _supabase.storage
          .from('qurbanku')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = _supabase.storage
          .from('qurbanku')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal mengunggah gambar: ${e.toString()}');
    }
  }
}
