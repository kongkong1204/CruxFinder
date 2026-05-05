// lib/screens/ProfileBody.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/TextField.dart';
import '../components/ButtonPrimary.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class ProfileBodyScreen extends StatefulWidget {
  final String nickname;
  final String email;
  final String height;
  final String weight;
  final String armspan;
  final String inseam;

  const ProfileBodyScreen({
    super.key,
    required this.nickname,
    required this.email,
    required this.height,
    required this.weight,
    required this.armspan,
    required this.inseam,
  });

  @override
  State<ProfileBodyScreen> createState() => _ProfileBodyScreenState();
}

class _ProfileBodyScreenState extends State<ProfileBodyScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _armspanController;
  late final TextEditingController _inseamController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.height);
    _weightController = TextEditingController(text: widget.weight);
    _armspanController = TextEditingController(text: widget.armspan);
    _inseamController = TextEditingController(text: widget.inseam);
  }

  Future<void> _onSave() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    // TODO: 저장 API 연동
    if (!mounted) return;
    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _armspanController.dispose();
    _inseamController.dispose();
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
                      label: '키',
                      controller: _heightController,
                      placeholder: 'text',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: '체중',
                      controller: _weightController,
                      placeholder: 'text',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: '암리치',
                      controller: _armspanController,
                      placeholder: 'text',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: '인심',
                      controller: _inseamController,
                      placeholder: 'text',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 저장 버튼
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