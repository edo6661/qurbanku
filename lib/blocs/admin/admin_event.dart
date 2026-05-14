import 'package:equatable/equatable.dart';
import '../../models/transaction_model.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingTransactions extends AdminEvent {}

class PendingTransactionsUpdated extends AdminEvent {
  final List<TransactionModel> transactions;

  const PendingTransactionsUpdated(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class ApproveTransactionRequested extends AdminEvent {
  final TransactionModel transaction;

  const ApproveTransactionRequested(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class RejectTransactionRequested extends AdminEvent {
  final String transactionId;
  final String adminNote;

  const RejectTransactionRequested({
    required this.transactionId,
    required this.adminNote,
  });

  @override
  List<Object?> get props => [transactionId, adminNote];
}

class PendingTransactionsError extends AdminEvent {
  final String message;

  const PendingTransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
