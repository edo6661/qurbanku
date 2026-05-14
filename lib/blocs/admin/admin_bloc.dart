import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/transaction_model.dart';
import '../../services/savings_service.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final SavingsService _savingsService;
  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;

  AdminBloc({required SavingsService savingsService})
    : _savingsService = savingsService,
      super(AdminInitial()) {
    on<LoadPendingTransactions>(_onLoadPendingTransactions);
    on<PendingTransactionsUpdated>(_onPendingTransactionsUpdated);
    on<PendingTransactionsError>(_onPendingTransactionsError);
    on<ApproveTransactionRequested>(_onApproveTransactionRequested);
    on<RejectTransactionRequested>(_onRejectTransactionRequested);
  }
  void _onLoadPendingTransactions(
    LoadPendingTransactions event,
    Emitter<AdminState> emit,
  ) {
    emit(AdminLoading());
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _savingsService
        .getPendingTransactionsStream()
        .listen(
          (transactions) {
            add(PendingTransactionsUpdated(transactions));
          },
          onError: (Object error) {
            add(
              PendingTransactionsError(
                'Gagal memuat data: ${error.toString()}',
              ),
            );
          },
        );
  }

  void _onPendingTransactionsUpdated(
    PendingTransactionsUpdated event,
    Emitter<AdminState> emit,
  ) {
    emit(AdminLoaded(event.transactions));
  }

  void _onPendingTransactionsError(
    PendingTransactionsError event,
    Emitter<AdminState> emit,
  ) {
    emit(AdminError(event.message));
  }

  Future<void> _onApproveTransactionRequested(
    ApproveTransactionRequested event,
    Emitter<AdminState> emit,
  ) async {
    // ... hapus final currentState = state;
    emit(AdminActionProcessing());
    try {
      await _savingsService.approveTransaction(event.transaction);
      emit(const AdminActionSuccess('Transaksi berhasil disetujui.'));
    } catch (e) {
      emit(AdminError('Gagal menyetujui transaksi: ${e.toString()}'));
    }
  }

  Future<void> _onRejectTransactionRequested(
    RejectTransactionRequested event,
    Emitter<AdminState> emit,
  ) async {
    // ... hapus final currentState = state;
    emit(AdminActionProcessing());
    try {
      await _savingsService.rejectTransaction(
        event.transactionId,
        event.adminNote,
      );
      emit(const AdminActionSuccess('Transaksi berhasil ditolak.'));
    } catch (e) {
      emit(AdminError('Gagal menolak transaksi: ${e.toString()}'));
    }
    // HAPUS BLOK IF DI BAWAH INI:
    // if (currentState is AdminLoaded) {
    //   emit(AdminLoaded(currentState.pendingTransactions));
    // }
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
