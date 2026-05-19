// lib/screens/Signup.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../components/ButtonPrimary.dart';
import '../components/TextField.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isEmailVerified = false;
  bool _codeSent = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isLoading = false;

  bool get _canSubmit =>
      _nameController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _isEmailVerified &&
      _passwordController.text.length >= 8 &&
      _passwordController.text == _passwordConfirmController.text;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
    _passwordConfirmController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _isSendingCode) return;
    setState(() => _isSendingCode = true);
    try {
      final res = await ApiService().sendVerificationCode(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isEmailVerified = false;
        _codeController.clear();
      });
      // 개발 모드: devCode 자동 표시
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
      final message = e.response?.data['message'] ?? '코드 발송 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _isVerifyingCode) return;
    setState(() => _isVerifyingCode = true);
    try {
      await ApiService().verifyEmailCode(_emailController.text.trim(), code);
      if (!mounted) return;
      setState(() => _isEmailVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증 완료!')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '인증 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().signUp(
        email: _emailController.text.trim(),
        nickname: _nameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 완료! 로그인해주세요.')),
      );
      Navigator.pushReplacementNamed(context, '/signin');
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '회원가입 실패';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '회원가입',
                style: AppFonts.title.T.copyWith(color: AppColors.dark.darkest),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                label: '닉네임',
                placeholder: '닉네임',
                controller: _nameController,
              ),
              const SizedBox(height: 20),

              // 이메일 + 인증코드 발송 버튼
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
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSendingCode ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.signature.darkest,
                        foregroundColor: AppColors.light.lightest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSendingCode ? '발송중' : (_codeSent ? '재발송' : '인증'),
                        style: AppFonts.regular.m,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 인증코드 입력 (코드 발송 후 표시)
              if (_codeSent) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: '인증코드',
                        placeholder: '코드 입력',
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isEmailVerified || _isVerifyingCode ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEmailVerified
                              ? AppColors.light.darkest
                              : AppColors.signature.darkest,
                          foregroundColor: AppColors.light.lightest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isEmailVerified ? '완료' : (_isVerifyingCode ? '확인중' : '확인'),
                          style: AppFonts.regular.m,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              CustomTextField(
                label: '비밀번호 (8자리 이상 영문+숫자)',
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
                text: _isLoading ? '처리 중...' : '회원가입',
                onPressed: _canSubmit ? _submit : () {},
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
