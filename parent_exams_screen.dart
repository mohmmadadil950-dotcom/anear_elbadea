import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/assessment.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// شاشة جدول الامتحانات للأبناء من ولي الأمر.
class ParentExamsScreen extends StatelessWidget {
  const ParentExamsScreen({super.key});

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
      appBar: AppBar(title: const Text('جداول الامتحانات')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int index) {
          final Student student = children[index];
          final List<ExamSchedule> exams = repo.examsForGrade(student.grade);
          return SectionCard(
            title: student.fullName,
            subtitle: student.gradeAndClassroom,
            icon: Icons.menu_book_outlined,
            child: exams.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('لا توجد امتحانات مجدوولة'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int eIndex) {
                      final ExamSchedule exam = exams[eIndex];
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.menu_book_outlined, size: 18)),
                        title: Text(exam.title),
                        subtitle: Text(
                            '${exam.subject} • ${exam.classroom} • ${ArFormat.date(exam.date)} ${exam.startTime}'),
                        trailing: Chip(
                            label: Text(exam.isFinished
                                ? 'منتهي'
                                : 'قادم'),
                            backgroundColor: exam.isFinished
                                ? Colors.grey.shade200
                                : Colors.deepPurple.shade50),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}