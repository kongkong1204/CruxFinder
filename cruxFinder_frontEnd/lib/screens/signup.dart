import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:crux_finder/components/button_primary.dart';
import 'package:crux_finder/components/button_secondary.dart';
import 'package:crux_finder/components/text_field.dart';
import 'package:crux_finder/services/api_service.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isEmailVerified = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  String? _devCode; // 개발 모드: 응답으로 받은 인증 코드

  bool _isNicknameAvailable = false;
  bool _isCheckingNickname = false;
  String _lastCheckedNickname = '';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _nicknameController.addListener(_onNicknameChanged);
    _passwordController.addListener(_refresh);
    _passwordConfirmController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  void _onEmailChanged() {
    setState(() {
      _isEmailVerified = false;
      _devCode = null;
    });
  }

  void _onNicknameChanged() {
    setState(() {
      _isNicknameAvailable = false;
      _lastCheckedNickname = '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _isEmailVerified &&
      _isNicknameAvailable &&
      _nicknameController.text.trim() == _lastCheckedNickname &&
      _passwordController.text.length >= 8 &&
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(_passwordController.text) &&
      _passwordController.text == _passwordConfirmController.text;

  // ── 이메일 인증 코드 발송 ──────────────────────────────

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSendingCode = true);
    try {
      final result = await ApiService().sendVerificationCode(email);
      if (!mounted) return;
      setState(() {
        _devCode = result['devCode'] as String?;
        _codeController.clear();
      });
      _showSnack(result['message'] ?? '인증 코드가 발송되었습니다.');
      if (_devCode != null) {
        _showSnack('개발 모드 코드: $_devCode');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(e.response?.data['message'] ?? '발송 실패');
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || code.isEmpty) return;

    setState(() => _isVerifyingCode = true);
    try {
      await ApiService().verifyEmailCode(email, code);
      if (!mounted) return;
      setState(() => _isEmailVerified = true);
      _showSnack('이메일 인증 완료!');
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(e.response?.data['message'] ?? '인증 실패');
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  // ── 닉네임 중복 확인 ──────────────────────────────────

  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isCheckingNickname = true);
    try {
      final available = await ApiService().checkNicknameAvailable(nickname);
      if (!mounted) return;
      setState(() {
        _isNicknameAvailable = available;
        _lastCheckedNickname = nickname;
      });
      _showSnack(available ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.');
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(e.response?.data['message'] ?? '확인 실패');
    } finally {
      if (mounted) setState(() => _isCheckingNickname = false);
    }
  }

  // ── 회원가입 제출 ──────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService().signUp(
        email: _emailController.text.trim(),
        nickname: _nicknameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      _showSnack('회원가입 성공!');
      Navigator.pushReplacementNamed(context, '/signin');
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(e.response?.data['message'] ?? '서버 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final buttonColor = _canSubmit
        ? AppColors.signature.darkest
        : AppColors.signature.lightest;

    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                '회원가입',
                style: AppFonts.title.m.copyWith(color: AppColors.dark.darkest),
              ),
              const SizedBox(height: 32),

              // 이메일 + 인증코드 발송
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: '이메일',
                      placeholder: 'crux@finder.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ButtonSecondary(
                      text: _isSendingCode ? '발송 중...' : '인증코드 발송',
                      onPressed: _isSendingCode ? null : _sendCode,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 인증 코드 입력 + 확인
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: _isEmailVerified ? '인증 코드 ✓' : '인증 코드',
                      placeholder: '6자리 코드',
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      enabled: !_isEmailVerified,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ButtonSecondary(
                      text: _isEmailVerified
                          ? '인증완료'
                          : (_isVerifyingCode ? '확인 중...' : '확인'),
                      onPressed: (_isEmailVerified || _isVerifyingCode) ? null : _verifyCode,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 닉네임 + 중복 확인
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: (_isNicknameAvailable &&
                              _nicknameController.text.trim() == _lastCheckedNickname)
                          ? '닉네임 ✓'
                          : '닉네임',
                      placeholder: '닉네임',
                      controller: _nicknameController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ButtonSecondary(
                      text: _isCheckingNickname ? '확인 중...' : '중복확인',
                      onPressed: _isCheckingNickname ? null : _checkNickname,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: '비밀번호 (8자리 이상 영문 + 숫자)',
                placeholder: '********',
                controller: _passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: '비밀번호 확인',
                placeholder: '********',
                controller: _passwordConfirmController,
                obscureText: true,
              ),

              const SizedBox(height: 40),

              ButtonPrimary(
                text: _isSubmitting ? '처리 중...' : '회원가입',
                backgroundColor: buttonColor,
                textColor: AppColors.light.lightest,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
