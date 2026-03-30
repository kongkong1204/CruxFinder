// lib/components/tab_bar.dart

import 'package:flutter/material.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

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
      color: AppColors.light.lightest,
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final bool isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.signature.darkest : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    items[index],
                    width: 24,
                    height: 24,
                    color: isSelected ? AppColors.light.lightest : AppColors.signature.darkest,
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

//nav기능 추가된 tabbar
//스크린 구현 완료후 교체 예정
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:crux_finder/styles/colors.dart';
//
//스크린 경로 추가
//
// class CustomTabBar extends StatelessWidget {
//   final int selectedIndex;
//
//   const CustomTabBar({
//     super.key,
//     required this.selectedIndex,
//   });
//
//   void _handleNavigation(BuildContext context, int index) {
//     if (selectedIndex == index) return;
//
//     Widget page;
//
//     switch (index) {
//       case 0:
//         page = const HomePage();
//         break;
//       case 1:
//         page = const FilePage();
//         break;
//       case 2:
//         page = const IconPage();
//         break;
//       case 3:
//         page = const FeedUploadPage();
//         break;
//       case 4:
//         page = const ProfilePage();
//         break;
//       default:
//         page = const HomePage();
//     }
//
//     Navigator.pushReplacement(
//       context,
//       CupertinoPageRoute(builder: (_) => page),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       'assets/icons/home.png',
//       'assets/icons/file.png',
//       'assets/icons/icon.png',
//       'assets/icons/add.png',
//       'assets/icons/profile.png',
//     ];
//
//     return Container(
//       color: AppColors.light.lightest,
//       padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 18),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(items.length, (index) {
//               final bool isSelected = selectedIndex == index;
//
//               return GestureDetector(
//                 onTap: () => _handleNavigation(context, index),
//                 behavior: HitTestBehavior.opaque,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 180),
//                   curve: Curves.easeInOut,
//                   width: 52,
//                   height: 52,
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? AppColors.signature.darkest
//                         : Colors.transparent,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Image.asset(
//                     items[index],
//                     width: 24,
//                     height: 24,
//                     color: isSelected
//                         ? AppColors.light.lightest
//                         : AppColors.signature.darkest,
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }