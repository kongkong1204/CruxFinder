// lib/screens/Solution.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class SolutionScreen extends StatelessWidget {
  const SolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
          child: Center(
            child: Text(
              '미구현',

            ),
          )
      ),
      bottomNavigationBar: CustomTabBar(
        selectedIndex: 2,
      ),
    );
  }
}