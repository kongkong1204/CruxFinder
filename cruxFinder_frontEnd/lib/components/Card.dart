// lib/components/Card.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../styles/colors.dart';
import '../styles/fonts.dart';

class FeedCard extends StatelessWidget {

  final String memo;
  final String dateText;
  final String absoluteGrade;
  final String relativeGrade;
  final String? imagePath;
  final VoidCallback? onMoreTap;

  const FeedCard({
    super.key,
    required this.memo,
    required this.dateText,
    required this.absoluteGrade,
    required this.relativeGrade,
    this.imagePath,
    this.onMoreTap,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.signature.darkest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildImageSection(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            color: AppColors.light.lightest,

            child: hasImage
                ? Image.asset(
              imagePath!,
              fit: BoxFit.cover,
            )

                : Center(
              child: Image.asset(
                'assets/icons/photo.png',
                width: 36,
                height: 36,
              ),
            ),
          ),

          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: onMoreTap,
              child: Image.asset(
                'assets/icons/dot.png',
                width: 24,
                height: 24,
              ),
            ),
          ),  //피드 수정 및 삭제에 사용하는 기능, 작업 진행상황에 따라 기능 구현하지 않을수도
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo,
                    style: AppFonts.regular.m.copyWith(
                      color: AppColors.dark.darkest
                    )
                  ),
                  const Spacer(),
                  Text(
                    dateText,
                      style: AppFonts.regular.xs.copyWith(
                          color: AppColors.dark.darkest
                      )
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  absoluteGrade,
                    style: AppFonts.title.T.copyWith(
                        color: AppColors.dark.darkest
                    )
                ),
                Text(
                  relativeGrade,
                    style: AppFonts.title.T.copyWith(
                        color: AppColors.dark.darkest
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}