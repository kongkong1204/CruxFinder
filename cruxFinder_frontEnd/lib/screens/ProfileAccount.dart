// lib/screens/ProfileAccount.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../components/TextField.dart';
import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class ProfileAccountScreen extends StatefulWidget {
  final String nickname;
  final String email;

  const ProfileAccountScreen({
    super.key,
    required this.nickname,
    required this.email,
  });

  @override
  State<ProfileAccountScreen> createState() => _ProfileAccountScreenState();
}

class _ProfileAccountScreenState extends State<ProfileAccountScreen> {
  late final TextEditingController _nicknameController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);
  }

  Future<void> _onSave() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty || isLoading) return;

    setState(() => isLoading = true);
    try {
      await ApiService().updateMe(nickname: newNickname);
      if (!mounted) return;
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '저장 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'profile',
                style: AppFonts.title.T.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.signature.darkest,
                        width: 1.5,
                      ),
                    ),
                    child: Image.asset(
                      'assets/icons/profile.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nickname,
                        style: AppFonts.bold.xs.copyWith(
                          color: AppColors.dark.darkest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.email,
                        style: AppFonts.bold.xl.copyWith(
                          color: AppColors.dark.darkest,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: '닉네임',
                      controller: _nicknameController,
                      placeholder: '닉네임 입력',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '비밀번호',
                      style: AppFonts.bold.xs.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ButtonSecondary(
                      text: '비밀번호 변경',
                      onPressed: () {
                        // TODO: 비밀번호 변경 화면 이동
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: isLoading
                  ? const SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ButtonPrimary(
                      text: '저장',
                      onPressed: _onSave,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
