import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/schedule.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// واجهة مهام المدرّب: إظهار الواجبات المُوكلة له مع زر إغلاقها.
class TeacherHomeworkScreen extends StatelessWidget {
  const TeacherHomeworkScreen({super.key});

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

    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        final List<HomeworkAssignment> assignments =
            repo.homeworkForTeacher(teacherName);

        return Scaffold(
          body: assignments.isEmpty
              ? const EmptyState(
                  title: 'لا توجد واجبات مُوكلة لك حالياً',
                  icon: Icons.menu_book_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final HomeworkAssignment hw = assignments[index];
                    final int submittedCount =
                        hw.submittedStudentIds.length;
                    return SectionCard(
                      title: hw.title,
                      subtitle:
                          '${hw.subject} • ${hw.grade} • تسليم '
                          '${ArFormat.date(hw.dueDate)}',
                      icon: Icons.menu_book_outlined,
                      trailing: Chip(
                        label: Text('$submittedCount / غير محدد'),
                        backgroundColor: Colors.deepPurple.shade50,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}