import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/assessment.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// شاشة درجات الأبناء من ولي الأمر.
class ParentMarksScreen extends StatelessWidget {
  const ParentMarksScreen({super.key});

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
      appBar: AppBar(title: const Text('درجات الأبناء')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int index) {
          final Student student = children[index];
          final List<MarkEntry> entries = repo.marksForStudent(student.id);
          final double average = repo.averageForStudent(student.id) / 100;
          return SectionCard(
            title: student.fullName,
            subtitle: '${student.gradeAndClassroom} • المعدل: ${ArFormat.percent(average)}',
            icon: Icons.grading_outlined,
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('لا توجد درجات مسجلة'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int mIndex) {
                      final MarkEntry entry = entries[mIndex];
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.subject_outlined, size: 18)),
                        title: Text(entry.subject),
                        subtitle: Text(
                            '${entry.total.toStringAsFixed(0)} / ${MarkEntry.totalMax.toStringAsFixed(0)}'),
                        trailing: Text(
                          entry.resultLabel,
                          style: TextStyle(color: entry.resultColor),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}