import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/assessment.dart';
import '../models/user.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_status_chip.dart';

/// جدول الامتحانات: يعرض امتحانات الصف المختار.
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  static const String routeName = '/exams';

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String? _grade;

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;
    final List<String> grades = user == null
        ? repository.activeGrades
        : repository.gradesForUser(user);
    final String? selected = _grade != null && grades.contains(_grade)
        ? _grade
        : (grades.isEmpty ? null : grades.first);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('جدول الامتحانات')),
      body: Column(
        children: <Widget>[
          if (grades.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: grades
                      .map(
                        (String grade) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(grade),
                            selected: grade == selected,
                            onSelected: (_) => setState(() => _grade = grade),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: repository,
              builder: (BuildContext context, Widget? child) {
                final List<ExamSchedule> exams = selected == null
                    ? const <ExamSchedule>[]
                    : repository.examsForGrade(selected);
                if (exams.isEmpty) {
                  return const EmptyState(
                    title: 'لا توجد امتحانات',
                    message: 'سيتم نشر جدول الامتحانات عند اعتماده.',
                    icon: Icons.event_note_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: exams.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _card(exams[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ExamSchedule exam) {
    final bool finished = exam.isFinished;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: finished
                  ? const LinearGradient(
                      colors: <Color>[Color(0xFF9E9EB4), Color(0xFF7A7A94)],
                    )
                  : AppTheme.horizontalGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  '${exam.date.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ArFormat.monthName(exam.date.month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        exam.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepPurple,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: finished ? 'منتهي' : 'قادم',
                      color: finished
                          ? AppTheme.notMarkedColor
                          : AppTheme.presentColor,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${exam.title} - ${exam.grade}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.notMarkedColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: <Widget>[
                    _meta(
                      Icons.schedule,
                      '${exam.startTime} (${exam.durationLabel})',
                    ),
                    _meta(Icons.meeting_room_outlined, exam.classroom),
                    _meta(Icons.person_outline, exam.supervisorName),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: AppTheme.midPurple),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.deepPurple),
        ),
      ],
    );
  }
}