import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/requests.dart';
import '../models/user.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_status_chip.dart';

/// شاشة الطلبات: إنشاء الطلبات، ومراجعتها من قبل الإدارة.
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  static const String routeName = '/requests';

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;
    final bool isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('الطلبات')),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.royalPurple,
              foregroundColor: Colors.white,
              onPressed: () => showRequestComposer(context, repository),
              icon: const Icon(Icons.add),
              label: const Text('طلب جديد'),
            ),
      body: ListenableBuilder(
        listenable: repository,
        builder: (BuildContext context, Widget? child) {
          final List<SchoolRequest> items = isAdmin || user == null
              ? repository.requests
              : repository.requestsFrom(user.fullName);
          if (items.isEmpty) {
            return const EmptyState(
              title: 'لا توجد طلبات',
              message: 'يمكنك إرسال طلب إجازة أو عذر غياب أو موعد مقابلة.',
              icon: Icons.assignment_outlined,
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

  Color _statusColor(SchoolRequestStatus status) => switch (status) {
        SchoolRequestStatus.pending => AppTheme.lateColor,
        SchoolRequestStatus.approved => AppTheme.presentColor,
        SchoolRequestStatus.rejected => AppTheme.absentColor,
      };

  Widget _card(
    BuildContext context,
    AppRepository repository,
    SchoolRequest item,
    bool isAdmin,
  ) {
    final Color statusColor = _statusColor(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusChip(
                label: item.type.label,
                color: AppTheme.royalPurple,
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(width: 6),
              StatusChip(
                label: item.status.label,
                color: statusColor,
                dense: true,
              ),
              const Spacer(),
              Text(
                ArFormat.date(item.createdAt),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.notMarkedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(item.details, style: const TextStyle(fontSize: 13, height: 1.6)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppTheme.notMarkedColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${item.fromName} (${item.fromRole.label})',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.notMarkedColor,
                ),
              ),
            ],
          ),
          if (item.reviewerNote.isNotEmpty) ..._reviewNote(item),
          if (isAdmin && item.status == SchoolRequestStatus.pending)
            ..._reviewButtons(context, repository, item),
        ],
      ),
    );
  }

List<Widget> _reviewNote(SchoolRequest item) {
    return <Widget>[
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'ملاحظة الإدارة: ${item.reviewerNote}'
          '${item.reviewedBy == null ? '' : ' - ${item.reviewedBy}'}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ];
  }

  List<Widget> _reviewButtons(
    BuildContext context,
    AppRepository repository,
    SchoolRequest item,
  ) {
    return <Widget>[
      const SizedBox(height: 10),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showReviewDialog(
                context,
                repository,
                item,
                SchoolRequestStatus.rejected,
              ),
              icon: const Icon(Icons.close, size: 16),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.absentColor,
              ),
              label: const Text('رفض'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => showReviewDialog(
                context,
                repository,
                item,
                SchoolRequestStatus.approved,
              ),
              icon: const Icon(Icons.check, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.presentColor,
                foregroundColor: Colors.white,
              ),
              label: const Text('موافقة'),
            ),
          ),
        ],
      ),
    ];
  }
}

/// نافذة إنشاء طلب جديد.
Future<void> showRequestComposer(
  BuildContext context,
  AppRepository repository,
) async {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  SchoolRequestType type = SchoolRequestType.leave;

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
                    'طلب جديد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SchoolRequestType.values
                        .map(
                          (SchoolRequestType item) => ChoiceChip(
                            label: Text(item.label),
                            selected: type == item,
                            onSelected: (_) => setState(() => type = item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الطلب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'تفاصيل الطلب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                        final String details = detailsController.text.trim();
                        final AppUser? user = repository.currentUser;
                        if (title.isEmpty || details.isEmpty || user == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('يُرجى إكمال العنوان والتفاصيل'),
                            ),
                          );
                          return;
                        }
                        repository.addRequest(
                          SchoolRequest(
                            id: repository.nextId('REQ'),
                            type: type,
                            title: title,
                            details: details,
                            fromName: user.fullName,
                            fromRole: user.role,
                            createdAt: DateTime.now(),
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('إرسال الطلب'),
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

/// نافذة مراجعة الطلب (موافقة/رفض) مع ملاحظة اختيارية.
Future<void> showReviewDialog(
  BuildContext context,
  AppRepository repository,
  SchoolRequest request,
  SchoolRequestStatus status,
) async {
  final TextEditingController noteController = TextEditingController();
  final bool approving = status == SchoolRequestStatus.approved;

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(approving ? 'الموافقة على الطلب' : 'رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(request.title),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظة الإدارة (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  approving ? AppTheme.presentColor : AppTheme.absentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              repository.reviewRequest(
                request.id,
                status,
                reviewerName: repository.currentUser?.fullName ?? 'الإدارة',
                note: noteController.text.trim(),
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(approving ? 'موافقة' : 'رفض'),
          ),
        ],
      );
    },
  );
}