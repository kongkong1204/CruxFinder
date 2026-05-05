// lib/screens/Splash.dart

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

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
              'AI와 함께하는 클라이밍',
              style: AppFonts.regular.m.copyWith(
                color: AppColors.signature.darkest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
