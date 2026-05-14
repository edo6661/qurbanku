import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qurban_ku/models/notification_model.dart.dart';
import 'package:qurban_ku/pages/admin/admin_transaction_detail_page.dart';
import '../services/savings_service.dart';

class NotificationsPage extends StatelessWidget {
  final String targetUser; // Bisa berisi ID User atau tulisan 'admin'

  const NotificationsPage({super.key, required this.targetUser});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // ✅ TAMBAHAN: Tombol Read All
        actions: [
          IconButton(
            tooltip: 'Tandai semua sudah dibaca',
            icon: const Icon(Icons.mark_email_read),
            onPressed: () {
              context.read<SavingsService>().markAllNotificationsAsRead(
                targetUser,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: context.read<SavingsService>().getNotificationsStream(
          targetUser,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada notifikasi.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = !notif.isRead;

              return ListTile(
                tileColor: isUnread ? Colors.green.withOpacity(0.05) : null,
                leading: CircleAvatar(
                  backgroundColor: isUnread ? Colors.green : Colors.grey,
                  child: Icon(
                    isUnread ? Icons.notifications_active : Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif.message),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(notif.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  if (isUnread) {
                    context.read<SavingsService>().markNotificationAsRead(
                      notif.id,
                    );
                  }
                  // ✅ UBAH: Admin DAN Peserta kini bisa mengeklik notif menuju ke detail setoran
                  if (notif.referenceId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminTransactionDetailPage(
                          transactionId: notif.referenceId!,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
