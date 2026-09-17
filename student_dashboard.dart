import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/schedule.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/timetable_board.dart';

/// لوحة تحكم الطالب: المعدل التراكمي، الحضور، الواجبات والجدول.
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

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
    final String studentId = student.id;
    final double average = repo.averageForStudent(studentId);
    final int rank = repo.rankOfStudent(studentId);
    final AttendanceSummary summary =
        repo.summaryForStudent(studentId);

    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DashboardHeader(user: user),
            SectionCard(
              title: 'المعدل والترتيب',
              icon: Icons.leaderboard_outlined,
              child: Wrap(
                spacing: 12,
                children: <Widget>[
                  StatTile(
                    label: 'المعدل',
                    value: ArFormat.percent(average / 100),
                    icon: Icons.show_chart_outlined,
                  ),
                  StatTile(label: 'الترتيب', value: '#$rank', icon: Icons.star),
                  StatTile(
                    label: 'الحضور',
                    value: ArFormat.percent(summary.rate),
                    icon: Icons.event_available_outlined,
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'الحضور الأخير',
              icon: Icons.event_available_outlined,
              child: Wrap(
                spacing: 12,
                children: <Widget>[
                  StatTile(label: 'حاضر', value: '${summary.present}', icon: Icons.check_circle_outline),
                  StatTile(label: 'غائب', value: '${summary.absent}', icon: Icons.cancel_outlined),
                  StatTile(label: 'متأخر', value: '${summary.late}', icon: Icons.access_time),
                ],
              ),
            ),
            SectionCard(
              title: 'الواجبات القادمة',
              icon: Icons.menu_book_outlined,
              child: (() {
                final List<HomeworkAssignment> list =
                    repo.homeworkForGrade(student.grade).where((HomeworkAssignment hw) {
                  return !hw.isSubmittedBy(student.id);
                }).toList();
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('لا توجد واجبات قادمة.'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final HomeworkAssignment hw = list[index];
                    return AppInfoRow(
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.assignment_outlined, size: 18),
                      ),
                      title: hw.title,
                      subtitle: '${hw.subject} • تسليم ${ArFormat.date(hw.dueDate)} • ${hw.daysLeft} يوم متبقٍ',
                      trailing: hw.isOverdue
                          ? const Icon(Icons.warning_amber_outlined, color: Colors.red)
                          : null,
                    );
                  },
                );
              })(),
            ),
            SectionCard(
              title: 'جدولي الهذا striping',
              icon: Icons.calendar_month_outlined,
              child: TimetableBoard(
                lessons: repo.lessonsForGrade(student.grade),
                showGrade: false,
              ),
            ),
          ],
        );
      },
    );
  }
}