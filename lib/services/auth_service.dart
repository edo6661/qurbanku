import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login gagal: User tidak ditemukan.');
      }
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Data pengguna tidak ditemukan di database.');
      }
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = firebaseUser.uid;

      // ====================================================
      // 2. KODE YANG DITAMBAH: Ambil & Simpan FCM Token
      // ====================================================
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(firebaseUser.uid).update({
            'fcm_token': fcmToken,
          });
        }
      } catch (e) {
        // Abaikan jika gagal agar proses login utama tidak terganggu
        print('Gagal menyimpan FCM Token: $e');
      }
      // ====================================================

      return UserModel.fromJson(data);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  Future<UserModel> updateUserProfile({
    required String uid,
    required String name,
    String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      });

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Data pengguna tidak ditemukan.');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = uid;
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential': // ← TAMBAH INI
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'email-already-in-use':
        return 'Email ini sudah digunakan oleh akun lain.';
      case 'weak-password':
        return 'Password terlalu lemah, minimal 6 karakter.';
      default:
        return 'Terjadi kesalahan otentikasi: $errorCode';
    }
  }

  Future<UserModel> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Registrasi gagal: User tidak dapat dibuat.');
      }

      // Buat data UserModel dengan role default 'peserta'
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        role: UserRole.peserta,
      );

      // Simpan data profil ke collection 'users'
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toJson());

      // Simpan FCM Token jika ada (agar notifikasi bisa masuk ke user baru)
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(firebaseUser.uid).update({
            'fcm_token': fcmToken,
          });
        }
      } catch (e) {
        print('Gagal menyimpan FCM Token saat register: $e');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
