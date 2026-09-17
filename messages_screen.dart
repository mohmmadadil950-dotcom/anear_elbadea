import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_empty_state.dart';

/// قائمة المحادثات الخاصة بالمستخدم الحالي.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const String routeName = '/messages';

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('الرسائل')),
      body: user == null
          ? const Center(child: Text('لا يوجد مستخدم مسجل'))
          : ListenableBuilder(
              listenable: repository,
              builder: (BuildContext context, Widget? child) {
                final List<ChatThread> threads =
                    repository.threadsForUser(user);
                if (threads.isEmpty) {
                  return const EmptyState(
                    title: 'لا توجد محادثات',
                    message: 'تشمل المحادثات التواصل مع المدرسين والإدارة.',
                    icon: Icons.chat_bubble_outline,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: threads.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) =>
                      _tile(context, threads[index]),
                );
              },
            ),
    );
  }

  Widget _tile(BuildContext context, ChatThread thread) {
    final ChatMessage? last = thread.lastMessage;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ChatScreen(threadId: thread.id),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: <Widget>[
            PersonAvatar(
              name: thread.title,
              icon: thread.withRole.icon,
              color: AppTheme.royalPurple,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    thread.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.notMarkedColor,
                    ),
                  ),
                  if (last != null) ...<Widget>[
                    const SizedBox(height: 5),
                    Text(
                      last.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (last != null)
                  Text(
                    ArFormat.time(last.sentAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.notMarkedColor,
                    ),
                  ),
                if (thread.unreadCount > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTheme.midPurple,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      '${thread.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة المحادثة: عرض الرسائل وإرسال رسالة جديدة.
class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.threadId, super.key});

  final String threadId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AppRepository _repository = AppRepository.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository.markThreadRead(widget.threadId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _controller.text.trim();
    final AppUser? user = _repository.currentUser;
    if (text.isEmpty || user == null) {
      return;
    }
    _repository.sendMessage(widget.threadId, user, text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = _repository.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _repository,
          builder: (BuildContext context, Widget? child) {
            final ChatThread? thread = _repository.threadById(widget.threadId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  thread?.title ?? 'محادثة',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (thread != null)
                  Text(
                    thread.subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListenableBuilder(
              listenable: _repository,
              builder: (BuildContext context, Widget? child) {
                final ChatThread? thread =
                    _repository.threadById(widget.threadId);
                final List<ChatMessage> messages =
                    thread?.messages ?? const <ChatMessage>[];
                if (messages.isEmpty) {
                  return const EmptyState(
                    title: 'ابدأ المحادثة',
                    message: 'اكتب رسالتك الأولى في الأسفل.',
                    icon: Icons.forum_outlined,
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessage message = messages[index];
                    final bool isMe = message.senderId == user?.id;
                    return _bubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.royalPurple : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: <Widget>[
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.midPurple,
                  ),
                ),
              ),
            Text(
              message.body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: isMe ? Colors.white : AppTheme.deepPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ArFormat.time(message.sentAt),
              style: TextStyle(
                fontSize: 10.5,
                color: isMe ? Colors.white70 : AppTheme.notMarkedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E0F0))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            width: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _send,
              child: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}