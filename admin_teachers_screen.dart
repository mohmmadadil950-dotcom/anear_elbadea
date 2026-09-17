import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/teacher.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_empty_state.dart';

/// شاشة إدارة المدرسين: بحث وإضافة وتعديل وحذف.
class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  static const String routeName = '/admin/teachers';

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  final AppRepository _repository = AppRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('إدارة المدرسين')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalPurple,
        foregroundColor: Colors.white,
        onPressed: () => showTeacherForm(context, _repository),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('مدرس جديد'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (String value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو المادة أو الهاتف',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _repository,
              builder: (BuildContext context, Widget? child) {
                final List<Teacher> teachers =
                    _repository.searchTeachers(_query);
                if (teachers.isEmpty) {
                  return const EmptyState(
                    title: 'لا توجد نتائج',
                    message: 'جرّب تعديل كلمة البحث.',
                    icon: Icons.search_off,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: teachers.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _row(teachers[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Teacher teacher) {
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
          PersonAvatar(
            name: teacher.fullName,
            size: 44,
            icon: Icons.co_present_outlined,
            color: AppTheme.midPurple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  teacher.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teacher.subjectsLabel,
                  style: const TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${teacher.gradesLabel} - ${ArFormat.phone(teacher.phone)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.notMarkedColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      '${teacher.weeklyLessons} حصة أسبوعياً',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.midPurple,
                      ),
                    ),
                    if (teacher.hasHomeroom) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        'مرشد ${teacher.homeroomClassroom}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.notMarkedColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, color: AppTheme.notMarkedColor),
            onSelected: (String value) {
              if (value == 'edit') {
                showTeacherForm(context, _repository, existing: teacher);
              } else {
                _confirmDelete(teacher);
              }
            },
            itemBuilder:
                (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('تعديل')),
              PopupMenuItem<String>(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Teacher teacher) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('حذف المدرس'),
        content: Text('سيتم حذف ${teacher.fullName} من الكادر التدريسي.'),
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
              _repository.removeTeacher(teacher.id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

/// نافذة إضافة أو تعديل مدرس.
Future<void> showTeacherForm(
  BuildContext context,
  AppRepository repository, {
  Teacher? existing,
}) async {
  final TextEditingController nameController =
      TextEditingController(text: existing?.fullName ?? '');
  final TextEditingController phoneController =
      TextEditingController(text: existing?.phone ?? '');
  final TextEditingController lessonsController =
      TextEditingController(text: '${existing?.weeklyLessons ?? 18}');
  final List<String> subjects = List<String>.of(existing?.subjects ?? <String>[]);
  final List<String> grades = List<String>.of(existing?.grades ?? <String>[]);
  String homeroom = existing?.homeroomClassroom ?? 'لا يوجد';
  final List<String> homeroomOptions = <String>[
    'لا يوجد',
    ...AppConstants.classrooms,
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
          void toggle(List<String> list, String value) {
            setState(() {
              if (list.contains(value)) {
                list.remove(value);
              } else {
                list.add(value);
              }
            });
          }

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
                    existing == null ? 'إضافة مدرس جديد' : 'تعديل بيانات المدرس',
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
                      labelText: 'اسم المدرس',
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
                      labelText: 'رقم الهاتف',
                      hintText: '07XXXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lessonsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'عدد الحصص الأسبوعية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('المواد (يمكن اختيار أكثر من مادة)'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AppConstants.subjects
                        .map(
                          (String item) => FilterChip(
                            label: Text(item),
                            selected: subjects.contains(item),
                            onSelected: (_) => toggle(subjects, item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('الصفوف (يمكن اختيار أكثر من صف)'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AppConstants.grades
                        .map(
                          (String item) => FilterChip(
                            label: Text(item),
                            selected: grades.contains(item),
                            onSelected: (_) => toggle(grades, item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('الإرشاد (قاعة)'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: homeroomOptions
                        .map(
                          (String item) => ChoiceChip(
                            label: Text(item),
                            selected: homeroom == item,
                            onSelected: (_) =>
                                setState(() => homeroom = item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _teacherSaveButton(
                    sheetContext,
                    repository,
                    existing: existing,
                    name: nameController,
                    phone: phoneController,
                    lessons: lessonsController,
                    subjects: subjects,
                    grades: grades,
                    homeroom: homeroom,
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

/// زر حفظ بيانات المدرس داخل النافذة.
Widget _teacherSaveButton(
  BuildContext sheetContext,
  AppRepository repository, {
  required Teacher? existing,
  required TextEditingController name,
  required TextEditingController phone,
  required TextEditingController lessons,
  required List<String> subjects,
  required List<String> grades,
  required String homeroom,
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
        final String phoneNumber = phone.text.trim();
        if (fullName.isEmpty ||
            phoneNumber.length != 11 ||
            !phoneNumber.startsWith('07') ||
            subjects.isEmpty ||
            grades.isEmpty) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            const SnackBar(
              content: Text(
                'أكمل الاسم والهاتف واختر مادة واحدة على الأقل وصفاً واحداً',
              ),
            ),
          );
          return;
        }
        final Teacher teacher = Teacher(
          id: existing?.id ?? repository.nextId('T'),
          fullName: fullName,
          phone: phoneNumber,
          subjects: List<String>.of(subjects),
          grades: List<String>.of(grades),
          homeroomClassroom: homeroom,
          joinedAt: existing?.joinedAt ?? DateTime.now(),
          weeklyLessons: int.tryParse(lessons.text.trim()) ?? 18,
        );
        if (existing == null) {
          repository.addTeacher(teacher);
        } else {
          repository.updateTeacher(teacher);
        }
        Navigator.of(sheetContext).pop();
      },
      child: Text(existing == null ? 'حفظ المدرس' : 'حفظ التعديلات'),
    ),
  );
}