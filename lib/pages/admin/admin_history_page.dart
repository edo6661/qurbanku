import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../models/transaction_model.dart';
import '../../services/savings_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/pdf_generator.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  String _selectedStatus = 'Semua';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        // Set end date to the end of the day (23:59:59)
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _showTransactionDetailDialog(BuildContext context, TransactionModel tx) {
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Riwayat Setoran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildDetailRow('Nama Pengkurban', tx.namaPengkurban),
            _buildDetailRow('Penabung', tx.namaPenabung),
            _buildDetailRow('Bin / Binti', tx.binBinti),
            _buildDetailRow('Tanggal Setor', dateFormatted),
            _buildDetailRow('Nominal', CurrencyFormatter.toRupiah(tx.amount)),
            _buildDetailRow('Status', tx.status.name.toUpperCase()),
            if (tx.adminNote != null && tx.adminNote!.isNotEmpty)
              _buildDetailRow(
                tx.status == TransactionStatus.rejected
                    ? 'Alasan Ditolak'
                    : 'Catatan Admin',
                tx.adminNote!,
              ),
            const SizedBox(height: 16),
            const Text(
              'Bukti Transfer:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                tx.evidenceUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: context.read<SavingsService>().getAllTransactionsHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        final allTransactions = snapshot.data ?? [];

        // Terapkan Filter
        final filteredTransactions = allTransactions.where((tx) {
          // Filter Status
          if (_selectedStatus == 'Approved' &&
              tx.status != TransactionStatus.approved)
            return false;
          if (_selectedStatus == 'Rejected' &&
              tx.status != TransactionStatus.rejected)
            return false;

          // Filter Tanggal
          if (_startDate != null && _endDate != null) {
            if (tx.createdAt.isBefore(_startDate!) ||
                tx.createdAt.isAfter(_endDate!)) {
              return false;
            }
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Bagian Filter Panel
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Filter Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value: _selectedStatus,
                          items: ['Semua', 'Approved', 'Rejected'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() => _selectedStatus = newValue!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _startDate != null
                                ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                                : 'Pilih Rentang Tanggal',
                          ),
                        ),
                      ),
                      if (_startDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear, color: Colors.red),
                          tooltip: 'Hapus Filter Tanggal',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: filteredTransactions.isEmpty
                          ? null
                          : () async {
                              final pdfBytes =
                                  await PdfGenerator.generateReport(
                                    transactions: filteredTransactions,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                    statusFilter: _selectedStatus,
                                  );
                              if (context.mounted) {
                                // Menampilkan preview PDF dan opsi Print/Save
                                await Printing.layoutPdf(
                                  onLayout: (format) async => pdfBytes,
                                  name:
                                      'Laporan_Setoran_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf',
                                );
                              }
                            },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export ke PDF'),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Bagian Daftar Transaksi
            Expanded(
              child: filteredTransactions.isEmpty
                  ? const Center(child: Text('Tidak ada data sesuai filter.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final isApproved =
                            tx.status == TransactionStatus.approved;
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () =>
                                _showTransactionDetailDialog(context, tx),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tx.namaPengkurban,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isApproved
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          tx.status.name.toUpperCase(),
                                          style: TextStyle(
                                            color: isApproved
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Penabung: ${tx.namaPenabung}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Bin/Binti: ${tx.binBinti}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        CurrencyFormatter.toRupiah(tx.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                        ).format(tx.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (tx.adminNote != null &&
                                      tx.adminNote!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      isApproved
                                          ? 'Catatan: ${tx.adminNote}'
                                          : 'Alasan: ${tx.adminNote}',
                                      style: TextStyle(
                                        color: isApproved
                                            ? Colors.green.shade700
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
