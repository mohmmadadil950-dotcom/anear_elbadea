import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// شاشة رسائل ولي الأمر مع الأبناء والمدرسين.
class ParentMessagesScreen extends StatelessWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppRepository repo = AppRepository.instance;
    final AppUser? user = repo.currentUser;
    if (user == null) {
      return const EmptyState(
        title: 'الجلسة غير نشطة',
        icon: Icons.login_outlined,
      );
    }
    final List<ChatThread> threads = repo.threadsForUser(user);
    if (threads.isEmpty) {
      return const EmptyState(
        title: 'لا توجد رسائل حتى الآن',
        icon: Icons.chat_bubble_outline,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('رسائلي')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final ChatThread thread = threads[index];
          return ListTile(
            leading: CircleAvatar(child: Text(thread.title.substring(0, 1))),
            title: Text(thread.title),
            subtitle: Text(thread.subtitle),
            trailing: thread.unreadCount > 0
                ? CircleAvatar(
                    radius: 10,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text('${thread.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )
                : null,
            onTap: () {
              repo.markThreadRead(thread.id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ThreadDetail(thread: thread),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// تفاصيل المحادثة (قراءة فقط).
class _ThreadDetail extends StatelessWidget {
  const _ThreadDetail({required this.thread});
  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(thread.title)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: thread.messages.isEmpty
                ? const Center(
                    child: EmptyState(
                      title: 'لا توجد رسائل في هذه المحادثة',
                      icon: Icons.chat_bubble_outline,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: thread.messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final message =
                          thread.messages[thread.messages.length - 1 - index];
                      return ListTile(
                        leading: CircleAvatar(
                            child: Text(message.senderName.substring(0, 1))),
                        title: Text(message.senderName),
                        subtitle: Text(message.body),
                        trailing: Text(
                            ArFormat.dateTime(message.sentAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black45)),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'استخدم شاشة الرسائل العامة للرد',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}