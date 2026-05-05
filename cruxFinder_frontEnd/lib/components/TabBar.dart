// lib/components/TabBar.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../styles/colors.dart';

// 스크린 경로 - 실제 경로로 교체 필요
import 'package:crux_finder/screens/Home.dart';
import 'package:crux_finder/screens/Feed.dart';
import 'package:crux_finder/screens/Solution.dart';
import 'package:crux_finder/screens/FeedUpload.dart';
import 'package:crux_finder/screens/Profile.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;

  const CustomTabBar({
    super.key,
    required this.selectedIndex,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (selectedIndex == index) return;

    Widget page;

    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const FeedScreen();
        break;
      case 2:
        page = const SolutionScreen();
        break;
      case 3:
        page = const FeedUploadScreen();
        break;
      case 4:
        page = const ProfileScreen();
        break;
      default:
        page = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      'assets/icons/home.png',
      'assets/icons/file.png',
      'assets/icons/icon.png',
      'assets/icons/add.png',
      'assets/icons/profile.png',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.light.lightest,
        border: Border(
          top: BorderSide(
            color: AppColors.signature.darkest,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final bool isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => _handleNavigation(context, index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.signature.darkest
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    items[index],
                    width: 24,
                    height: 24,
                    color: isSelected
                        ? AppColors.light.lightest
                        : AppColors.signature.darkest,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}