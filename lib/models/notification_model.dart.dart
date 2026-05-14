// Lokasi: lib/models/notification_model.dart.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String targetUser;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String?
  referenceId; // TAMBAHAN: Untuk menyimpan ID referensi (seperti ID Transaksi)

  const NotificationModel({
    required this.id,
    required this.targetUser,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.referenceId, // TAMBAHAN
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      targetUser: json['target_user'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: (json['created_at'] as Timestamp).toDate(),
      referenceId: json['reference_id'] as String?, // TAMBAHAN
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_user': targetUser,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
      if (referenceId != null) 'reference_id': referenceId, // TAMBAHAN
    };
  }

  @override
  List<Object?> get props => [
    id,
    targetUser,
    title,
    message,
    isRead,
    createdAt,
    referenceId,
  ];
}
