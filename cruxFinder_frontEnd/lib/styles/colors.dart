// lib/styles/colors.dart

import 'package:flutter/material.dart';

class AppColors
{
  static Signature signature = Signature();

  static Light light = Light();

  static Dark dark = Dark();

  static Error error = Error();

  static Clear clear = Clear();
}

class Signature
{
  final Color lightest = Color(0xFFE2EAFC);
  final Color light = Color(0xFFD7E3FC);
  final Color medium = Color(0xFFCCDBFD);
  final Color dark = Color(0xFFC1D3FE);
  final Color darkest = Color(0xFFABC4FF);
}

class Light
{
  final Color lightest = Color(0xFFFFFFFF);
  final Color light = Color(0xFFF8F9FE);
  final Color medium = Color(0xFFE8E9F1);
  final Color dark = Color(0xFFD4D6DD);
  final Color darkest = Color(0xFFC5C6CC);
}

class Dark
{
  final Color lightest = Color(0xFF8F9098);
  final Color light = Color(0xFF71727A);
  final Color medium = Color(0xFF494A50);
  final Color dark = Color(0xFF2F3036);
  final Color darkest = Color(0xFF1F2024);
}

class Error
{
  final Color lightest = Color(0xFFF1A7A9);
  final Color light = Color(0xFFEC8385);
  final Color medium = Color(0xFFE66063);
  final Color dark = Color(0xFFE35053);
  final Color darkest = Color(0xFFDD2C2F);
}

class Clear
{
  final Color lightest = Color(0xFFB7EFC5);
  final Color light = Color(0xFF92E6A7);
  final Color medium = Color(0xFF6EDE8A);
  final Color dark = Color(0xFF4AD66D);
  final Color darkest = Color(0xFF2DC653);
}