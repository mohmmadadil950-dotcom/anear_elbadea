import 'package:flutter/material.dart';

import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/assessment.dart';
import '../../models/student.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';

/// شاشة الدرجات الخاصة بالمدرّب: عرض وتعديل درجات الصفوف التي يدرّسها.
class TeacherMarksScreen extends StatefulWidget {
  const TeacherMarksScreen({super.key});

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  String? _grade;
  String? _subject;

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
    final List<String> grades = repo.gradesForUser(user);

    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        final List<Widget> children = <Widget>[];

        if (grades.isNotEmpty) {
          children.add(
            SectionCard(
              title: 'إعدادات الدرجات',
              icon: Icons.settings_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: _grade,
                    decoration: const InputDecoration(
                      labelText: 'الصف',
                      border: OutlineInputBorder(),
                    ),
                    items: grades
                        .map((String value) => DropdownMenuItem<String>(
                            value: value, child: Text(value)))
                        .toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _grade = value;
                        _subject = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_grade != null)
                    DropdownButtonFormField<String>(
                      value: _subject,
                      decoration: const InputDecoration(
                        labelText: 'المادة',
                        border: OutlineInputBorder(),
                      ),
                      items: (repo.marksForGrade(_grade!)
                              .map((MarkEntry m) => m.subject)
                              .toSet()
                              .toList()
                            ..sort())
                          .map((String value) => DropdownMenuItem<String>(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? value) {
                        setState(() => _subject = value);
                      },
                    ),
                ],
              ),
            ),
          );
        }

        if (_grade != null && _subject != null) {
          final List<MarkEntry> entries =
              repo.marksForGrade(_grade!, subject: _subject!);
          if (entries.isEmpty) {
            children.add(
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState(title: 'لا توجد درجات مسجلة'),
              ),
            );
          } else {
            children.add(
              SectionCard(
                title:
                    'درجات $_subject - $_grade (${entries.length} طالب)',
                icon: Icons.grading_outlined,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final MarkEntry entry = entries[index];
                    final Student? student = repo.studentById(entry.studentId);
                    return ListTile(
                      leading: CircleAvatar(child: Text(student?.initials ?? '؟')),
                      title: Text(entry.studentName),
                      subtitle: Text(
                        '${ArFormat.percent(entry.percentage)} • ${entry.resultLabel}',
                      ),
                      trailing: Text(
                        '${entry.total.toStringAsFixed(0)} / ${MarkEntry.totalMax.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }

        return Scaffold(
          body: children.isEmpty
              ? const Center(child: EmptyState(title: 'اختر الصف والمادة'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: children,
                ),
        );
      },
    );
  }
}