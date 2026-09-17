import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/attendance.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// شاشة حضور الطالب: سجل حالات الحضور الأخيرة مع الملخص.
class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

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
    final Student? student = repo.primaryStudent(user);
    if (student == null) {
      return const EmptyState(
        title: 'لم يتم ربط حسابك بطالب',
        icon: Icons.school_outlined,
      );
    }
    final List<AttendanceRecord> records =
        repo.recordsForStudent(student.id);
    final AttendanceSummary summary = repo.summaryForStudent(student.id);

    return Scaffold(
      appBar: AppBar(title: const Text('حضوري')),
      body: records.isEmpty
          ? const EmptyState(
              title: 'لا يوجد سجل حضور مسجل',
              icon: Icons.event_available_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                SectionCard(
                  title: 'الملخص العام',
                  icon: Icons.event_available_outlined,
                  child: Wrap(
                    spacing: 12,
                    children: <Widget>[
                      _Stat('إجمالي الحضور', '${summary.total}'),
                      _Stat('حاضر', '${summary.present}'),
                      _Stat('غائب', '${summary.absent}'),
                      _Stat('متأخر', '${summary.late}'),
                      _Stat('نسبة الحضور', ArFormat.percent(summary.rate)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'سجل الحضور',
                  icon: Icons.history,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final AttendanceRecord record = records[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              record.status.color.withValues(alpha: 0.15),
                          child: Icon(record.status.icon,
                              color: record.status.color, size: 20),
                        ),
                        title: Text(record.subject),
                        subtitle: Text(
                          '${record.grade} - ${record.classroom} • ${ArFormat.date(record.date)}',
                        ),
                        trailing: Text(record.status.label,
                            style: TextStyle(
                                color: record.status.color,
                                fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B2CA0),
                )),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54)),
      ],
    );
  }
}