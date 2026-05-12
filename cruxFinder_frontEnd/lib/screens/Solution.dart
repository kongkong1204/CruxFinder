// lib/screens/Solution.dart

import 'package:flutter/material.dart';

import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';
import '../components/DropDown.dart';
import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key});

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  bool _hasMainImage = false;
  final List<bool> _additionalImages = [];

  // 벽 높이 (50cm 단위, 300~500cm)
  String _selectedWallHeight = '300cm';
  final List<String> _wallHeightItems = [
    '300cm', '350cm', '400cm', '450cm', '500cm',
  ];

  // 벽 경사각
  String _selectedWallAngle = '수직';
  final List<String> _wallAngleItems = [
    '슬랩', '수직', '오버행', '심한 오버행',
  ];

  void _onSelectMainImage() {
    setState(() {
      _hasMainImage = !_hasMainImage;
      // TODO: 실제 이미지 피커 연동
    });
  }

  void _onAddAdditionalImage() {
    if (_additionalImages.length >= 5) return;
    setState(() {
      _additionalImages.add(true);
      // TODO: 실제 이미지 피커 연동
    });
  }

  void _onRemoveAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'solution',
                style: AppFonts.title.T.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 정면 사진 섹션
                    Text(
                      '최적의 솔루션을 찾기위해\n문제 정면 사진을 선택해 주세요',
                      style: AppFonts.bold.xl.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 정면 사진 프리뷰
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.light.darkest,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _hasMainImage
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: AppColors.light.light,
                          alignment: Alignment.center,
                          child: Text(
                            '정면 사진',
                            style: AppFonts.regular.m.copyWith(
                              color: AppColors.dark.darkest,
                            ),
                          ),
                        ),
                      )
                          : Center(
                        child: Image.asset(
                          'assets/icons/photo.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ButtonSecondary(
                      text: '사진 선택',
                      onPressed: _onSelectMainImage,
                    ),

                    const SizedBox(height: 28),

                    // 벽 정보 섹션
                    Text(
                      '벽 정보를 입력해 주세요',
                      style: AppFonts.bold.xl.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropDown(
                            title: '벽 높이',
                            items: _wallHeightItems,
                            initialValue: _selectedWallHeight,
                            onChanged: (value) {
                              setState(() {
                                _selectedWallHeight = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropDown(
                            title: '경사각',
                            items: _wallAngleItems,
                            initialValue: _selectedWallAngle,
                            onChanged: (value) {
                              setState(() {
                                _selectedWallAngle = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 추가 사진 섹션
                    Text(
                      '최적의 솔루션을 찾기위해\n문제의 사진을 추가해 주세요',
                      style: AppFonts.bold.xl.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 추가된 사진 목록
                    if (_additionalImages.isNotEmpty) ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _additionalImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.light.light,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.light.darkest,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '추가 사진 ${index + 1}',
                                    style: AppFonts.regular.m.copyWith(
                                      color: AppColors.dark.darkest,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _onRemoveAdditionalImage(index),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.dark.darkest.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: AppColors.light.lightest,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    if (_additionalImages.length < 5)
                      ButtonSecondary(
                        text: '사진 추가',
                        onPressed: _onAddAdditionalImage,
                      ),

                    if (_additionalImages.length >= 5)
                      Center(
                        child: Text(
                          '추가 사진은 최대 5장까지 가능해요',
                          style: AppFonts.regular.s.copyWith(
                            color: AppColors.dark.lightest,
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),

                    ButtonPrimary(
                      text: '다음',
                      onPressed: () {
                        debugPrint('mainImage: $_hasMainImage');
                        debugPrint('wallHeight: $_selectedWallHeight');
                        debugPrint('wallAngle: $_selectedWallAngle');
                        debugPrint('additionalImages: ${_additionalImages.length}장');
                        // TODO: 다음 화면 이동
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomTabBar(
        selectedIndex: 2,
      ),
    );
  }
}