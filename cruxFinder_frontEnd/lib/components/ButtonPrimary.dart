// lib/components/ButtonPrimary.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../styles/colors.dart';
import '../styles/fonts.dart';

class ButtonPrimary extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ButtonPrimary({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signature.darkest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: AppFonts.regular.xl.copyWith(
            color: AppColors.dark.darkest,
          ),
        ),
      ),
    );
  }
}
