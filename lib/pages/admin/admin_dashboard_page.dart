import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qurban_ku/blocs/news/news_bloc.dart';
import 'package:qurban_ku/blocs/news/news_event.dart';
import 'package:qurban_ku/models/notification_model.dart.dart';
import 'package:qurban_ku/models/transaction_model.dart';
import 'package:qurban_ku/pages/admin/admin_history_page.dart';
import 'package:qurban_ku/pages/admin/admin_news_page.dart';
import 'package:qurban_ku/pages/admin/admin_tabungan_peserta_page.dart';
import 'package:qurban_ku/pages/notifications_page.dart';
import 'package:qurban_ku/pages/profile/profile_page.dart';
import 'package:qurban_ku/services/savings_service.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../utils/currency_formatter.dart';
import 'admin_target_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  // Daftar judul AppBar sesuai tab
  final List<String> _titles = [
    'Verifikasi Setoran',
    'Target Kurban',
    'Riwayat & Export',
    'Tabungan Peserta', // <-- TAMBAHAN
    'Kelola Berita', // <-- TAMBAHAN
  ];
  @override
  void initState() {
    super.initState();
    // Restart stream berita dan transaksi saat masuk ke dashboard admin
    context.read<NewsBloc>().add(LoadNews());
    context.read<AdminBloc>().add(LoadPendingTransactions());
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
              'Detail Setoran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildDetailRow('Nama Pengkurban', tx.namaPengkurban),
            _buildDetailRow('Penabung', tx.namaPenabung),
            _buildDetailRow('Bin / Binti', tx.binBinti),
            _buildDetailRow('Tanggal Setor', dateFormatted),
            _buildDetailRow('Nominal', CurrencyFormatter.toRupiah(tx.amount)),
            const SizedBox(height: 16),
            const Text(
              'Bukti Transfer:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageDialog(context, tx.evidenceUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  tx.evidenceUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          StreamBuilder<List<NotificationModel>>(
            stream: context.read<SavingsService>().getNotificationsStream(
              'admin',
            ),
            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data?.where((n) => !n.isRead).length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationsPage(targetUser: 'admin'),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      // Tampilkan halaman berdasarkan index
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildPendingTab(context),
          const AdminTargetPage(),
          const AdminHistoryPage(),
          const AdminTabunganPesertaPage(), // <-- UBAH 2: Tambahkan halaman ke
          const AdminNewsPage(), // <-- TAMBAHAN
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Verifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Target',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Peserta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Berita',
          ), // <-- TAMBAHAN
        ],
      ),
    );
  }

  // ==========================================
  // UI UNTUK TAB VERIFIKASI PENDING
  // ==========================================
  Widget _buildPendingTab(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      buildWhen: (previous, current) =>
          current is AdminLoaded ||
          current is AdminLoading ||
          current is AdminInitial,
      builder: (context, state) {
        if (state is AdminLoading || state is AdminInitial)
          return const Center(child: CircularProgressIndicator());
        if (state is AdminLoaded) {
          if (state.pendingTransactions.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada transaksi yang menunggu verifikasi.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.pendingTransactions.length,
            itemBuilder: (context, index) {
              final tx = state.pendingTransactions[index];
              final dateFormatted = DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(tx.createdAt);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                clipBehavior: Clip.antiAlias, // Agar InkWell tidak keluar batas
                child: InkWell(
                  onTap: () => _showTransactionDetailDialog(
                    context,
                    tx,
                  ), // Fungsi klik detail
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
                                tx.namaPengkurban,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              dateFormatted,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Penabung: ${tx.namaPenabung}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Bin/Binti: ${tx.binBinti}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          CurrencyFormatter.toRupiah(tx.amount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green, // Warna nominal disesuaikan
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showImageDialog(context, tx.evidenceUrl),
                              icon: const Icon(Icons.image, size: 16),
                              label: const Text('Bukti'),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  _showRejectDialog(context, tx.id),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Tolak',
                            ),
                            IconButton(
                              onPressed: () => _showApproveDialog(context, tx),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              ),
                              tooltip: 'Setujui',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Image.network(imageUrl, fit: BoxFit.contain)],
        ),
      ),
    );
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
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
