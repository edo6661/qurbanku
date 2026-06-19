import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/transaction_model.dart';
import '../../services/savings_service.dart';
import '../../services/storage_service.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final StorageService _storageService;
  final SavingsService _savingsService;

  TransactionBloc({
    required StorageService storageService,
    required SavingsService savingsService,
  }) : _storageService = storageService,
       _savingsService = savingsService,
       super(TransactionInitial()) {
    on<SubmitTransaction>(_onSubmitTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
  }

  Future<void> _onSubmitTransaction(
    SubmitTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionSubmitting());
    try {
      final hasPending = await _savingsService.hasPendingTransaction(
        event.savingId,
      );
      if (hasPending) {
        emit(
          const TransactionError(
            'Masih ada setoran yang menunggu verifikasi admin. '
            'Tunggu hingga disetujui atau ditolak sebelum setor lagi.',
          ),
        );
        return;
      }

      final savingDetail = await _savingsService.getSavingDetail(
        event.savingId,
      );

      final String evidenceUrl = await _storageService
          .uploadTransactionEvidence(event.evidenceImage, event.userId);
      final transactionId = FirebaseFirestore.instance
          .collection('transactions')
          .doc()
          .id;

      final transaction = TransactionModel(
        id: transactionId,
        userId: event.userId,
        savingId: event.savingId,
        amount: event.amount,
        evidenceUrl: evidenceUrl,
        status: TransactionStatus.pending,
        createdAt: DateTime.now(),
        namaPengkurban: savingDetail.namaPengkurban,
        binBinti: savingDetail.binBinti,
        namaPenabung: event.namaPenabung,
      );

      await _savingsService.submitTransaction(transaction);
      emit(TransactionSuccess());
    } catch (e) {
      emit(TransactionError('Gagal mengirim transaksi: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionSubmitting());
    try {
      String evidenceUrl = event.currentEvidenceUrl;

      if (event.newEvidenceImage != null) {
        evidenceUrl = await _storageService.uploadTransactionEvidence(
          event.newEvidenceImage!,
          event.userId,
        );
      }

      await _savingsService.updateTransaction(
        transactionId: event.transactionId,
        amount: event.amount,
        evidenceUrl: evidenceUrl,
      );
      emit(TransactionSuccess());
    } catch (e) {
      emit(TransactionError('Gagal memperbarui transaksi: ${e.toString()}'));
    }
  }
}
