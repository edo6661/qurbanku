import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DatabaseSeeder {
  static Future<void> seedInitialData(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memulai proses seeding data...')),
    );

    try {
      UserCredential adminCred = await auth.createUserWithEmailAndPassword(
        email: 'admin@qurbanku.com',
        password: 'password123',
      );

      await firestore.collection('users').doc(adminCred.user!.uid).set({
        'uid': adminCred.user!.uid,
        'name': 'Admin Masjid',
        'email': 'admin@qurbanku.com',
        'role': 'admin',
      });

      UserCredential pesertaCred = await auth.createUserWithEmailAndPassword(
        email: 'peserta@qurbanku.com',
        password: 'password123',
      );

      await firestore.collection('users').doc(pesertaCred.user!.uid).set({
        'uid': pesertaCred.user!.uid,
        'name': 'Fulan (Peserta)',
        'email': 'peserta@qurbanku.com',
        'role': 'peserta',
      });

      const targetId = 'target_sapi_01';
      await firestore.collection('saving_targets').doc(targetId).set({
        'id': targetId,
        'animal_type': 'Sapi Limosin (Patungan 7 Orang)',
        'target_amount': 3500000.0,
      });

      final savingRef = firestore.collection('user_savings').doc();
      await savingRef.set({
        'id': savingRef.id,
        'user_id': pesertaCred.user!.uid,
        'target_id': targetId,
        'current_balance': 0.0,
        'status': 'active',
      });

      await auth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seeding Berhasil! Silakan login dengan akun yang dibuat.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data seeder sudah pernah dijalankan (Email sudah ada).',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        debugPrint('Auth Error: ${e.message}');
      }
    } catch (e) {
      debugPrint('Seeding Error: $e');
    }
  }

  static Future<void> clearTransactionData(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memulai pembersihan data transaksi & tabungan...'),
      ),
    );

    try {
      // Daftar tabel yang ingin DIHAPUS (Users dan Saving Targets aman karena tidak ditulis di sini)
      final collectionsToClear = [
        'transactions',
        'user_savings',
        'notifications',
      ];

      for (String collectionPath in collectionsToClear) {
        final snapshot = await firestore.collection(collectionPath).get();
        final batch = firestore.batch();

        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit(); // Eksekusi penghapusan massal per tabel
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data transaksi, tabungan, dan notifikasi berhasil dibersihkan!',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membersihkan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
