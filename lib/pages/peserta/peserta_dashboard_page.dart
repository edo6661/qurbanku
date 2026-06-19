import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qurban_ku/blocs/news/news_event.dart';
import 'package:qurban_ku/models/notification_model.dart.dart';
import 'package:qurban_ku/models/user_saving_model.dart';
import 'package:qurban_ku/pages/notifications_page.dart';
import 'package:qurban_ku/pages/profile/profile_page.dart';
import 'package:qurban_ku/widgets/admin_whatsapp_card.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/savings/savings_bloc.dart';
import '../../blocs/savings/savings_event.dart';
import '../../blocs/savings/savings_state.dart';
import '../../blocs/news/news_bloc.dart';
import '../../blocs/news/news_state.dart';
import '../../models/news_model.dart';
import '../../models/saving_target_model.dart';
import '../../services/savings_service.dart';
import '../../utils/currency_formatter.dart';
import 'riwayat_setoran_page.dart';
import 'setor_tabungan_page.dart';

class PesertaDashboardPage extends StatefulWidget {
  const PesertaDashboardPage({super.key});

  @override
  State<PesertaDashboardPage> createState() => _PesertaDashboardPageState();
}

class _PesertaDashboardPageState extends State<PesertaDashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SavingsBloc>().add(
        LoadSavingsData(userId: authState.user.uid),
      );
      context.read<NewsBloc>().add(LoadNews());
    }
  }

  void _showAddTargetSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AddTargetBottomSheet(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Beranda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              userId,
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
                              NotificationsPage(targetUser: userId),
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
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Semua Setoran',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RiwayatSetoranPage(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTargetSheet(context, userId),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Target'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // SEKSI 1: TABUNGAN SAYA
              // ==========================================
              const Text(
                'Tabungan Saya',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              BlocBuilder<SavingsBloc, SavingsState>(
                builder: (context, state) {
                  if (state is SavingsLoading || state is SavingsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is SavingsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (state is SavingsEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Anda belum memiliki target tabungan.\nSilakan tekan tombol Tambah Target di bawah.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (state is SavingsLoaded) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.savingsList.length,
                      itemBuilder: (context, index) {
                        final item = state.savingsList[index];
                        return _buildSavingCard(context, item);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 32),

              // ==========================================
              // SEKSI 2: BERITA TERBARU
              // ==========================================
              const Text(
                'Berita Terbaru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _NewsSection(),
              const SizedBox(height: 24),
              const AdminWhatsappCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Dipindahkan agar body tidak terlalu penuh
  Widget _buildSavingCard(BuildContext context, SavingItem item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRiwayatTargetPage(
                savingId: item.userSaving.id,
                targetName: item.targetDetail.animalType,
                isLunas: item.progressPercentage >= 100.0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.targetDetail.animalType.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A.n: ${item.userSaving.namaPengkurban}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Penabung: ${item.depositorName}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                'Bin/Binti: ${item.userSaving.binBinti}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Target: ${CurrencyFormatter.toRupiah(item.targetDetail.targetAmount)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: item.progressPercentage / 100,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
                backgroundColor: Colors.grey[300],
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.toRupiah(item.userSaving.currentBalance),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final isLunas = item.progressPercentage >= 100.0;
                  final isCompleted =
                      item.userSaving.status == SavingStatus.completed;
                  final hasPending = item.hasPendingTransaction;

                  return SizedBox(
                    width: double.infinity,
                    child: isCompleted
                        ? ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(
                              Icons.verified,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Telah Diserahkan',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : isLunas
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                _showPenyerahanDialog(context, item),
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Serahkan Tabungan',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          )
                        : hasPending
                        ? ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(
                              Icons.hourglass_top,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Menunggu Verifikasi Admin',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              final maxAmount =
                                  item.targetDetail.targetAmount -
                                  item.userSaving.currentBalance;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SetorTabunganPage(
                                    savingId: item.userSaving.id,
                                    maxAmount: maxAmount,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('Setor untuk Target Ini'),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPenyerahanDialog(BuildContext context, SavingItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alhamdulillah, Lunas!'),
        content: const Text(
          'Tabungan kurban Anda untuk target ini sudah mencapai 100%. '
          'Silakan serahkan tabungan secara resmi ke panitia kurban.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await context.read<SavingsService>().completeSaving(
                item.userSaving.id,
              );
              if (context.mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tabungan berhasil diserahkan!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Serahkan Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET KHUSUS BERITA (EXPANDABLE LIST & CARD)
// ============================================================
class _NewsSection extends StatefulWidget {
  const _NewsSection();

  @override
  State<_NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<_NewsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading || state is NewsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NewsLoaded) {
          if (state.newsList.isEmpty) {
            return const Text(
              'Belum ada berita yang tersedia.',
              style: TextStyle(color: Colors.grey),
            );
          }

          // Default: Tampilkan max 3, jika _showAll = true, tampilkan semua
          final displayedNews = _showAll
              ? state.newsList
              : state.newsList.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...displayedNews.map((news) => _NewsCard(news: news)),
              if (state.newsList.length > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                  child: Text(
                    _showAll
                        ? 'Tampilkan Lebih Sedikit'
                        : 'Lihat Berita Lainnya (${state.newsList.length - 3})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _NewsCard extends StatefulWidget {
  final NewsModel news;
  const _NewsCard({required this.news});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Berita
          Image.network(
            widget.news.imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 180,
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.news.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(widget.news.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Deskripsi yang bisa diexpand
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.news.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  secondChild: Text(
                    widget.news.description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded ? 'Tutup' : 'Baca Selengkapnya',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET TERPISAH UNTUK BOTTOM SHEET & DETAIL (TETAP SAMA)
// ============================================================
class _AddTargetBottomSheet extends StatefulWidget {
  final String userId;
  const _AddTargetBottomSheet({required this.userId});

  @override
  State<_AddTargetBottomSheet> createState() => _AddTargetBottomSheetState();
}

class _AddTargetBottomSheetState extends State<_AddTargetBottomSheet> {
  SavingTargetModel? selectedTarget;
  final namaController = TextEditingController();
  final binBintiController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    namaController.dispose();
    binBintiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedTarget == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Target Kurban',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<SavingTargetModel>>(
              stream: context.read<SavingsService>().getTargetsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final targets = snapshot.data ?? [];
                if (targets.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Admin belum membuat target kurban.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final target = targets[index];
                    return Card(
                      elevation: 1,
                      child: ListTile(
                        title: Text(
                          target.animalType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.toRupiah(target.targetAmount),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() => selectedTarget = target);
                          },
                          child: const Text('Gabung'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Step 2: Form isi data pengkurban
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => selectedTarget = null),
                ),
                const Text(
                  'Data Pengkurban',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Target: ${selectedTarget!.animalType}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Pengkurban',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: binBintiController,
              decoration: const InputDecoration(
                labelText: 'Bin / Binti',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final savingsService = context.read<SavingsService>();
                    await savingsService.joinTarget(
                      widget.userId,
                      selectedTarget!.id,
                      namaController.text.trim(),
                      binBintiController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Target berhasil ditambahkan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal bergabung: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Simpan & Gabung'),
            ),
          ],
        ),
      ),
    );
  }
}
