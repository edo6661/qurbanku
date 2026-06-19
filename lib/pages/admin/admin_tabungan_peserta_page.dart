import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qurban_ku/pages/admin/admin_detail_riwayat_tabungan_page.dart';
import '../../services/savings_service.dart';
import '../../models/user_saving_model.dart';
import '../../models/saving_target_model.dart';
import '../../utils/currency_formatter.dart';

class AdminTabunganPesertaPage extends StatefulWidget {
  const AdminTabunganPesertaPage({super.key});

  @override
  State<AdminTabunganPesertaPage> createState() =>
      _AdminTabunganPesertaPageState();
}

class _AdminTabunganPesertaPageState extends State<AdminTabunganPesertaPage> {
  String _selectedFilter = 'Semua';

  Future<List<Map<String, dynamic>>> _fetchData() async {
    return await context.read<SavingsService>().getAllUserSavingsWithDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- BAGIAN FILTER ---
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Filter Status Tabungan',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedFilter,
            items: ['Semua', 'Sedang Proses', 'Lunas'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedFilter = newValue!);
            },
          ),
        ),
        const Divider(height: 1, thickness: 1),

        // --- BAGIAN LIST DATA ---
        Expanded(
          // ✅ UBAH: Menggunakan StreamBuilder
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: context
                .read<SavingsService>()
                .getAllUserSavingsWithDetailStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Terjadi kesalahan: ${snapshot.error}'),
                );
              }
              final allData = snapshot.data ?? [];
              final filteredData = allData.where((item) {
                final progress = item['progressPercentage'] as double;
                if (_selectedFilter == 'Sedang Proses' && progress >= 100.0)
                  return false;
                if (_selectedFilter == 'Lunas' && progress < 100.0)
                  return false;
                return true;
              }).toList();

              if (filteredData.isEmpty) {
                return const Center(
                  child: Text('Tidak ada data peserta sesuai filter.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final item = filteredData[index];
                  final saving = item['saving'] as UserSavingModel;
                  final target = item['target'] as SavingTargetModel;
                  final progress = item['progressPercentage'] as double;
                  final namaPenabung = item['namaPenabung'] as String? ?? '-';
                  final isLunas = progress >= 100.0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        // Membuka daftar transaksi khusus untuk tabungan ini
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminDetailRiwayatTabunganPage(
                                  savingId: saving.id,
                                  namaPengkurban: saving.namaPengkurban,
                                  targetName: target.animalType,
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // ... Sisa kode Column tetap sama seperti sebelumnya (Row nama pengkurban, bin/binti, linear progress, dll) ...
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    saving.namaPengkurban,
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
                                      color: isLunas
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Penabung: $namaPenabung',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Bin/Binti: ${saving.binBinti}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Target Kurban: ${target.animalType}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey[300],
                              color: isLunas
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  CurrencyFormatter.toRupiah(
                                    saving.currentBalance,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${progress.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
            },
          ),
        ),
      ],
    );
  }
}
