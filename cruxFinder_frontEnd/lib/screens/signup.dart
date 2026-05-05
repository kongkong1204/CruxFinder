// lib/screens/SignUp.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/ButtonPrimary.dart';
import '../components/TextField.dart';
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
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool get _canSubmit =>
      _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
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

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _submit() {

    if (!_canSubmit) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint('회원가입 요청');
    debugPrint(name);
    debugPrint(email);
    debugPrint(password);

    // TODO
    // 회원가입 API 연결
  }

  @override
  Widget build(BuildContext context) {

    final buttonColor = _canSubmit
        ? AppColors.signature.darkest
        : AppColors.signature.lightest;

    return Scaffold(
      backgroundColor: AppColors.light.lightest,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 48),

              Text(
                '회원가입',
                style: AppFonts.title.T.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),

              const SizedBox(height: 32),

              CustomTextField(
                label: '이름',
                placeholder: '이름',
                controller: _nameController,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: '이메일',
                placeholder: 'crux@finder.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: '비밀번호(8자리 이상 영문 + 숫자)',
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

              const Spacer(),

              ButtonPrimary(
                text: '회원가입',
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