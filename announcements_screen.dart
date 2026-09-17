import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/announcement.dart';
import '../models/user.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_status_chip.dart';

/// شاشة الإعلانات: عرض للجميع، ونشر للإدارة.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  static const String routeName = '/announcements';

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;
    final bool isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الإعلانات'),
        actions: <Widget>[
          if (isAdmin)
            IconButton(
              tooltip: 'نشر إعلان',
              onPressed: () => showAnnouncementComposer(context, repository),
              icon: const Icon(Icons.add_comment_outlined),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (BuildContext context, Widget? child) {
          final List<Announcement> items = user == null
              ? repository.announcements
              : repository.announcementsForRole(user.role);
          if (items.isEmpty) {
            return const EmptyState(
              title: 'لا توجد إعلانات',
              message: 'ستظهر هنا إعلانات الإدارة والمدرسين.',
              icon: Icons.campaign_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) =>
                _card(context, repository, items[index], isAdmin),
          );
        },
      ),
    );
  }

  Widget _card(
    BuildContext context,
    AppRepository repository,
    Announcement item,
    bool isAdmin,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPinned ? AppTheme.gold : const Color(0xFFE3E0F0),
          width: item.isPinned ? 1.4 : 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusChip(
                label: item.category.label,
                color: AppTheme.royalPurple,
                icon: item.category.icon,
              ),
              const SizedBox(width: 6),
              StatusChip(
                label: item.audience,
                color: AppTheme.midPurple,
                dense: true,
              ),
              const Spacer(),
              if (item.isPinned)
                const Icon(Icons.push_pin, size: 16, color: AppTheme.gold),
              if (isAdmin) _menu(repository, item),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(item.body, style: const TextStyle(fontSize: 13, height: 1.6)),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppTheme.notMarkedColor,
              ),
              const SizedBox(width: 4),
              Text(
                item.authorName,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.notMarkedColor,
                ),
              ),
              const Spacer(),
              Text(
                ArFormat.date(item.publishedAt),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.notMarkedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menu(AppRepository repository, Announcement item) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppTheme.notMarkedColor,
      ),
      onSelected: (String value) {
        if (value == 'pin') {
          repository.toggleAnnouncementPin(item.id);
        } else {
          repository.removeAnnouncement(item.id);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'pin',
          child: Text(item.isPinned ? 'إلغاء التثبيت' : 'تثبيت'),
        ),
        const PopupMenuItem<String>(value: 'delete', child: Text('حذف')),
      ],
    );
  }

}

/// نافذة نشر إعلان جديد (تظهر للإدارة فقط).
Future<void> showAnnouncementComposer(
  BuildContext context,
  AppRepository repository,
) async {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  const List<String> audiences = <String>[
    'الجميع',
    'المدرسون',
    'الطلاب',
    'أولياء الأمور',
  ];
  String audience = audiences.first;
  AnnouncementCategory category = AnnouncementCategory.general;
  bool pinned = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'نشر إعلان جديد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإعلان',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'نص الإعلان',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('الفئة المستهدفة'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: audiences
                        .map(
                          (String item) => ChoiceChip(
                            label: Text(item),
                            selected: audience == item,
                            onSelected: (_) =>
                                setState(() => audience = item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('التصنيف'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: AnnouncementCategory.values
                        .map(
                          (AnnouncementCategory item) => ChoiceChip(
                            label: Text(item.label),
                            selected: category == item,
                            onSelected: (_) =>
                                setState(() => category = item),
                          ),
                        )
                        .toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تثبيت الإعلان في الأعلى'),
                    value: pinned,
                    onChanged: (bool value) => setState(() => pinned = value),
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final String title = titleController.text.trim();
                        final String body = bodyController.text.trim();
                        if (title.isEmpty || body.isEmpty) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('يُرجى إكمال العنوان والنص'),
                            ),
                          );
                          return;
                        }
                        final AppUser? user = repository.currentUser;
                        repository.addAnnouncement(
                          Announcement(
                            id: repository.nextId('ANN'),
                            title: title,
                            body: body,
                            authorName: user?.fullName ?? 'الإدارة',
                            audience: audience,
                            category: category,
                            publishedAt: DateTime.now(),
                            isPinned: pinned,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('نشر الإعلان'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}