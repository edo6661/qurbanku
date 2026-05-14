import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/savings/savings_bloc.dart';
import '../../blocs/savings/savings_state.dart';
import '../../models/transaction_model.dart';
import '../../services/savings_service.dart';
import '../../utils/currency_formatter.dart';
import 'setor_tabungan_page.dart';

class RiwayatSetoranPage extends StatelessWidget {
  const RiwayatSetoranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Setoran (Per Target)')),
      body: BlocBuilder<SavingsBloc, SavingsState>(
        builder: (context, state) {
          if (state is SavingsLoading || state is SavingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SavingsEmpty) {
            return const Center(
              child: Text(
                'Belum ada target tabungan.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          if (state is SavingsLoaded) {
            // Grouping Lunas dan Proses
            final lunasList = state.savingsList
                .where((item) => item.progressPercentage >= 100)
                .toList();
            final prosesList = state.savingsList
                .where((item) => item.progressPercentage < 100)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (prosesList.isNotEmpty) ...[
                  const Text(
                    'Sedang Proses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...prosesList.map(
                    (item) => _buildTargetCard(context, item, isLunas: false),
                  ),
                  const SizedBox(height: 24),
                ],
                if (lunasList.isNotEmpty) ...[
                  const Text(
                    'Sudah Lunas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lunasList.map(
                    (item) => _buildTargetCard(context, item, isLunas: true),
                  ),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTargetCard(
    BuildContext context,
    SavingItem item, {
    required bool isLunas,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigasi ke detail riwayat per ID Sapi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRiwayatTargetPage(
                savingId: item.userSaving.id,
                targetName: item.targetDetail.animalType,
                isLunas: isLunas,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.targetDetail.animalType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLunas
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLunas ? 'LUNAS' : 'PROSES',
                      style: TextStyle(
                        color: isLunas ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A.n: ${item.userSaving.namaPengkurban}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Terkumpul: ${CurrencyFormatter.toRupiah(item.userSaving.currentBalance)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ketuk untuk melihat riwayat setoran >>',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Halaman baru untuk melihat list transaksi di dalam 1 target sapi
class DetailRiwayatTargetPage extends StatelessWidget {
  final String savingId;
  final String targetName;
  final bool isLunas;

  const DetailRiwayatTargetPage({
    super.key,
    required this.savingId,
    required this.targetName,
    required this.isLunas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail: $targetName',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isLunas ? Colors.green.shade100 : Colors.orange.shade100,
            child: Text(
              isLunas
                  ? 'Status: TABUNGAN TELAH LUNAS'
                  : 'Status: TABUNGAN SEDANG PROSES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLunas ? Colors.green.shade800 : Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
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
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty)
                  return const Center(
                    child: Text('Belum ada riwayat setoran.'),
                  );

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
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          CurrencyFormatter.toRupiah(tx.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormatted,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (tx.status == TransactionStatus.rejected)
                              Text(
                                'Ditolak: ${tx.adminNote ?? "-"}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
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
