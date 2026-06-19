import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qurban_ku/models/transaction_model.dart';
import '../../services/savings_service.dart';
import '../../models/user_saving_model.dart';
import '../../models/saving_target_model.dart';
import '../../utils/currency_formatter.dart';

class AdminDetailRiwayatTabunganPage extends StatelessWidget {
  final String savingId;
  final String namaPengkurban;
  final String targetName;

  const AdminDetailRiwayatTabunganPage({
    super.key,
    required this.savingId,
    required this.namaPengkurban,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Setoran: $namaPengkurban',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blueGrey.shade50,
            child: Text(
              'Target: $targetName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: context
                  .read<SavingsService>()
                  .getTransactionsBySavingIdStream(savingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty)
                  return const Center(child: Text('Tidak ada riwayat.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final dateFormatted = DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(tx.createdAt);

                    Color statusColor = tx.status == TransactionStatus.approved
                        ? Colors.green
                        : tx.status == TransactionStatus.rejected
                        ? Colors.red
                        : Colors.orange;

                    return Card(
                      child: ListTile(
                        title: Text(
                          CurrencyFormatter.toRupiah(tx.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateFormatted),
                            if (tx.adminNote != null &&
                                tx.adminNote!.isNotEmpty)
                              Text(
                                tx.status == TransactionStatus.rejected
                                    ? 'Ditolak: ${tx.adminNote}'
                                    : 'Catatan: ${tx.adminNote}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tx.status == TransactionStatus.rejected
                                      ? Colors.red
                                      : Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          tx.status.name.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
