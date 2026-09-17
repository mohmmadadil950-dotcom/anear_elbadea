import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/schedule.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// واجهة واجبات الطالب: إرسال أو إلغاء تسليم واجب.
class StudentHomeworkScreen extends StatelessWidget {
  const StudentHomeworkScreen({super.key});

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
    final List<HomeworkAssignment> assignments =
        repo.homeworkForGrade(student.grade);

    if (assignments.isEmpty) {
      return const EmptyState(
        title: 'لا توجد واجبات مُعلّنة',
        icon: Icons.menu_book_outlined,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('واجباتي')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: assignments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final HomeworkAssignment hw = assignments[index];
          final bool submitted = hw.isSubmittedBy(student.id);
          return SectionCard(
            title: hw.title,
            subtitle:
                '${hw.subject} • تسليم ${ArFormat.date(hw.dueDate)} • ${hw.daysLeft} يوم متبقي',
            icon: Icons.menu_book_outlined,
            trailing: submitted
                ? const Icon(Icons.check_circle, color: Color(0xFF1BA75C))
                : hw.isOverdue
                    ? const Icon(Icons.warning_amber_outlined,
                        color: Color(0xFFE0463C))
                    : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(hw.details),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      repo.toggleHomeworkSubmission(hw.id, student.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(submitted
                              ? 'تم إلغاء تسليم الواجب'
                              : 'تم تسليم الواجب'),
                        ),
                      );
                    },
                    icon: Icon(submitted
                        ? Icons.undo_outlined
                        : Icons.upload_outlined),
                    label: Text(submitted ? 'إلغاء التسليم' : 'تسليم'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
