// lib/styles/fonts.dart

import 'package:flutter/material.dart';

// 300 Light
// 400 Regular
// 600 SemiBold
// 700 Bold


class AppFonts {
  static final bold = Bold();
  static final regular = Light();
  static final title = Title();
}

// Bold
class Bold {
  final xl = const TextStyle(
    fontFamily: 'inter',
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
  );

  final l = const TextStyle(
    fontFamily: 'inter',
    fontSize: 20,
    fontWeight: FontWeight.w700, // Bold
  );

  final m = const TextStyle(
    fontFamily: 'inter',
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
  );

  final s = const TextStyle(
    fontFamily: 'inter',
    fontSize: 15,
    fontWeight: FontWeight.w600, // semiBold
  );

  final xs = const TextStyle(
    fontFamily: 'inter',
    fontSize: 14,
    fontWeight: FontWeight.w600, // semiBold
  );
}

// Light
class Light {
  final xl = const TextStyle(
    fontFamily: 'inter',
    fontSize: 24,
    fontWeight: FontWeight.w400, // Regular
  );

  final l = const TextStyle(
    fontFamily: 'inter',
    fontSize: 20,
    fontWeight: FontWeight.w400, // Regular
  );

  final m = const TextStyle(
    fontFamily: 'inter',
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
  );

  final s = const TextStyle(
    fontFamily: 'inter',
    fontSize: 15,
    fontWeight: FontWeight.w300, // light
  );

  final xs = const TextStyle(
    fontFamily: 'inter',
    fontSize: 14,
    fontWeight: FontWeight.w300, // light
  );
}

// title
class Title {
  final T = const TextStyle(
    fontFamily: 'inter',
    fontSize: 40,
    fontWeight: FontWeight.w700, // SemiBold
  );
}
