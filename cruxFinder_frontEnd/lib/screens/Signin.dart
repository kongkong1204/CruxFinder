// lib/screens/SignIn.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:dio/dio.dart';

import '../components/ButtonPrimary.dart';
import '../components/TextField.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  bool get _canLogin =>
      _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onTapLogin() async {
    if (!_canLogin || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/feed');
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '로그인 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTapForgotPassword() {}

  void _onTapSignUp() {
    Navigator.pushNamed(context, '/signup');
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
                '로그인',
                style: AppFonts.title.T.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),
              const SizedBox(height: 28),

              CustomTextField(
                controller: _emailController,
                placeholder: '이메일',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _passwordController,
                placeholder: '비밀번호',
                obscureText: true,
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _onTapForgotPassword,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  '비밀번호가 기억이 안나시나요?',
                  style: AppFonts.regular.m.copyWith(
                    color: AppColors.signature.darkest,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              ButtonPrimary(
                text: _isLoading ? '로그인 중...' : '로그인',
                onPressed: _onTapLogin,
              ),
              const SizedBox(height: 14),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppFonts.regular.m.copyWith(
                      color: AppColors.dark.darkest,
                    ),
                    children: [
                      const TextSpan(text: '아직 회원이 아니신가요? '),
                      TextSpan(
                        text: '회원가입',
                        style: AppFonts.regular.m.copyWith(
                          color: AppColors.signature.darkest,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _onTapSignUp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}