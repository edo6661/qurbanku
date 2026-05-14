import 'package:equatable/equatable.dart';

enum SavingStatus { active, completed }

class UserSavingModel extends Equatable {
  final String id;
  final String userId;
  final String targetId;
  final double currentBalance;
  final SavingStatus status;

  final String namaPengkurban;
  final String binBinti;

  const UserSavingModel({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.currentBalance,
    required this.status,
    required this.namaPengkurban,
    required this.binBinti,
  });

  factory UserSavingModel.fromJson(Map<String, dynamic> json) {
    return UserSavingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetId: json['target_id'] as String,
      currentBalance: (json['current_balance'] as num).toDouble(),
      status: _parseStatus(json['status'] as String?),

      namaPengkurban: json['nama_pengkurban'] as String? ?? '',
      binBinti: json['bin_binti'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_id': targetId,
      'current_balance': currentBalance,
      'status': status.name,

      'nama_pengkurban': namaPengkurban,
      'bin_binti': binBinti,
    };
  }

  static SavingStatus _parseStatus(String? statusStr) {
    if (statusStr == 'completed') return SavingStatus.completed;
    return SavingStatus.active;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    targetId,
    currentBalance,
    status,
    namaPengkurban,
    binBinti,
  ];
}
