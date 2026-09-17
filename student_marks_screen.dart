import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/assessment.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// شاشة درجات الطالب: جدول بالمواد والنسبة والنتيجة.
class StudentMarksScreen extends StatelessWidget {
  const StudentMarksScreen({super.key});

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
    final List<MarkEntry> entries = repo.marksForStudent(student.id);

    return Scaffold(
      appBar: AppBar(title: const Text('درجاتي')),
      body: entries.isEmpty
          ? const EmptyState(
              title: 'لا توجد درجات مسجلة بعد',
              icon: Icons.grading_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final MarkEntry entry = entries[index];
                return SectionCard(
                  title: entry.subject,
                  subtitle: ArFormat.date(entry.updatedAt),
                  icon: Icons.subject_outlined,
                  trailing: Chip(
                    label: Text(entry.resultLabel),
                    backgroundColor:
                        entry.resultColor.withValues(alpha: 0.15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildRow('الاسم', entry.studentName),
                      _buildRow('الصف', entry.grade),
                      _buildRow(
                        'المجموع',
                        '${entry.total.toStringAsFixed(0)} / ${MarkEntry.totalMax.toStringAsFixed(0)}',
                      ),
                      _buildRow(
                        'النسبة',
                        ArFormat.percent(entry.percentage),
                      ),
                      _buildRow(
                        'التقدير',
                        entry.grade9000,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}