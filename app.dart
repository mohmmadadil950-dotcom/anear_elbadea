import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'data/app_repository.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

class AnwarAlBadeaApp extends StatefulWidget {
  const AnwarAlBadeaApp({super.key});

  @override
  State<AnwarAlBadeaApp> createState() => _AnwarAlBadeaAppState();
}

class _AnwarAlBadeaAppState extends State<AnwarAlBadeaApp> {
  @override
  void initState() {
    super.initState();
    AppRepository.instance.seedDemoData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.shortName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: SplashScreen.routeName,
      routes: <String, WidgetBuilder>{
        SplashScreen.routeName: (BuildContext context) => const SplashScreen(),
        LoginScreen.routeName: (BuildContext context) => const LoginScreen(),
        HomeShell.routeName: (BuildContext context) => const HomeShell(),
        AdminDashboard.routeName: (BuildContext context) =>
            const AdminDashboard(),
      },
    );
  }
}
