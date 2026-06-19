import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qurban_ku/blocs/auth/auth_bloc.dart';
import 'package:qurban_ku/blocs/auth/auth_state.dart';
import 'package:qurban_ku/models/transaction_model.dart';
import 'package:qurban_ku/models/user_model.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import '../../services/savings_service.dart';
import '../../utils/currency_formatter.dart';

class AdminTransactionDetailPage extends StatefulWidget {
  final String transactionId;
  const AdminTransactionDetailPage({super.key, required this.transactionId});

  @override
  State<AdminTransactionDetailPage> createState() =>
      _AdminTransactionDetailPageState();
}

class _AdminTransactionDetailPageState
    extends State<AdminTransactionDetailPage> {
  TransactionModel? transaction;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tx = await context.read<SavingsService>().getTransactionById(
        widget.transactionId,
      );
      setState(() {
        transaction = tx;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showApproveDialog(BuildContext context, TransactionModel tx) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Setujui Transaksi'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Catatan untuk peserta...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                context.read<AdminBloc>().add(
                  ApproveTransactionRequested(
                    transaction: tx,
                    adminNote: noteController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String transactionId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Transaksi'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Alasan...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                context.read<AdminBloc>().add(
                  RejectTransactionRequested(
                    transactionId: transactionId,
                    adminNote: noteController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext); // Tutup dialog
              }
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final bool isAdmin =
        (authState is AuthAuthenticated &&
        authState.user.role == UserRole.admin);

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Setoran')),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (isLoading || state is AdminActionProcessing) {
            return const Center(child: CircularProgressIndicator());
          }
          if (transaction == null)
            return const Center(child: Text('Data tidak ditemukan'));

          final tx = transaction!;
          final dateFormatted = DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(tx.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Status', tx.status.name.toUpperCase()),
                _buildRow('Nama Pengkurban', tx.namaPengkurban),
                _buildRow('Penabung', tx.namaPenabung),
                _buildRow('Bin / Binti', tx.binBinti),
                _buildRow('Tanggal Setor', dateFormatted),
                _buildRow('Nominal', CurrencyFormatter.toRupiah(tx.amount)),
                if (tx.adminNote != null && tx.adminNote!.isNotEmpty)
                  _buildRow(
                    tx.status == TransactionStatus.rejected
                        ? 'Alasan Ditolak'
                        : 'Catatan Admin',
                    tx.adminNote!,
                  ),

                const SizedBox(height: 16),

                // ✅ TAMBAHAN: Foto bukti transfer
                const Text(
                  'Bukti Transfer:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showImageDialog(context, tx.evidenceUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      tx.evidenceUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            height: 100,
                            child: Center(child: Text('Gagal memuat gambar')),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ketuk foto untuk memperbesar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                if (tx.status == TransactionStatus.pending && isAdmin)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () => _showRejectDialog(context, tx.id),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showApproveDialog(context, tx),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Setujui'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ TAMBAHAN: Fungsi zoom foto
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
