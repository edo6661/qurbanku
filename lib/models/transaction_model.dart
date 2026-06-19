import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionStatus { pending, approved, rejected }

class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String evidenceUrl;
  final String savingId;
  final TransactionStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final String namaPengkurban;
  final String binBinti;
  final String namaPenabung;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.evidenceUrl,
    required this.status,
    required this.savingId,
    this.adminNote,
    required this.createdAt,
    required this.namaPengkurban,
    required this.binBinti,
    this.namaPenabung = '-',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      evidenceUrl: json['evidence_url'] as String,
      status: _parseStatus(json['status'] as String?),
      savingId: json['saving_id'] as String? ?? '',
      adminNote: json['admin_note'] as String?,
      createdAt: (json['created_at'] as Timestamp).toDate(),
      // Gunakan fallback agar data lama sebelum update tidak error
      namaPengkurban: json['nama_pengkurban'] as String? ?? '-',
      binBinti: json['bin_binti'] as String? ?? '-',
      namaPenabung: json['nama_penabung'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'evidence_url': evidenceUrl,
      'status': status.name,
      'saving_id': savingId,
      if (adminNote != null) 'admin_note': adminNote,
      'created_at': Timestamp.fromDate(createdAt),
      'nama_pengkurban': namaPengkurban,
      'bin_binti': binBinti,
      'nama_penabung': namaPenabung,
    };
  }

  static TransactionStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'approved':
        return TransactionStatus.approved;
      case 'rejected':
        return TransactionStatus.rejected;
      default:
        return TransactionStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    savingId,
    evidenceUrl,
    status,
    adminNote,
    createdAt,
    namaPengkurban,
    binBinti,
    namaPenabung,
  ];
}
