import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/announcement.dart';
import '../widgets/app_empty_state.dart';

/// شاشة التنبيهات: تعرض كل ما يخص المستخدم من إشعارات.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const String routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('التنبيهات'),
        actions: <Widget>[
          ListenableBuilder(
            listenable: repository,
            builder: (BuildContext context, Widget? child) {
              return TextButton(
                onPressed: repository.unreadNotificationsCount == 0
                    ? null
                    : repository.markAllNotificationsRead,
                child: const Text(
                  'تعليم الكل كمقروء',
                  style: TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (BuildContext context, Widget? child) {
          final List<AppNotification> items = repository.notifications;
          if (items.isEmpty) {
            return const EmptyState(
              title: 'لا توجد تنبيهات',
              message: 'ستظهر هنا تنبيهات الحضور والدرجات والرسوم.',
              icon: Icons.notifications_none,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final AppNotification item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: item.isRead ? Colors.white : AppTheme.lightPurple,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isRead
                        ? const Color(0xFFE3E0F0)
                        : AppTheme.midPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  onTap: () => repository.markNotificationRead(item.id),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.royalPurple.withValues(alpha: 0.12),
                    child: Icon(
                      item.kind.icon,
                      color: AppTheme.royalPurple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.bold,
                      color: AppTheme.deepPurple,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 3),
                      Text(item.body, style: const TextStyle(fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(
                        ArFormat.dateTime(item.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.notMarkedColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: item.isRead
                      ? null
                      : Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppTheme.midPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}