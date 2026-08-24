import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() { if (mounted) context.read<NotificationProvider>().fetchNotifications(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'), centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationProvider>().markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.notifications.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No notifications', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (_, i) {
                final n = provider.notifications[i];
                final isRead = n['isRead'] ?? false;
                final typeIcons = {
                  'complaint_update': Icons.update, 'assignment': Icons.assignment_ind,
                  'resolution': Icons.check_circle, 'feedback': Icons.star,
                  'system': Icons.info, 'reminder': Icons.alarm,
                };
                final typeColors = {
                  'complaint_update': Colors.blue, 'assignment': Colors.orange,
                  'resolution': Colors.green, 'feedback': Colors.amber,
                  'system': Colors.grey, 'reminder': Colors.purple,
                };
                final icon = typeIcons[n['type']] ?? Icons.notifications;
                final color = typeColors[n['type']] ?? Colors.grey;

                return FadeInUp(
                  delay: Duration(milliseconds: i * 50),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: Text(n['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 14)),
                      subtitle: Text(n['body'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 2),
                      trailing: isRead ? null : Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                      onTap: () {
                        if (!isRead) provider.markAsRead(n['_id']);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
