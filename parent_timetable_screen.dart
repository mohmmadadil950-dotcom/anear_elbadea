import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/timetable_board.dart';

/// جدول حصص الأبناء من ولي الأمر.
class ParentTimetableScreen extends StatelessWidget {
  const ParentTimetableScreen({super.key});

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
      appBar: AppBar(title: const Text('جداول الأبناء')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int index) {
          final Student student = children[index];
          final List<LessonSlot> lessons =
              repo.lessonsForGrade(student.grade);
          return SectionCard(
            title: student.fullName,
            subtitle: student.gradeAndClassroom,
            icon: Icons.calendar_month_outlined,
            child: lessons.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('لا توجد حصص مسجلة لهذا الصف'),
                  )
                : TimetableBoard(
                    lessons: lessons,
                    showGrade: true,
                  ),
          );
        },
      ),
    );
  }
}