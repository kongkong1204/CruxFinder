// lib/screens/profile.dart

import 'package:flutter/material.dart';

import '../components/TabBar.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

import 'ProfileAccount.dart';
import 'ProfileBody.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedTabIndex = 4;

  bool isLoading = true;
  String nickname = '';
  String email = '';
  double? height;
  double? weight;
  double? armReach;
  double? inseam;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService().getMe();
      if (!mounted) return;
      setState(() {
        nickname = data['nickname'] ?? '';
        email = data['email'] ?? '';
        height = data['height'] != null ? (data['height'] as num).toDouble() : null;
        weight = data['weight'] != null ? (data['weight'] as num).toDouble() : null;
        armReach = data['armReach'] != null ? (data['armReach'] as num).toDouble() : null;
        inseam = data['inseam'] != null ? (data['inseam'] as num).toDouble() : null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService().clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                              nickname,
                              style: AppFonts.bold.xs.copyWith(
                                color: AppColors.dark.darkest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: AppFonts.bold.xl.copyWith(
                                color: AppColors.dark.darkest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _ProfileMenuItem(
                    label: '계정 정보 수정',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileAccountScreen(
                            nickname: nickname,
                            email: email,
                          ),
                        ),
                      ).then((_) => _loadUser());
                    },
                  ),
                  Divider(color: AppColors.signature.darkest, thickness: 0.5, height: 0),
                  _ProfileMenuItem(
                    label: '신체 정보 수정',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileBodyScreen(
                            nickname: nickname,
                            email: email,
                            height: _fmt(height),
                            weight: _fmt(weight),
                            armReach: _fmt(armReach),
                            inseam: _fmt(inseam),
                          ),
                        ),
                      ).then((_) => _loadUser());
                    },
                  ),
                  Divider(color: AppColors.signature.darkest, thickness: 0.5, height: 0),
                  _ProfileMenuItem(
                    label: '로그아웃',
                    onTap: _logout,
                  ),
                  Divider(color: AppColors.signature.darkest, thickness: 0.5, height: 0),
                ],
              ),
      ),
      bottomNavigationBar: CustomTabBar(
        selectedIndex: selectedTabIndex,
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.regular.l.copyWith(
                color: AppColors.dark.darkest,
              ),
            ),
            Image.asset('assets/icons/arrow_right.png'),
          ],
        ),
      ),
    );
  }
}
