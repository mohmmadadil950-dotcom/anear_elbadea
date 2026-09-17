import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/user.dart';
import '../widgets/app_info_row.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_status_chip.dart';
import 'login_screen.dart';

/// شاشة الحساب: بيانات المستخدم وبيانات المجموعة.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('حسابي')),
      body: user == null
          ? const Center(child: Text('لا يوجد مستخدم مسجل'))
          : ListView(
              padding: const EdgeInsets.all(14),
              children: <Widget>[
                _header(user),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'البيانات الشخصية',
                  icon: Icons.person_outline,
                  child: Column(
                    children: <Widget>[
                      InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'الاسم',
                        value: user.fullName,
                      ),
                      InfoRow(
                        icon: Icons.phone_iphone,
                        label: 'الهاتف',
                        value: ArFormat.phone(user.phone),
                      ),
                      InfoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'الدور',
                        value: user.role.label,
                      ),
                      if (user.title != null)
                        InfoRow(
                          icon: Icons.work_outline,
                          label: 'المسمى',
                          value: user.title!,
                        ),
                      if (user.email != null)
                        InfoRow(
                          icon: Icons.mail_outline,
                          label: 'البريد',
                          value: user.email!,
                        ),
                    ],
                  ),
                ),
                ..._roleDetails(repository, user),
                ..._schoolCard(repository),
                _logoutCard(context, repository),
              ],
            ),
    );
  }

  Widget _header(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: AppTheme.royalGradient,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.gold,
            child: Text(
              user.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepPurple,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                StatusChip(
                  label: user.role.label,
                  color: AppTheme.gold,
                  icon: user.role.icon,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _schoolCard(AppRepository repository) {
    return <Widget>[
      SectionCard(
        title: 'عن المجموعة',
        icon: Icons.school_outlined,
        child: Column(
          children: <Widget>[
            const InfoRow(
              icon: Icons.account_balance_outlined,
              label: 'الاسم',
              value: AppConstants.schoolName,
            ),
            const InfoRow(
              icon: Icons.location_on_outlined,
              label: 'العنوان',
              value: AppConstants.schoolAddress,
            ),
            InfoRow(
              icon: Icons.groups_outlined,
              label: 'الطلاب',
              value: '${repository.studentCount} طالباً وطالبة',
            ),
            InfoRow(
              icon: Icons.co_present_outlined,
              label: 'المدرسون',
              value: '${repository.teacherCount} مدرساً',
            ),
          ],
        ),
      ),
    ];
  }

  Widget _logoutCard(BuildContext context, AppRepository repository) {
    return SectionCard(
      child: SizedBox(
        height: 46,
        child: OutlinedButton.icon(
          onPressed: () {
            repository.signOut();
            Navigator.of(context).pushNamedAndRemoveUntil(
              LoginScreen.routeName,
              (Route<dynamic> route) => false,
            );
          },
          icon: const Icon(Icons.logout),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.absentColor,
            side: const BorderSide(color: AppTheme.absentColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: const Text('تسجيل الخروج'),
        ),
      ),
    );
  }

  List<Widget> _roleDetails(AppRepository repository, AppUser user) {
    final List<Widget> widgets = <Widget>[];

    if (user.role == UserRole.student || user.role == UserRole.parent) {
      final List<Student> children = repository.linkedStudents(user);
      if (children.isNotEmpty) {
        widgets.add(
          SectionCard(
            title: user.role == UserRole.parent ? 'أبنائي' : 'بياناتي الدراسية',
            icon: Icons.school_outlined,
            child: Column(
              children: children
                  .map(
                    (Student student) => InfoRow(
                      icon: Icons.person_outline,
                      label: student.fullName,
                      value: student.gradeAndClassroom,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      }
    }

    if (user.role == UserRole.teacher) {
      final Teacher? teacher = repository.linkedTeacher(user);
      if (teacher != null) {
        widgets.add(
          SectionCard(
            title: 'بياناتي التدريسية',
            icon: Icons.co_present_outlined,
            child: Column(
              children: <Widget>[
                InfoRow(
                  icon: Icons.menu_book_outlined,
                  label: 'المواد',
                  value: teacher.subjectsLabel,
                ),
                InfoRow(
                  icon: Icons.groups_outlined,
                  label: 'الصفوف',
                  value: teacher.gradesLabel,
                ),
                InfoRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'المرشد',
                  value: teacher.homeroomClassroom,
                ),
                InfoRow(
                  icon: Icons.event_note_outlined,
                  label: 'الحصص الأسبوعية',
                  value: '${teacher.weeklyLessons} حصة',
                ),
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'تاريخ المباشرة',
                  value: ArFormat.date(teacher.joinedAt),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (user.role == UserRole.admin) {
      widgets.add(
        SectionCard(
          title: 'ملخص إداري',
          icon: Icons.insights_outlined,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: Icons.groups_outlined,
                label: 'الطلاب',
                value: '${repository.studentCount}',
              ),
              InfoRow(
                icon: Icons.co_present_outlined,
                label: 'المدرسون',
                value: '${repository.teacherCount}',
              ),
              InfoRow(
                icon: Icons.event_available_outlined,
                label: 'نسبة الحضور',
                value: ArFormat.percent(repository.latestAttendanceRate),
              ),
              InfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'المتأخرات',
                value: '${repository.totalOutstanding.toStringAsFixed(0)} د.ع',
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}