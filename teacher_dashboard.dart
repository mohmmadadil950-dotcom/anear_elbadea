import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/dashboard_header.dart';

/// لوحة تحكم المدرس: ملخص الحضور والواجبات للصفوف التي يدرّسها.
class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

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
    final String teacherName = user.fullName;
    final List<String> grades = repo.gradesForUser(user);
    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        final List<Widget> children = <Widget>[
          DashboardHeader(user: user),
          SectionCard(
            title: 'ملخصي',
            icon: Icons.person_outline,
            child: Wrap(
              spacing: 12,
              children: <Widget>[
                StatTile(
                  label: 'الصفوف',
                  value: '${grades.length}',
                  icon: Icons.school_outlined,
                ),
                StatTile(
                  label: 'الحضور اليوم',
                  value: ArFormat.percent(
                    grades.isEmpty
                        ? 0
                        : repo.latestAttendanceRate,
                  ),
                  icon: Icons.event_available_outlined,
                ),
                StatTile(
                  label: 'الواجبات',
                  value: '${repo.homeworkForTeacher(teacherName).length}',
                  icon: Icons.menu_book_outlined,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'الصفوف التي أدرّسها',
            icon: Icons.grade_level_outlined,
            child: grades.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('لم يُعيّن لك صفوف بعد.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: grades.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final String grade = grades[index];
                      final int count =
                          repo.studentsInGrade(grade).length;
                      return AppInfoRow(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.deepPurple.shade50,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Color(0xFF4B2CA0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: grade,
                        subtitle: '$count طالب',
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      );
                    },
                  ),
          ),
        ];
        if (grades.isEmpty) {
          children.insert(
            3,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: EmptyState(
                title: 'ليس لديك صفوف مُعيّنة',
                icon: Icons.grade_level_outlined,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: children,
        );
      },
    );
  }
}

/// ملاحظة مساعدة: استخدام [AppConstants] لتجنّب تحذيرات الاستيراد غير المستعمل في بعض السياقات.
typedef _Const = AppConstants;