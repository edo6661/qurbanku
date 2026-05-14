import 'package:equatable/equatable.dart';
import '../../models/user_saving_model.dart';

abstract class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSavingsData extends SavingsEvent {
  final String userId;

  const LoadSavingsData({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class SavingsUpdated extends SavingsEvent {
  final List<UserSavingModel> savings;
  const SavingsUpdated(this.savings);
  @override
  List<Object?> get props => [savings];
}

class SavingsErrorOccurred extends SavingsEvent {
  final String error;

  const SavingsErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}
