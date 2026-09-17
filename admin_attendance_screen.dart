import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_status_chip.dart';

/// شاشة متابعة الحضور للإدارة: يوم محدد وصف محدد.
class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  static const String routeName = '/admin/attendance';

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final AppRepository _repository = AppRepository.instance;
  DateTime _date = DateTime.now();
  String _gradeFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    final DateTime? last = _repository.lastAttendanceDate;
    if (last != null) {
      _date = last;
    }
  }

  void _shiftDay(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
  }

  List<Student> get _students {
    if (_gradeFilter == 'الكل') {
      return _repository.students;
    }
    return _repository.studentsInGrade(_gradeFilter);
  }

  /// حالة الطالب في اليوم المحدد (أول حالة مسجلة).
  AttendanceStatus? _statusFor(Student student) {
    final List<AttendanceRecord> records = _repository
        .recordsForStudent(student.id)
        .where((AttendanceRecord record) =>
            record.date.year == _date.year &&
            record.date.month == _date.month &&
            record.date.day == _date.day)
        .toList();
    if (records.isEmpty) {
      return null;
    }
    if (records.any(
      (AttendanceRecord record) => record.status == AttendanceStatus.absent,
    )) {
      return AttendanceStatus.absent;
    }
    if (records.any(
      (AttendanceRecord record) => record.status == AttendanceStatus.late,
    )) {
      return AttendanceStatus.late;
    }
    if (records.any(
      (AttendanceRecord record) => record.status == AttendanceStatus.excused,
    )) {
      return AttendanceStatus.excused;
    }
    return AttendanceStatus.present;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('متابعة الحضور')),
      body: ListenableBuilder(
        listenable: _repository,
        builder: (BuildContext context, Widget? child) {
          final AttendanceSummary summary = _gradeFilter == 'الكل'
              ? _repository.summaryForDate(_date)
              : AttendanceSummary.fromRecords(
                  _repository.recordsForGradeOnDate(_gradeFilter, _date),
                );
          final List<Student> students = _students;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              _dateCard(),
              const SizedBox(height: 12),
              SectionCard(
                title: 'ملخص اليوم',
                subtitle: '${_gradeFilter} - ${ArFormat.weekday(_date)}',
                icon: Icons.insights_outlined,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _summaryBox(
                            'حاضر',
                            '${summary.present}',
                            AppTheme.presentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _summaryBox(
                            'غائب',
                            '${summary.absent}',
                            AppTheme.absentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _summaryBox(
                            'متأخر',
                            '${summary.late}',
                            AppTheme.lateColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _summaryBox(
                            'بعذر',
                            '${summary.excused}',
                            AppTheme.midPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نسبة الحضور: ${ArFormat.percent(summary.rate)} '
                      'من أصل ${summary.total} سجل',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.notMarkedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              students.isEmpty
                  ? const EmptyState(
                      title: 'لا يوجد طلاب',
                      message: 'لا يوجد طلاب في هذا الصف.',
                      icon: Icons.groups_outlined,
                    )
                  : Column(
                      children: students
                          .map(
                            (Student student) => _studentTile(student),
                          )
                          .toList(),
                    ),
            ],
          );
        },
      ),
    );
  }

Widget _dateCard() {
    final List<String> grades = <String>['الكل', ..._repository.activeGrades];
    return SectionCard(
      title: 'اختيار اليوم والصف',
      icon: Icons.calendar_month_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'اليوم السابق',
                onPressed: () => _shiftDay(-1),
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(_date.year - 1),
                      lastDate: DateTime(_date.year + 1),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.lightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ArFormat.weekday(_date)} - ${ArFormat.date(_date)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepPurple,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'اليوم التالي',
                onPressed: () => _shiftDay(1),
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: grades
                  .map(
                    (String grade) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(grade),
                        selected: _gradeFilter == grade,
                        onSelected: (_) =>
                            setState(() => _gradeFilter = grade),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.deepPurple),
          ),
        ],
      ),
    );
  }

  Widget _studentTile(Student student) {
    final AttendanceStatus? status = _statusFor(student);
    final Color color = status?.color ?? AppTheme.notMarkedColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepPurple,
                  ),
                ),
                Text(
                  student.gradeAndClassroom,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.notMarkedColor,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: status?.label ?? 'لم يُحضّر',
            color: color,
            icon: status?.icon ?? Icons.help_outline,
            dense: true,
          ),
        ],
      ),
    );
  }
}