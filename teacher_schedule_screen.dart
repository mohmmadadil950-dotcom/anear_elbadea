import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../../models/teacher.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/timetable_board.dart';

/// جدول حصص المدرس الأسبوعي.
class TeacherScheduleScreen extends StatelessWidget {
  const TeacherScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppRepository repo = AppRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        final AppUser? user = repo.currentUser;
        final Teacher? teacher =
            user == null ? null : repo.linkedTeacher(user);
        if (teacher == null) {
          return const EmptyState(
            title: 'لا يوجد ملف مدرس مرتبط بالحساب',
            icon: Icons.calendar_month_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SectionCard(
              title: 'جدولي الأسبوعي',
              subtitle: '${teacher.fullName} - ${teacher.gradesLabel}',
              icon: Icons.calendar_month_outlined,
              child: TimetableBoard(
                lessons: repo.lessonsForTeacher(teacher.fullName),
                showGrade: true,
              ),
            ),
          ],
        );
      },
    );
  }
}