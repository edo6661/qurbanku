import 'package:equatable/equatable.dart';
import '../../models/transaction_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<TransactionModel> pendingTransactions;

  const AdminLoaded(this.pendingTransactions);

  @override
  List<Object?> get props => [pendingTransactions];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminActionProcessing extends AdminState {}

class AdminActionSuccess extends AdminState {
  final String message;

  const AdminActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
