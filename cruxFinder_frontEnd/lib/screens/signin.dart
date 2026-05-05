import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:crux_finder/components/button_primary.dart';
import 'package:crux_finder/components/text_field.dart';
import 'package:crux_finder/services/api_service.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
  TextEditingController(text: 'crux@finder.com');
  final TextEditingController _passwordController = TextEditingController();

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
    if (!_canLogin) return;

    try {
      final data = await ApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/feed');
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? '서버 오류가 발생했습니다.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _onTapForgotPassword() {
    debugPrint('비밀번호 찾기 화면 이동');
  }

  void _onTapSignUp() {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '로그인',
                  style: AppFonts.title.m.copyWith(
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
                    style: AppFonts.light.m.copyWith(
                      color: AppColors.signature.darkest,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                ButtonPrimary(
                  text: '로그인',
                  backgroundColor: AppColors.signature.darkest,
                  textColor: AppColors.light.darkest,
                  onPressed: _onTapLogin,
                ),
                const SizedBox(height: 14),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppFonts.light.m.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                      children: [
                        const TextSpan(text: '아직 회원이 아니신가요? '),
                        TextSpan(
                          text: '회원가입',
                          style: AppFonts.light.m.copyWith(
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
      ),
    );
  }
}