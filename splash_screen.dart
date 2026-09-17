import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../data/app_repository.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// الشاشة الترحيبية التي تظهر عند فتح التطبيق.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppConstants.splashDuration, _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) {
      return;
    }
    final bool signedIn = AppRepository.instance.isSignedIn;
    Navigator.of(context).pushReplacementNamed(
      signedIn ? HomeShell.routeName : LoginScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldGradient,
                ),
                child: Image.asset(
                  AppConstants.logoAsset,
                  width: 132,
                  height: 132,
                ),
              ),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppConstants.schoolName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 70,
                height: 3,
                decoration: const BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                AppConstants.englishName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              const Text(
                AppConstants.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}