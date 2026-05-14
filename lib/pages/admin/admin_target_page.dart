import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/saving_target_model.dart';
import '../../services/savings_service.dart';
import '../../utils/currency_formatter.dart';

class AdminTargetPage extends StatelessWidget {
  const AdminTargetPage({super.key});

  void _showTargetForm(
    BuildContext context, {
    SavingTargetModel? existingTarget,
  }) {
    final nameController = TextEditingController(
      text: existingTarget?.animalType,
    );
    final amountController = TextEditingController();

    if (existingTarget != null) {
      amountController.text = existingTarget.targetAmount.toInt().toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existingTarget == null ? 'Tambah Target Baru' : 'Edit Target',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Hewan / Keterangan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Target Nominal (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final cleanText = amountController.text.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final amount = double.tryParse(cleanText) ?? 0.0;

                  final newTarget = SavingTargetModel(
                    id: existingTarget?.id ?? '',
                    animalType: nameController.text,
                    targetAmount: amount,
                  );

                  await context.read<SavingsService>().saveTarget(newTarget);
                  if (context.mounted) Navigator.pop(bottomSheetContext);
                }
              },
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<SavingTargetModel>>(
        stream: context.read<SavingsService>().getTargetsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final targets = snapshot.data ?? [];
          if (targets.isEmpty)
            return const Center(child: Text('Belum ada target kurban.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(
                    target.animalType,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    CurrencyFormatter.toRupiah(target.targetAmount),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showTargetForm(context, existingTarget: target),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await context.read<SavingsService>().deleteTarget(
                            target.id,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTargetForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
