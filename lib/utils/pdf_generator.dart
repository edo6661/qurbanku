import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'currency_formatter.dart';

class PdfGenerator {
  static Future<Uint8List> generateReport({
    required List<TransactionModel> transactions,
    DateTime? startDate,
    DateTime? endDate,
    required String statusFilter,
  }) async {
    final pdf = pw.Document();

    double totalApproved = 0;
    for (var tx in transactions) {
      if (tx.status == TransactionStatus.approved) {
        totalApproved += tx.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Riwayat Setoran Kurban',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            ),
            pw.Text('Filter Status: $statusFilter'),
            if (startDate != null && endDate != null)
              pw.Text(
                'Periode: ${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
              ),

            pw.SizedBox(height: 20),

            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerHeight: 30,
              cellHeight: 25,
              data: <List<String>>[
                <String>[
                  'Tanggal',
                  'Penabung',
                  'A.n Pengkurban',
                  'Status',
                  'Nominal',
                  'Catatan/Alasan',
                ],
                ...transactions.map((tx) {
                  return [
                    DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                    tx.namaPenabung,
                    tx.namaPengkurban,
                    tx.status.name.toUpperCase(),
                    CurrencyFormatter.toRupiah(tx.amount),
                    tx.adminNote ?? '-',
                  ];
                }),
              ],
            ),

            pw.SizedBox(height: 20),
            if (statusFilter == 'Semua' || statusFilter == 'Approved')
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total Setoran Disetujui: ${CurrencyFormatter.toRupiah(totalApproved)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
