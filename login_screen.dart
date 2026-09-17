import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/ar_format.dart';
import '../data/app_repository.dart';
import '../models/user.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_section_card.dart';
import 'home_shell.dart';

/// شاشة الدخول: رقم الهاتف ثم رمز التحقق (OTP).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppRepository _repository = AppRepository.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  int _attemptsLeft = AppConstants.otpMaxAttempts;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  String? _error;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = AppConstants.otpResendCooldown.inSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown = _cooldown - 1);
      if (_cooldown <= 0) {
        timer.cancel();
      }
    });
  }

  void _sendOtp() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String phone = _phoneController.text.trim();
    final AppUser? user = _repository.userByPhone(phone);
    if (user == null) {
      setState(() {
        _error = 'الرقم غير مسجل في المجموعة. '
            'استخدم أحد الحسابات التجريبية أدناه للتجربة.';
      });
      return;
    }
    _repository.requestOtp(phone);
    setState(() {
      _otpSent = true;
      _error = null;
      _attemptsLeft = AppConstants.otpMaxAttempts;
      _otpController.clear();
    });
    _startCooldown();
    _showSnack(
      'تم إرسال رمز التحقق إلى ${ArFormat.maskedPhone(phone)} '
      '(الرمز التجريبي: ${AppConstants.demoOtpCode})',
    );
  }

  void _verify() {
    final String code = _otpController.text.trim();
    if (code.length != AppConstants.otpLength) {
      setState(() => _error = 'الرمز يتكون من 6 أرقام.');
      return;
    }
    final String phone = _phoneController.text.trim();
    if (_repository.verifyOtp(phone, code)) {
      final AppUser? user = _repository.userByPhone(phone);
      if (user == null) {
        setState(() => _error = 'تعذّر العثور على الحساب.');
        return;
      }
      _repository.signIn(user);
      Navigator.of(context).pushReplacementNamed(HomeShell.routeName);
      return;
    }

    final int left = _attemptsLeft - 1;
    setState(() {
      _attemptsLeft = left;
      _error = left > 0
          ? 'رمز التحقق غير صحيح، تبقى لديك $left محاولات.'
          : 'تم استنفاد المحاولات، يُرجى إعادة إرسال الرمز.';
      if (left <= 0) {
        _otpSent = false;
      }
    });
  }

  void _useDemoAccount(AppUser user) {
    _phoneController.text = user.phone;
    _repository.requestOtp(user.phone);
    setState(() {
      _otpSent = true;
      _error = null;
      _attemptsLeft = AppConstants.otpMaxAttempts;
      _otpController.text = AppConstants.demoOtpCode;
    });
    _startCooldown();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: <Widget>[
                    Image.asset(
                      AppConstants.logoAsset,
                      width: 110,
                      height: 110,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      AppConstants.shortName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تسجيل الدخول برقم الهاتف',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    _buildLoginCard(),
                    const SizedBox(height: 18),
                    _buildDemoAccounts(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return SectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_otpSent,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                hintText: '07XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_iphone),
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                final String digits = (value ?? '').trim();
                if (digits.isEmpty) {
                  return 'يُرجى إدخال رقم الهاتف';
                }
                if (digits.length != 11 || !digits.startsWith('07')) {
                  return 'رقم عراقي غير صحيح (11 رقماً يبدأ بـ 07)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            if (_otpSent) _buildOtpFields(),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.absentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.absentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppTheme.absentColor,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _otpSent ? _verify : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _otpSent ? 'تأكيد الدخول' : 'إرسال رمز التحقق',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_otpSent)
              TextButton(
                onPressed: () => setState(() {
                  _otpSent = false;
                  _error = null;
                }),
                child: const Text('تغيير رقم الهاتف'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConstants.otpLength),
          ],
          decoration: const InputDecoration(
            labelText: 'رمز التحقق',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          onFieldSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'الرمز التجريبي: ${AppConstants.demoOtpCode} - '
                'المحاولات المتبقية: $_attemptsLeft',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.notMarkedColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _cooldown > 0 ? null : _sendOtp,
              child: Text(
                _cooldown > 0
                    ? 'إعادة الإرسال بعد $_cooldown ث'
                    : 'إعادة الإرسال',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'حسابات تجريبية (اضغط للدخول السريع):',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _repository.demoAccounts.map((AppUser user) {
            return InkWell(
              onTap: () => _useDemoAccount(user),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    PersonAvatar(
                      name: user.fullName,
                      size: 30,
                      color: AppTheme.gold,
                      icon: user.role.icon,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${user.role.label} - ${user.fullName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}