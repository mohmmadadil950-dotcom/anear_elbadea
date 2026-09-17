import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_status_chip.dart';

/// شاشة إدارة الطلاب: بحث وتصفية وإضافة وتعديل وحذف.
class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  static const String routeName = '/admin/students';

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final AppRepository _repository = AppRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _gradeFilter = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> get _filtered {
    final List<Student> base = _repository.searchStudents(_query);
    if (_gradeFilter == 'الكل') {
      return base;
    }
    return base.where((Student item) => item.grade == _gradeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> grades = <String>[
      'الكل',
      ..._repository.activeGrades,
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('إدارة الطلاب')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalPurple,
        foregroundColor: Colors.white,
        onPressed: () => showStudentForm(context, _repository),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('طالب جديد'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الصف أو هاتف ولي الأمر',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: grades.length,
              itemBuilder: (BuildContext context, int index) {
                final String grade = grades[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(grade),
                    selected: _gradeFilter == grade,
                    onSelected: (_) => setState(() => _gradeFilter = grade),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _repository,
              builder: (BuildContext context, Widget? child) {
                final List<Student> students = _filtered;
                if (students.isEmpty) {
                  return const EmptyState(
                    title: 'لا توجد نتائج',
                    message: 'جرّب تعديل البحث أو الفلتر.',
                    icon: Icons.search_off,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _row(students[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _row(Student student) {
    final AttendanceSummary summary = _repository.summaryForStudent(student.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: <Widget>[
          PersonAvatar(name: student.fullName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.gradeAndClassroom,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.notMarkedColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    StatusChip(
                      label: 'الحضور ${ArFormat.percent(summary.rate)}',
                      color: summary.rate >= 0.9
                          ? AppTheme.presentColor
                          : AppTheme.lateColor,
                      dense: true,
                    ),
                    const SizedBox(width: 6),
                    if (summary.absent > 0)
                      StatusChip(
                        label: '${summary.absent} غياب',
                        color: AppTheme.absentColor,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, color: AppTheme.notMarkedColor),
            onSelected: (String value) {
              switch (value) {
                case 'view':
                  _showDetails(student);
                case 'edit':
                  showStudentForm(context, _repository, existing: student);
                case 'delete':
                  _confirmDelete(student);
              }
            },
            itemBuilder:
                (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'view', child: Text('عرض الملف')),
              PopupMenuItem<String>(value: 'edit', child: Text('تعديل')),
              PopupMenuItem<String>(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(Student student) {
    final AppRepository repository = _repository;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) {
        final AttendanceSummary summary =
            repository.summaryForStudent(student.id);
        final double average = repository.averageForStudent(student.id);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    PersonAvatar(name: student.fullName, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepPurple,
                            ),
                          ),
                          Text(
                            student.gradeAndClassroom,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.notMarkedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _detailsCard(student),
                _indicatorsCard(repository, student, summary, average),
              ],
            ),
          ),
        );
      },
    );
  }

SectionCard _detailsCard(Student student) {
    return SectionCard(
      title: 'بيانات الطالب',
      icon: Icons.badge_outlined,
      child: Column(
        children: <Widget>[
          InfoRow(icon: Icons.fingerprint, label: 'المعرف', value: student.id),
          InfoRow(
            icon: Icons.person_outline,
            label: 'ولي الأمر',
            value: student.guardianName,
          ),
          InfoRow(
            icon: Icons.phone_iphone,
            label: 'الهاتف',
            value: ArFormat.phone(student.guardianPhone),
          ),
          InfoRow(
            icon: Icons.location_on_outlined,
            label: 'العنوان',
            value: student.address,
          ),
          InfoRow(
            icon: Icons.directions_bus_outlined,
            label: 'النقل',
            value: student.busRoute,
          ),
          InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'التسجيل',
            value: ArFormat.date(student.enrolledAt),
          ),
        ],
      ),
    );
  }

  SectionCard _indicatorsCard(
    AppRepository repository,
    Student student,
    AttendanceSummary summary,
    double average,
  ) {
    return SectionCard(
      title: 'المؤشرات',
      icon: Icons.insights_outlined,
      child: Column(
        children: <Widget>[
          InfoRow(
            icon: Icons.event_available_outlined,
            label: 'الحضور',
            value: '${ArFormat.percent(summary.rate)} '
                '(${summary.attended}/${summary.total})',
          ),
          InfoRow(
            icon: Icons.cancel_outlined,
            label: 'الغياب',
            value: '${summary.absent} يوم',
          ),
          InfoRow(
            icon: Icons.grading_outlined,
            label: 'المعدل',
            value: ArFormat.percent(average),
          ),
          InfoRow(
            icon: Icons.emoji_events_outlined,
            label: 'الترتيب',
            value: '${repository.rankOfStudent(student.id)} في الصف',
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Student student) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text(
          'سيتم حذف ${student.fullName} مع سجلات حضوره ودرجاته. '
          'هل ترغب بالمتابعة؟',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.absentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _repository.removeStudent(student.id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

}

/// نافذة إضافة أو تعديل طالب.
Future<void> showStudentForm(
  BuildContext context,
  AppRepository repository, {
  Student? existing,
}) async {
  final TextEditingController nameController =
      TextEditingController(text: existing?.fullName ?? '');
  final TextEditingController guardianController =
      TextEditingController(text: existing?.guardianName ?? '');
  final TextEditingController phoneController =
      TextEditingController(text: existing?.guardianPhone ?? '');
  final TextEditingController addressController =
      TextEditingController(text: existing?.address ?? 'بغداد - ');
  String grade = existing?.grade ?? AppConstants.grades.first;
  String classroom = existing?.classroom ?? AppConstants.classrooms.first;
  String busRoute = existing?.busRoute ?? 'بدون نقل';
  const List<String> busRoutes = <String>[
    'خط الكرادة',
    'خط الأعظمية',
    'خط الجادرية',
    'خط الحرية',
    'بدون نقل',
  ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    existing == null ? 'إضافة طالب جديد' : 'تعديل بيانات الطالب',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الطالب الثلاثي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: guardianController,
                    decoration: const InputDecoration(
                      labelText: 'اسم ولي الأمر',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'هاتف ولي الأمر',
                      hintText: '07XXXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _choices(
                    title: 'الصف',
                    options: AppConstants.grades,
                    selected: grade,
                    onSelected: (String value) =>
                        setState(() => grade = value),
                  ),
                  const SizedBox(height: 12),
                  _choices(
                    title: 'القاعة',
                    options: AppConstants.classrooms,
                    selected: classroom,
                    onSelected: (String value) =>
                        setState(() => classroom = value),
                  ),
                  const SizedBox(height: 12),
                  _choices(
                    title: 'النقل المدرسي',
                    options: busRoutes,
                    selected: busRoute,
                    onSelected: (String value) =>
                        setState(() => busRoute = value),
                  ),
                  const SizedBox(height: 16),
                  _saveButton(
                    sheetContext,
                    repository,
                    existing: existing,
                    name: nameController,
                    guardian: guardianController,
                    phone: phoneController,
                    address: addressController,
                    grade: grade,
                    classroom: classroom,
                    busRoute: busRoute,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// مجموعة اختيارات (Chips) بعنوان.
Widget _choices({
  required String title,
  required List<String> options,
  required String selected,
  required ValueChanged<String> onSelected,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options
            .map(
              (String item) => ChoiceChip(
                label: Text(item),
                selected: selected == item,
                onSelected: (_) => onSelected(item),
              ),
            )
            .toList(),
      ),
    ],
  );
}

Widget _saveButton(
  BuildContext sheetContext,
  AppRepository repository, {
  required Student? existing,
  required TextEditingController name,
  required TextEditingController guardian,
  required TextEditingController phone,
  required TextEditingController address,
  required String grade,
  required String classroom,
  required String busRoute,
}) {
  return SizedBox(
    height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.royalPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        final String fullName = name.text.trim();
        final String guardianName = guardian.text.trim();
        final String guardianPhone = phone.text.trim();
        if (fullName.isEmpty ||
            guardianName.isEmpty ||
            guardianPhone.length != 11 ||
            !guardianPhone.startsWith('07')) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            const SnackBar(
              content: Text('يُرجى إكمال الحقول ورقم هاتف صحيح (11 رقماً)'),
            ),
          );
          return;
        }
        final Student student = Student(
          id: existing?.id ?? repository.nextId('S'),
          fullName: fullName,
          grade: grade,
          classroom: classroom,
          guardianName: guardianName,
          guardianPhone: guardianPhone,
          address: address.text.trim(),
          busRoute: busRoute,
          enrolledAt: existing?.enrolledAt ?? DateTime.now(),
        );
        if (existing == null) {
          repository.addStudent(student);
        } else {
          repository.updateStudent(student);
        }
        Navigator.of(sheetContext).pop();
      },
      child: Text(existing == null ? 'حفظ الطالب' : 'حفظ التعديلات'),
    ),
  );
}