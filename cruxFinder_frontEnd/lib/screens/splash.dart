// lib/screens/splash.dart

import 'package:crux_finder/services/api_service.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await ApiService().loadToken();
    final hasToken = await ApiService().hasToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, hasToken ? '/feed' : '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/crux_finder_icon.png',
                width: 100,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              '이제 진짜 시작합니당',
              style: AppFonts.light.m.copyWith(
                color: AppColors.signature.darkest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
