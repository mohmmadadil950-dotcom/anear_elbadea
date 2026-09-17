import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../data/app_repository.dart';
import '../models/user.dart';
import 'admin/admin_attendance_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_finance_screen.dart';
import 'admin/admin_purchases_screen.dart';
import 'admin/admin_students_screen.dart';
import 'admin/admin_teachers_screen.dart';
import 'announcements_screen.dart';
import 'exams_screen.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'parent/parent_attendance_screen.dart';
import 'parent/parent_dashboard.dart';
import 'parent/parent_marks_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';
import 'student/student_attendance_screen.dart';
import 'student/student_dashboard.dart';
import 'student/student_homework_screen.dart';
import 'student/student_marks_screen.dart';
import 'student/student_timetable_screen.dart';
import 'teacher/mark_attendance_screen.dart';
import 'teacher/teacher_dashboard.dart';
import 'teacher/teacher_homework_screen.dart';
import 'teacher/teacher_marks_screen.dart';
import 'teacher/teacher_schedule_screen.dart';

/// وجهة واحدة في شريط التنقل السفلي.
class HomeDestination {
  const HomeDestination({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// الهيكل الرئيسي للتطبيق بعد تسجيل الدخول: شريط تنقل بحسب الدور.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const String routeName = '/home';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  HomeDestination _destination({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return HomeDestination(
      label: label,
      icon: icon,
      builder: (BuildContext context) => child,
    );
  }

  /// قائمة الوجهات بحسب دور المستخدم الحالي.
  List<HomeDestination> _destinationsFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return <HomeDestination>[
          _destination(
            label: 'الإدارة',
            icon: Icons.dashboard_outlined,
            child: const AdminDashboard(),
          ),
          _destination(
            label: 'الطلاب',
            icon: Icons.groups_outlined,
            child: const AdminStudentsScreen(),
          ),
          _destination(
            label: 'المدرسون',
            icon: Icons.co_present_outlined,
            child: const AdminTeachersScreen(),
          ),
          _destination(
            label: 'الحضور',
            icon: Icons.event_available_outlined,
            child: const AdminAttendanceScreen(),
          ),
          _destination(
            label: 'المالية',
            icon: Icons.receipt_long_outlined,
            child: const AdminFinanceScreen(),
          ),
          _destination(
            label: 'المشتريات',
            icon: Icons.shopping_cart_outlined,
            child: const AdminPurchasesScreen(),
          ),
        ];
      case UserRole.teacher:
        return <HomeDestination>[
          _destination(
            label: 'الرئيسية',
            icon: Icons.dashboard_outlined,
            child: const TeacherDashboard(),
          ),
          _destination(
            label: 'التحضير',
            icon: Icons.fact_check_outlined,
            child: const MarkAttendanceScreen(),
          ),
          _destination(
            label: 'الدرجات',
            icon: Icons.grading_outlined,
            child: const TeacherMarksScreen(),
          ),
          _destination(
            label: 'الواجبات',
            icon: Icons.menu_book_outlined,
            child: const TeacherHomeworkScreen(),
          ),
          _destination(
            label: 'الجدول',
            icon: Icons.calendar_month_outlined,
            child: const TeacherScheduleScreen(),
          ),
        ];
      case UserRole.student:
        return <HomeDestination>[
          _destination(
            label: 'الرئيسية',
            icon: Icons.dashboard_outlined,
            child: const StudentDashboard(),
          ),
          _destination(
            label: 'درجاتي',
            icon: Icons.grading_outlined,
            child: const StudentMarksScreen(),
          ),
          _destination(
            label: 'حضوري',
            icon: Icons.event_available_outlined,
            child: const StudentAttendanceScreen(),
          ),
          _destination(
            label: 'واجباتي',
            icon: Icons.menu_book_outlined,
            child: const StudentHomeworkScreen(),
          ),
          _destination(
            label: 'جدولي',
            icon: Icons.calendar_month_outlined,
            child: const StudentTimetableScreen(),
          ),
        ];
      case UserRole.parent:
        return <HomeDestination>[
          _destination(
            label: 'أبنائي',
            icon: Icons.family_restroom_outlined,
            child: const ParentDashboard(),
          ),
          _destination(
            label: 'الحضور',
            icon: Icons.event_available_outlined,
            child: const ParentAttendanceScreen(),
          ),
          _destination(
            label: 'الدرجات',
            icon: Icons.grading_outlined,
            child: const ParentMarksScreen(),
          ),
          _destination(
            label: 'الرسائل',
            icon: Icons.chat_bubble_outline,
            child: const MessagesScreen(),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppRepository repository = AppRepository.instance;
    final AppUser? user = repository.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('انتهت الجلسة، يُرجى تسجيل الدخول مرة أخرى.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(LoginScreen.routeName),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    final List<HomeDestination> destinations = _destinationsFor(user.role);
    final int index = _index >= destinations.length ? 0 : _index;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      endDrawer: _buildDrawer(user),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              AppConstants.shortName,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${user.role.label} - ${user.fullName}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'الإعلانات',
            onPressed: () => _open(const AnnouncementsScreen()),
            icon: const Icon(Icons.campaign_outlined),
          ),
          ListenableBuilder(
            listenable: repository,
            builder: (BuildContext context, Widget? child) {
              final int unread = repository.unreadNotificationsCount;
              return IconButton(
                tooltip: 'التنبيهات',
                onPressed: () => _open(const NotificationsScreen()),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none),
                ),
              );
            },
          ),
          Builder(
            builder: (BuildContext context) => IconButton(
              tooltip: 'القائمة',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: destinations
            .map(
              (HomeDestination item) => Navigator(
                onGenerateRoute: (RouteSettings settings) =>
                    MaterialPageRoute<void>(
                  builder: item.builder,
                  settings: settings,
                ),
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 66,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: destinations
            .map(
              (HomeDestination item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => screen),
    );
  }

  Widget _buildDrawer(AppUser user) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(gradient: AppTheme.royalGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.gold,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: AppTheme.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.title ?? user.role.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _drawerItem(Icons.person_outline, 'حسابي', const ProfileScreen()),
                  _drawerItem(
                    Icons.campaign_outlined,
                    'الإعلانات',
                    const AnnouncementsScreen(),
                  ),
                  _drawerItem(
                    Icons.assignment_outlined,
                    'الطلبات',
                    const RequestsScreen(),
                  ),
                  _drawerItem(
                    Icons.chat_bubble_outline,
                    'الرسائل',
                    const MessagesScreen(),
                  ),
                  _drawerItem(
                    Icons.event_note_outlined,
                    'جدول الامتحانات',
                    const ExamsScreen(),
                  ),
                  _drawerItem(
                    Icons.notifications_none,
                    'التنبيهات',
                    const NotificationsScreen(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppTheme.absentColor,
                    ),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: AppTheme.absentColor),
                    ),
                    onTap: () {
                      AppRepository.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        LoginScreen.routeName,
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        _open(screen);
      },
    );
  }
}