import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_event.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../models/transaction_model.dart';
import '../../services/savings_service.dart';
import '../../services/storage_service.dart';
import '../../utils/currency_formatter.dart';

class SetorTabunganPage extends StatelessWidget {
  final TransactionModel? existingTransaction;
  final String? savingId;
  final double? maxAmount; // TAMBAHAN

  const SetorTabunganPage({
    super.key,
    this.existingTransaction,
    this.savingId,
    this.maxAmount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionBloc(
        storageService: context.read<StorageService>(),
        savingsService: context.read<SavingsService>(),
      ),
      child: _SetorTabunganForm(
        existingTransaction: existingTransaction,
        savingId: savingId,
        maxAmount: maxAmount, // TAMBAHAN
      ),
    );
  }
}

class _SetorTabunganForm extends StatefulWidget {
  final TransactionModel? existingTransaction;
  final String? savingId;
  final double? maxAmount; // TAMBAHAN

  const _SetorTabunganForm({
    this.existingTransaction,
    this.savingId,
    this.maxAmount,
  });
  @override
  State<_SetorTabunganForm> createState() => _SetorTabunganFormState();
}

class _SetorTabunganFormState extends State<_SetorTabunganForm> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      );
      _amountController.text = formatter
          .format(widget.existingTransaction!.amount)
          .trim();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submit() {
    final hasValidImage = _selectedImage != null || _isEditMode;

    if (_formKey.currentState!.validate() && hasValidImage) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final cleanText = _amountController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        final amount = double.tryParse(cleanText) ?? 0.0;

        if (_isEditMode) {
          context.read<TransactionBloc>().add(
            UpdateTransaction(
              transactionId: widget.existingTransaction!.id,
              amount: amount,
              newEvidenceImage: _selectedImage,
              currentEvidenceUrl: widget.existingTransaction!.evidenceUrl,
              userId: authState.user.uid,
            ),
          );
        } else {
          context.read<TransactionBloc>().add(
            SubmitTransaction(
              amount: amount,
              evidenceImage: _selectedImage!,
              userId: authState.user.uid,
              savingId: widget.savingId!, // <--- BARU (Kirim ID tabungannya)
            ),
          );
        }
      }
    } else if (!hasValidImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah bukti transfer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Revisi Setoran' : 'Setor Tabungan'),
      ),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditMode
                      ? 'Revisi berhasil dikirim. Menunggu verifikasi.'
                      : 'Transaksi berhasil dikirim. Menunggu verifikasi.',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is TransactionSubmitting;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),

                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isEditMode) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alasan Penolakan Admin:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.existingTransaction!.adminNote ??
                                    'Tidak ada catatan',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Nominal Setoran (Rp)',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Nominal wajib diisi';

                          // Hapus semua karakter selain angka
                          final cleanText = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          final amount = double.tryParse(cleanText) ?? 0.0;

                          // TAMBAHAN: Validasi max amount
                          if (widget.maxAmount != null &&
                              amount > widget.maxAmount!) {
                            return 'Maksimal setoran Rp ${CurrencyFormatter.toRupiah(widget.maxAmount!)}';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Bukti Transfer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: isLoading ? null : _pickImage,
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : _isEditMode
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        widget.existingTransaction!.evidenceUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(color: Colors.black38),
                                      const Center(
                                        child: Text(
                                          'Ketuk untuk ganti foto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ketuk untuk memilih foto',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                _isEditMode
                                    ? 'Kirim Revisi Setoran'
                                    : 'Kirim Bukti Setoran',
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
