// lib/components/alert.dart

import 'package:flutter/material.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class Information_alert {
  static void show(
      BuildContext context, {
        required String description,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 16,
        right: 16,
        child: _AlertWidget(
          description: description,
          iconPath: 'assets/icons/alert',
          backgroundColor: AppColors.signature.lightest,
          descriptionColor: AppColors.dark.darkest,
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class Error_alert {
  static void show(
      BuildContext context, {
        required String description,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 16,
        right: 16,
        child: _AlertWidget(
          description: description,
          iconPath: 'assets/icons/error',
          backgroundColor: AppColors.error.light,
          descriptionColor: AppColors.dark.darkest,
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class _AlertWidget extends StatelessWidget {
  final String description;
  final String iconPath;
  final Color backgroundColor;
  final Color descriptionColor;

  const _AlertWidget({
    Key? key,
    required this.description,
    required this.iconPath,
    required this.backgroundColor,
    required this.descriptionColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // icon
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Image.asset(iconPath, width: 24, height: 24),
            ),

            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(
                      description,
                      style: AppFonts.light.l.copyWith(
                        color: descriptionColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
