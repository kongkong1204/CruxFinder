import 'package:flutter/material.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

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
        color: AppColors.light.lightest,
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
                'assets/icons/search.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16,
      ),
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
                    style: AppFonts.light.m.copyWith(
                      color: AppColors.dark.darkest
                    )
                  ),
                  const Spacer(),
                  Text(
                    dateText,
                      style: AppFonts.light.xs.copyWith(
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
                    style: AppFonts.title.m.copyWith(
                        color: AppColors.dark.darkest
                    )
                ),
                Text(
                  relativeGrade,
                    style: AppFonts.title.m.copyWith(
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