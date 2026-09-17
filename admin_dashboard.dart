import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/announcement.dart';
import '../../models/attendance.dart';
import '../../models/requests.dart';
import '../../models/student.dart';
import '../../models/user.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_status_chip.dart';
import '../../widgets/dashboard_header.dart';
import '../announcements_screen.dart';
import '../requests_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_students_screen.dart';
import 'admin_teachers_screen.dart';

/// لوحة الإدارة العامة لمجموعة مدارس أنوار البديع.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const String routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;

    return Scaffold(
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: user == null
            ? const Center(child: Text('لا يوجد مستخدم مسجل', style: TextStyle(color: Colors.white)))
            : ListenableBuilder(
                listenable: repository,
                builder: (BuildContext context, Widget? child) {
                  final DateTime? attendanceDate = repository.lastAttendanceDate;
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      DashboardHeader(
                        user: user,
                        subtitle: 'لوحة الإدارة العامة',
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: <Widget>[
                            _statsGrid(repository, attendanceDate),
                            const SizedBox(height: 12),
                            _quickActions(context),
                            const SizedBox(height: 12),
                            _attendanceSection(repository, attendanceDate),
                            const SizedBox(height: 12),
                            _financeSection(repository),
                            const SizedBox(height: 12),
                            _requestsSection(context, repository),
                            const SizedBox(height: 12),
                            _announcementsSection(context, repository),
                            const SizedBox(height: 12),
                            _absentSection(repository),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

Widget _statsGrid(AppRepository repository, DateTime? attendanceDate) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'عدد الطلاب',
                value: '${repository.studentCount}',
                icon: Icons.groups_outlined,
                hint: 'في ${repository.activeGrades.length} صفاً',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'المدرسون',
                value: '${repository.teacherCount}',
                icon: Icons.co_present_outlined,
                color: AppTheme.midPurple,
                hint: 'كادر تدريسي فعّال',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'نسبة الحضور',
                value: ArFormat.percent(repository.latestAttendanceRate),
                icon: Icons.event_available_outlined,
                color: AppTheme.presentColor,
                hint: attendanceDate == null
                    ? 'لا يوجد تحضير'
                    : 'آخر تحضير: ${ArFormat.date(attendanceDate)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'المتأخرات المالية',
                value: '${repository.totalOutstanding.toStringAsFixed(0)}',
                icon: Icons.receipt_long_outlined,
                color: AppTheme.absentColor,
                hint: '${repository.unpaidInvoicesCount} فاتورة غير مسددة',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    final List<(String, IconData, Widget)> actions = <(String, IconData, Widget)>[
      ('الطلاب', Icons.groups_outlined, const AdminStudentsScreen()),
      ('المدرسون', Icons.co_present_outlined, const AdminTeachersScreen()),
      ('التحضير', Icons.fact_check_outlined, const AdminAttendanceScreen()),
      ('المالية', Icons.payments_outlined, const AdminFinanceScreen()),
    ];
    return SectionCard(
      title: 'إجراءات سريعة',
      icon: Icons.bolt_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map(((String, IconData, Widget) item) {
          return ActionChip(
            avatar: Icon(item.$2, size: 18, color: AppTheme.royalPurple),
            label: Text(item.$1),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => item.$3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _attendanceSection(AppRepository repository, DateTime? attendanceDate) {
    final Map<String, AttendanceSummary> summaries =
        repository.latestSummaryByGrade;
    return SectionCard(
      title: 'الحضور حسب الصف',
      subtitle: attendanceDate == null
          ? 'لا يوجد تحضير مسجل'
          : 'آخر يوم تحضير: ${ArFormat.date(attendanceDate)}',
      icon: Icons.event_available_outlined,
      child: Column(
        children:
            summaries.entries.map((MapEntry<String, AttendanceSummary> entry) {
          final AttendanceSummary summary = entry.value;
          final double rate = summary.rate;
          final int total = summary.total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: total == 0
                          ? 'لا يوجد'
                          : '${ArFormat.percent(rate)} ($total)',
                      color: rate >= 0.9
                          ? AppTheme.presentColor
                          : rate >= 0.75
                              ? AppTheme.lateColor
                              : AppTheme.absentColor,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GradientProgressBar(
                  value: rate,
                  color: AppTheme.royalPurple,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

Widget _financeSection(AppRepository repository) {
    final double ratio = repository.totalBilled == 0
        ? 0
        : repository.totalCollected / repository.totalBilled;
    return SectionCard(
      title: 'الموقف المالي',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InfoRow(
            icon: Icons.request_quote_outlined,
            label: 'إجمالي الفواتير',
            value: '${repository.totalBilled.toStringAsFixed(0)} د.ع',
          ),
          InfoRow(
            icon: Icons.savings_outlined,
            label: 'المبالغ المستلمة',
            value: '${repository.totalCollected.toStringAsFixed(0)} د.ع',
          ),
          InfoRow(
            icon: Icons.warning_amber_outlined,
            label: 'المتأخرات',
            value: '${repository.totalOutstanding.toStringAsFixed(0)} د.ع',
          ),
          const SizedBox(height: 8),
          GradientProgressBar(value: ratio, color: AppTheme.presentColor),
          const SizedBox(height: 6),
          Text(
            'نسبة التحصيل: ${ArFormat.percent(ratio)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.notMarkedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestsSection(BuildContext context, AppRepository repository) {
    final List<SchoolRequest> pending = repository.pendingRequests;
    return SectionCard(
      title: 'الطلبات قيد المراجعة',
      subtitle: '${pending.length} طلباً بحاجة إلى قرار',
      icon: Icons.assignment_outlined,
      trailing: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const RequestsScreen(),
          ),
        ),
        child: const Text('عرض الكل'),
      ),
      child: pending.isEmpty
          ? const Text(
              'لا توجد طلبات قيد المراجعة حالياً.',
              style: TextStyle(fontSize: 13, color: AppTheme.notMarkedColor),
            )
          : Column(
              children: pending.take(3).map((SchoolRequest item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.assignment_outlined,
                        size: 18,
                        color: AppTheme.midPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.fromName} - ${item.type.label}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.notMarkedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: item.status.label,
                        color: AppTheme.lateColor,
                        dense: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

Widget _announcementsSection(
    BuildContext context,
    AppRepository repository,
  ) {
    final List<Announcement> items = repository.announcements.take(3).toList();
    return SectionCard(
      title: 'أحدث الإعلانات',
      icon: Icons.campaign_outlined,
      trailing: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const AnnouncementsScreen(),
          ),
        ),
        child: const Text('عرض الكل'),
      ),
      child: Column(
        children: items.map((Announcement item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Icon(item.category.icon, size: 18, color: AppTheme.midPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.audience} - ${ArFormat.date(item.publishedAt)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.notMarkedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isPinned)
                  const Icon(Icons.push_pin, size: 15, color: AppTheme.gold),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _absentSection(AppRepository repository) {
    final List<Student> students = repository.topAbsentStudents();
    return SectionCard(
      title: 'متابعة الغياب المتكرر',
      subtitle: 'أكثر الطلاب تكراراً للغياب',
      icon: Icons.report_gmailerrorred_outlined,
      child: students.isEmpty
          ? const Text(
              'لا توجد حالات غياب متكرر.',
              style: TextStyle(fontSize: 13, color: AppTheme.notMarkedColor),
            )
          : Column(
              children: students.map((Student student) {
                final AttendanceSummary summary =
                    repository.summaryForStudent(student.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${student.gradeAndClassroom} - '
                              'ولي الأمر: ${ArFormat.maskedPhone(student.guardianPhone)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.notMarkedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: '${summary.absent} غياب',
                        color: AppTheme.absentColor,
                        dense: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}