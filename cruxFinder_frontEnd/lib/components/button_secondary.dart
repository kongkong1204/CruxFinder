// lib/components/button_secondary.dart

import 'package:flutter/material.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class ButtonSecondary extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const ButtonSecondary({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.signature.darkest,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: AppFonts.light.xl.copyWith(
            color: AppColors.dark.darkest,
          ),
        ),
      ),
    );
  }
}
