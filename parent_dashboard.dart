import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/assessment.dart';
import '../../models/attendance.dart';
import '../../models/schedule.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/timetable_board.dart';

/// لوحة تحكم ولي الأمر: ملخص كل الأبناء.
class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

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
    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DashboardHeader(user: user),
            SectionCard(
              title: 'أبنائي',
              icon: Icons.family_restroom_outlined,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: children.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final Student student = children[index];
                  final double average =
                      repo.averageForStudent(student.id) / 100;
                  final AttendanceSummary summary =
                      repo.summaryForStudent(student.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppInfoRow(
                        leading: CircleAvatar(child: Text(student.initials)),
                        title: student.fullName,
                        subtitle: student.gradeAndClassroom,
                        trailing: Text(ArFormat.percent(average)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          StatTile(
                            label: 'الحضور',
                            value: ArFormat.percent(summary.rate),
                            icon: Icons.event_available_outlined,
                          ),
                          StatTile(
                            label: 'غياب',
                            value: '${summary.absent}',
                            icon: Icons.cancel_outlined,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            if (children.isNotEmpty)
              SectionCard(
                title: 'جدول الأبناء',
                icon: Icons.calendar_month_outlined,
                child: TimetableBoard(
                  lessons: repo.lessonsForGrade(children.first.grade),
                  showGrade: true,
                ),
              ),
          ],
        );
      },
    );
  }
}