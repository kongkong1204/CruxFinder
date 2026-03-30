// lib/screens/splash.dart

import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget
{
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      
      body: Center
      (
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

            const SizedBox(height: 20,),

            Text(
              '이제 진짜 시작합니당',
              style: AppFonts.light.m.copyWith(
                color: AppColors.signature.darkest
              ),
            )
          ],
        ),
      )
    );
  }
}