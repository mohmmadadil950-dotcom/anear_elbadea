import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/schedule.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// واجهة واجبات الأبناء من ولي الأمر: إرسال/إلغاء تسليم واجب لكل ابن.
class ParentHomeworkScreen extends StatelessWidget {
  const ParentHomeworkScreen({super.key});

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
      appBar: AppBar(title: const Text('واجبات الأبناء')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int index) {
          final Student student = children[index];
          final List<HomeworkAssignment> assignments =
              repo.homeworkForGrade(student.grade);
          return SectionCard(
            title: student.fullName,
            subtitle: student.gradeAndClassroom,
            icon: Icons.menu_book_outlined,
            child: assignments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('لا توجد واجبات مُعلّنة'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assignments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int hIndex) {
                      final HomeworkAssignment hw = assignments[hIndex];
                      final bool submitted =
                          hw.isSubmittedBy(student.id);
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.assignment_outlined, size: 18)),
                        title: Text(hw.title),
                        subtitle: Text(
                            '${hw.subject} • تسليم ${ArFormat.date(hw.dueDate)}'),
                        trailing: submitted
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF1BA75C))
                            : hw.isOverdue
                                ? const Icon(Icons.warning_amber_outlined,
                                    color: Color(0xFFE0463C))
                                : null,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}