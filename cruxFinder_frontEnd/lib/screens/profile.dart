// lib/screens/Profile.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

import 'ProfileAccount.dart';
import 'ProfileBody.dart';

class UserProfile {
  final String name;
  final String nickname;
  final String email;
  final String height;
  final String weight;
  final String armspan;
  final String inseam;

  const UserProfile({
    required this.name,
    required this.nickname,
    required this.email,
    required this.height,
    required this.weight,
    required this.armspan,
    required this.inseam,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedTabIndex = 4;

  // TODO: 실제 유저 데이터로 교체
  final UserProfile userProfile = const UserProfile(
    name: 'name',
    nickname: 'nickname',
    email: 'cruxfinder@test.com',
    height: '',
    weight: '',
    armspan: '',
    inseam: '',
  );

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
                        userProfile.nickname,
                        style: AppFonts.bold.xs.copyWith(
                          color: AppColors.dark.darkest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userProfile.email,
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
                      nickname: userProfile.nickname,
                      email: userProfile.email,
                      name: userProfile.name,
                    ),
                  ),
                );
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
                      nickname: userProfile.nickname,
                      email: userProfile.email,
                      height: userProfile.height,
                      weight: userProfile.weight,
                      armspan: userProfile.armspan,
                      inseam: userProfile.inseam,
                    ),
                  ),
                );
              },
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