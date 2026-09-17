import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';

/// شاشة حضور الأبناء من ولي الأمر.
class ParentAttendanceScreen extends StatelessWidget {
  const ParentAttendanceScreen({super.key});

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
    final List<Student> children = repo.linkedStudents(user);
    if (children.isEmpty) {
      return const EmptyState(
        title: 'لا يوجد أبناء مرتبطون بهذا الحساب',
        icon: Icons.family_restroom_outlined,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('حضور الأبناء')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int index) {
          final Student student = children[index];
          final List<AttendanceRecord> records =
              repo.recordsForStudent(student.id);
          final AttendanceSummary summary =
              repo.summaryForStudent(student.id);
          return SectionCard(
            title: student.fullName,
            subtitle: student.gradeAndClassroom,
            icon: Icons.event_available_outlined,
            child: records.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('لا يوجد سجل حضور مسجل'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        children: <Widget>[
                          AppInfoRow(
                            leading: Icon(Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.primary),
                            title: 'حاضر',
                            subtitle: '${summary.present}',
                          ),
                          AppInfoRow(
                            leading: Icon(Icons.cancel_outlined,
                                color: Theme.of(context).colorScheme.error),
                            title: 'غائب',
                            subtitle: '${summary.absent}',
                          ),
                          AppInfoRow(
                            leading: Icon(Icons.access_time,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary),
                            title: 'متأخر',
                            subtitle: '${summary.late}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نسبة الحضور: ${ArFormat.percent(summary.rate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int rIndex) {
                          final AttendanceRecord record = records[rIndex];
                          return AppInfoRow(
                            leading: CircleAvatar(
                              backgroundColor: record.status.color
                                  .withValues(alpha: 0.15),
                              child: Icon(record.status.icon,
                                  color: record.status.color, size: 18),
                            ),
                            title: record.subject,
                            subtitle:
                                '${record.grade} - ${record.classroom} • ${ArFormat.date(record.date)}',
                            trailing: Text(record.status.label,
                                style: TextStyle(
                                    color: record.status.color,
                                    fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}