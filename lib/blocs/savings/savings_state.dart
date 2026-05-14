import 'package:equatable/equatable.dart';
import '../../models/saving_target_model.dart';
import '../../models/user_saving_model.dart';

class SavingItem extends Equatable {
  final UserSavingModel userSaving;
  final SavingTargetModel targetDetail;
  final double progressPercentage;

  const SavingItem({
    required this.userSaving,
    required this.targetDetail,
    required this.progressPercentage,
  });

  @override
  List<Object?> get props => [userSaving, targetDetail, progressPercentage];
}

abstract class SavingsState extends Equatable {
  const SavingsState();
  @override
  List<Object?> get props => [];
}

class SavingsInitial extends SavingsState {}

class SavingsLoading extends SavingsState {}

class SavingsEmpty extends SavingsState {}

class SavingsLoaded extends SavingsState {
  final List<SavingItem> savingsList;
  const SavingsLoaded(this.savingsList);
  @override
  List<Object?> get props => [savingsList];
}

class SavingsError extends SavingsState {
  final String message;
  const SavingsError(this.message);
  @override
  List<Object?> get props => [message];
}
