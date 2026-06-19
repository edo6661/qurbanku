import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qurban_ku/models/notification_model.dart.dart';
import 'package:qurban_ku/services/fcm_service.dart';
import 'package:qurban_ku/utils/currency_formatter.dart';
import '../models/saving_target_model.dart';
import '../models/user_saving_model.dart';
import '../models/transaction_model.dart';

class SavingsService {
  final FirebaseFirestore _firestore;
  SavingsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  Stream<UserSavingModel?> getUserSavingStream(String userId) {
    return _firestore
        .collection('user_savings')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final data = snapshot.docs.first.data();
          data['id'] = snapshot.docs.first.id;
          return UserSavingModel.fromJson(data);
        });
  }

  Future<SavingTargetModel> getTargetDetail(String targetId) async {
    final doc = await _firestore
        .collection('saving_targets')
        .doc(targetId)
        .get();
    if (!doc.exists) throw Exception('Target tabungan tidak ditemukan');
    final data = doc.data()!;
    data['id'] = doc.id;
    return SavingTargetModel.fromJson(data);
  }

  Future<void> submitTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

      await _sendNotification(
        'admin',
        'Setoran Baru!',
        'Ada setoran baru dari ${transaction.namaPenabung} (A.n. ${transaction.namaPengkurban}) sebesar ${CurrencyFormatter.toRupiah(transaction.amount)}. Mohon segera diverifikasi.',

        referenceId: transaction.id,
      );
    } catch (e) {
      throw Exception('Gagal mengirim transaksi: ${e.toString()}');
    }
  }

  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TransactionModel.fromJson(data);
          }).toList();
        });
  }

  Stream<List<TransactionModel>> getPendingTransactionsStream() {
    return _firestore
        .collection('transactions')
        .where('status', isEqualTo: TransactionStatus.pending.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TransactionModel.fromJson(data);
          }).toList();
        });
  }

  Future<void> approveTransaction(
    TransactionModel transaction, {
    required String adminNote,
  }) async {
    final savingDocRef = _firestore
        .collection('user_savings')
        .doc(transaction.savingId);
    final transactionDocRef = _firestore
        .collection('transactions')
        .doc(transaction.id);
    bool isFullyPaid = false;
    String targetAnimalName = '';
    await _firestore.runTransaction((tx) async {
      final savingSnapshot = await tx.get(savingDocRef);
      if (!savingSnapshot.exists) {
        throw Exception('Tabungan tidak valid atau sudah dihapus');
      }
      final currentBalance =
          (savingSnapshot.data()?['current_balance'] as num?)?.toDouble() ??
          0.0;
      final newBalance = currentBalance + transaction.amount;
      final targetId = savingSnapshot.data()!['target_id'] as String;

      final targetSnapshot = await tx.get(
        _firestore.collection('saving_targets').doc(targetId),
      );
      if (targetSnapshot.exists) {
        final targetAmount = (targetSnapshot.data()!['target_amount'] as num)
            .toDouble();
        targetAnimalName = targetSnapshot.data()!['animal_type'] as String;
        if (newBalance >= targetAmount) {
          isFullyPaid = true;
        }
      }

      tx.update(transactionDocRef, {
        'status': TransactionStatus.approved.name,
        'admin_note': adminNote,
      });

      tx.update(savingDocRef, {
        'current_balance': newBalance,
        'updated_at': Timestamp.now(),
      });
    });

    await _sendNotification(
      transaction.userId,
      'Setoran Diterima',
      'Setoran Anda sebesar ${CurrencyFormatter.toRupiah(transaction.amount)} untuk atas nama ${transaction.namaPengkurban} telah diverifikasi. Catatan: $adminNote',

      referenceId: transaction.id,
    );
    if (isFullyPaid) {
      await _sendNotification(
        transaction.userId,
        'Alhamdulillah, Lunas!',
        'Tabungan kurban untuk target $targetAnimalName (A.n. ${transaction.namaPengkurban}) sudah mencapai 100%.',
      );
      await _sendNotification(
        'admin',
        'Target 100% Tercapai',
        'Tabungan kurban peserta A.n. ${transaction.namaPengkurban} untuk target $targetAnimalName telah lunas.',
      );
    }
  }

  Future<void> rejectTransaction(String transactionId, String adminNote) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': TransactionStatus.rejected.name,
      'admin_note': adminNote,
    });

    final txDoc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();
    if (txDoc.exists) {
      final userId = txDoc.data()!['user_id'] as String;
      final nama = txDoc.data()!['nama_pengkurban'] as String? ?? '-';
      await _sendNotification(
        userId,
        'Setoran Ditolak',
        'Mohon maaf, setoran Anda (A.n. $nama) ditolak. Alasan: $adminNote. Silakan perbaiki setoran Anda.',
      );
    }
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required String evidenceUrl,
  }) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'amount': amount,
      'evidence_url': evidenceUrl,
      'status': TransactionStatus.pending.name,
      'admin_note': FieldValue.delete(),
      'created_at': Timestamp.now(),
    });
  }

  Stream<List<SavingTargetModel>> getTargetsStream() {
    return _firestore.collection('saving_targets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SavingTargetModel.fromJson(data);
      }).toList();
    });
  }

  Future<void> saveTarget(SavingTargetModel target) async {
    final docRef = target.id.isEmpty
        ? _firestore.collection('saving_targets').doc()
        : _firestore.collection('saving_targets').doc(target.id);

    final data = target.toJson();
    data['id'] = docRef.id;
    await docRef.set(data);
  }

  Future<void> deleteTarget(String targetId) async {
    await _firestore.collection('saving_targets').doc(targetId).delete();
  }

  Stream<List<TransactionModel>> getAllTransactionsHistoryStream() {
    return _firestore
        .collection('transactions')
        .where(
          'status',
          whereIn: [
            TransactionStatus.approved.name,
            TransactionStatus.rejected.name,
          ],
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TransactionModel.fromJson(data);
          }).toList();
        });
  }

  Future<void> joinTarget(
    String userId,
    String targetId,
    String namaPengkurban,
    String binBinti,
  ) async {
    final savingRef = _firestore.collection('user_savings').doc();
    await savingRef
        .set({
          'id': savingRef.id,
          'user_id': userId,
          'target_id': targetId,
          'current_balance': 0.0,
          'status': 'active',
          'nama_pengkurban': namaPengkurban,
          'bin_binti': binBinti,
          'updated_at': Timestamp.now(),
        })
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Koneksi ke Firestore terputus (Timeout).');
          },
        );
  }

  Stream<List<UserSavingModel>> getUserSavingsStream(String userId) {
    return _firestore
        .collection('user_savings')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();

          docs.sort((a, b) {
            final dataA = a.data();
            final dataB = b.data();

            final dateA =
                (dataA['updated_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final dateB =
                (dataB['updated_at'] as Timestamp?)?.toDate() ?? DateTime(2000);

            return dateB.compareTo(dateA);
          });

          return docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return UserSavingModel.fromJson(data);
          }).toList();
        });
  }

  Future<UserSavingModel> getSavingDetail(String savingId) async {
    final doc = await _firestore.collection('user_savings').doc(savingId).get();
    if (!doc.exists) throw Exception('Data tabungan tidak ditemukan');
    final data = doc.data()!;
    data['id'] = doc.id;
    return UserSavingModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getAllUserSavingsWithDetail() async {
    final savingsSnapshot = await _firestore.collection('user_savings').get();
    List<Map<String, dynamic>> results = [];

    for (var doc in savingsSnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final saving = UserSavingModel.fromJson(data);

      try {
        final target = await getTargetDetail(saving.targetId);
        double progressPercentage =
            (saving.currentBalance / target.targetAmount) * 100;
        if (progressPercentage > 100.0) progressPercentage = 100.0;

        results.add({
          'saving': saving,
          'target': target,
          'progressPercentage': progressPercentage,
        });
      } catch (e) {}
    }
    return results;
  }

  Stream<List<NotificationModel>> getNotificationsStream(String targetUser) {
    return _firestore
        .collection('notifications')
        .where('target_user', isEqualTo: targetUser)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return NotificationModel.fromJson(data);
          }).toList();
        });
  }

  Future<void> markNotificationAsRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({
      'is_read': true,
    });
  }

  Future<void> _sendNotification(
    String target,
    String title,
    String msg, {
    String? referenceId,
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    await docRef.set({
      'id': docRef.id,
      'target_user': target,
      'title': title,
      'message': msg,
      'is_read': false,
      'created_at': Timestamp.now(),
      if (referenceId != null) 'reference_id': referenceId,
    });

    try {
      String? targetFcmToken;
      if (target == 'admin') {
        final adminQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();
        if (adminQuery.docs.isNotEmpty) {
          targetFcmToken =
              adminQuery.docs.first.data()['fcm_token']
                  as String?; // ← pakai String? bukan String
          print('✅ FCM Token admin: $targetFcmToken');
        } else {
          print('❌ Admin tidak ditemukan di Firestore');
        }
      } else {
        final userDoc = await _firestore.collection('users').doc(target).get();
        if (userDoc.exists) {
          targetFcmToken =
              userDoc.data()!['fcm_token'] as String?; // ← pakai String?
          print('✅ FCM Token user: $targetFcmToken');
        } else {
          print('❌ User $target tidak ditemukan');
        }
      }

      if (targetFcmToken != null) {
        print('🚀 Mengirim push notif ke: $targetFcmToken');
        await FcmService.sendNotification(
          deviceToken: targetFcmToken,
          title: title,
          body: msg,
        );
      } else {
        print('❌ FCM Token null, push notif tidak dikirim');
      }
    } catch (e) {
      print('Push Notif Error: $e');
    }
  }

  Stream<List<TransactionModel>> getTransactionsBySavingIdStream(
    String savingId,
  ) {
    return _firestore
        .collection('transactions')
        .where('saving_id', isEqualTo: savingId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TransactionModel.fromJson(data);
          }).toList();
        });
  }

  Future<TransactionModel> getTransactionById(String transactionId) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();
    if (!doc.exists) throw Exception('Transaksi tidak ditemukan');
    final data = doc.data()!;
    data['id'] = doc.id;
    return TransactionModel.fromJson(data);
  }

  Future<bool> hasPendingTransaction(String savingId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('saving_id', isEqualTo: savingId)
        .where('status', isEqualTo: TransactionStatus.pending.name)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return '-';
    return doc.data()?['name'] as String? ?? '-';
  }

  Future<void> completeSaving(String savingId) async {
    await _firestore.collection('user_savings').doc(savingId).update({
      'status': 'completed',
    });
  }

  Future<void> markAllNotificationsAsRead(String targetUser) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('target_user', isEqualTo: targetUser)
        .where('is_read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getAllUserSavingsWithDetailStream() {
    return _firestore.collection('user_savings').snapshots().asyncMap((
      snapshot,
    ) async {
      List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final saving = UserSavingModel.fromJson(data);
        try {
          final target = await getTargetDetail(saving.targetId);
          double progressPercentage =
              (saving.currentBalance / target.targetAmount) * 100;
          if (progressPercentage > 100.0) progressPercentage = 100.0;

          Timestamp? updatedAt = data['updated_at'] as Timestamp?;
          DateTime updateTime = updatedAt?.toDate() ?? DateTime(2000);

          results.add({
            'saving': saving,
            'target': target,
            'progressPercentage': progressPercentage,
            'updatedAt': updateTime,
          });
        } catch (e) {}
      }

      results.sort((a, b) {
        DateTime dateA = a['updatedAt'] as DateTime;
        DateTime dateB = b['updatedAt'] as DateTime;
        return dateB.compareTo(dateA);
      });

      return results;
    });
  }
}
