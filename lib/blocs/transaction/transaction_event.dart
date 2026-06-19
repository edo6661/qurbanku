import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class SubmitTransaction extends TransactionEvent {
  final double amount;
  final File evidenceImage;
  final String userId;
  final String savingId;
  final String namaPenabung;

  const SubmitTransaction({
    required this.amount,
    required this.evidenceImage,
    required this.userId,
    required this.savingId,
    required this.namaPenabung,
  });

  @override
  List<Object?> get props => [
    amount,
    evidenceImage,
    userId,
    savingId,
    namaPenabung,
  ];
}

class UpdateTransaction extends TransactionEvent {
  final String transactionId;
  final double amount;
  final File? newEvidenceImage;
  final String currentEvidenceUrl;
  final String userId;

  const UpdateTransaction({
    required this.transactionId,
    required this.amount,
    this.newEvidenceImage,
    required this.currentEvidenceUrl,
    required this.userId,
  });

  @override
  List<Object?> get props => [
    transactionId,
    amount,
    newEvidenceImage,
    currentEvidenceUrl,
    userId,
  ];
}
