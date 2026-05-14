import 'package:equatable/equatable.dart';

class SavingTargetModel extends Equatable {
  final String id;
  final String animalType;
  final double targetAmount;

  const SavingTargetModel({
    required this.id,
    required this.animalType,
    required this.targetAmount,
  });

  factory SavingTargetModel.fromJson(Map<String, dynamic> json) {
    return SavingTargetModel(
      id: json['id'] as String,
      animalType: json['animal_type'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'animal_type': animalType, 'target_amount': targetAmount};
  }

  @override
  List<Object?> get props => [id, animalType, targetAmount];
}
