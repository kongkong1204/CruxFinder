// lib/screens/ForgotPassword.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../components/ButtonPrimary.dart';
import '../components/TextField.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

enum _Step { email, code, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().forgotPassword(email);
      if (!mounted) return;
      _email = email;
      setState(() => _step = _Step.code);
      if (res['devCode'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('[개발] 인증코드: ${res['devCode']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증코드가 이메일로 발송됐습니다.')),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '오류가 발생했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().verifyResetCode(_email, code);
      if (!mounted) return;
      setState(() => _step = _Step.newPassword);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '인증 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _passwordConfirmController.text.trim();
    if (password.isEmpty || _isLoading) return;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().resetPassword(_email, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경됐습니다. 다시 로그인해주세요.')),
      );
      Navigator.pushReplacementNamed(context, '/signin');
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '변경 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 24),
              ),
              const SizedBox(height: 32),
              Text(
                '비밀번호 재설정',
                style: AppFonts.title.T.copyWith(color: AppColors.dark.darkest),
              ),
              const SizedBox(height: 8),
              Text(
                _stepDescription,
                style: AppFonts.regular.m.copyWith(color: AppColors.dark.lightest),
              ),
              const SizedBox(height: 36),
              ..._buildFields(),
              const SizedBox(height: 36),
              ButtonPrimary(
                text: _isLoading ? '처리 중...' : _buttonLabel,
                onPressed: _isLoading ? () {} : _onTapNext,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepDescription {
    switch (_step) {
      case _Step.email:
        return '가입한 이메일을 입력해주세요.';
      case _Step.code:
        return '$_email 로 발송된 인증코드를 입력해주세요.';
      case _Step.newPassword:
        return '새 비밀번호를 입력해주세요.';
    }
  }

  String get _buttonLabel {
    switch (_step) {
      case _Step.email:
        return '인증코드 발송';
      case _Step.code:
        return '확인';
      case _Step.newPassword:
        return '비밀번호 변경';
    }
  }

  VoidCallback get _onTapNext {
    switch (_step) {
      case _Step.email:
        return _sendCode;
      case _Step.code:
        return _verifyCode;
      case _Step.newPassword:
        return _resetPassword;
    }
  }

  List<Widget> _buildFields() {
    switch (_step) {
      case _Step.email:
        return [
          CustomTextField(
            label: '이메일',
            placeholder: 'crux@finder.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ];
      case _Step.code:
        return [
          CustomTextField(
            label: '인증코드',
            placeholder: '6자리 코드 입력',
            controller: _codeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendCode,
            child: Text(
              '코드 재발송',
              style: AppFonts.regular.m.copyWith(color: AppColors.signature.darkest),
            ),
          ),
        ];
      case _Step.newPassword:
        return [
          CustomTextField(
            label: '새 비밀번호 (8자리 이상 영문+숫자)',
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
        ];
    }
  }
}
