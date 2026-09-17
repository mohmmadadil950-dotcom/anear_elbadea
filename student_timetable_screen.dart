import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/timetable_board.dart';

/// جدول حصص الطالب الأسبوعي.
class StudentTimetableScreen extends StatelessWidget {
  const StudentTimetableScreen({super.key});

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
    final List<LessonSlot> lessons = repo.lessonsForGrade(student.grade);

    return Scaffold(
      appBar: AppBar(title: const Text('جدولي الدراسي')),
      body: lessons.isEmpty
          ? const EmptyState(
              title: 'لا يوجد حصص مُسجلة لهذا الصف',
              icon: Icons.calendar_month_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                SectionCard(
                  title: '${student.fullName} - ${student.gradeAndClassroom}',
                  icon: Icons.calendar_month_outlined,
                  child: TimetableBoard(
                    lessons: lessons,
                    showGrade: true,
                  ),
                ),
              ],
            ),
    );
  }
}