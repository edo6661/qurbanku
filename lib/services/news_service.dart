import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import 'storage_service.dart';

class NewsService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  NewsService({
    FirebaseFirestore? firestore,
    required StorageService storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storageService = storageService;

  // READ: Dapatkan stream berita (diurutkan dari yang terbaru)
  Stream<List<NewsModel>> getNewsStream() {
    return _firestore
        .collection('news')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return NewsModel.fromJson(data);
          }).toList();
        });
  }

  // CREATE: Tambah berita baru
  Future<void> createNews({
    required String title,
    required String description,
    required File imageFile,
  }) async {
    // 1. Upload gambar dulu ke Cloudinary
    final imageUrl = await _storageService.uploadNewsImage(imageFile);

    // 2. Simpan data ke Firestore
    final docRef = _firestore.collection('news').doc();
    final news = NewsModel(
      id: docRef.id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await docRef.set(news.toJson());
  }

  // UPDATE: Edit berita
  Future<void> updateNews({
    required String id,
    required String title,
    required String description,
    File? newImageFile,
    required String currentImageUrl,
  }) async {
    String imageUrl = currentImageUrl;

    // Jika admin mengganti gambar, upload gambar baru
    if (newImageFile != null) {
      imageUrl = await _storageService.uploadNewsImage(newImageFile);
    }

    await _firestore.collection('news').doc(id).update({
      'title': title,
      'description': description,
      'image_url': imageUrl,
    });
  }

  // DELETE: Hapus berita
  Future<void> deleteNews(String id) async {
    await _firestore.collection('news').doc(id).delete();
  }
}
