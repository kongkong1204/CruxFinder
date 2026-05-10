// lib/screens/SolutionHold.dart

import 'package:flutter/material.dart';

import '../components/ButtonPrimary.dart';
import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

// 홀드 타입
enum HoldType { jug, pinch, crimp, sloper, pocket }

extension HoldTypeLabel on HoldType {
  String get label {
    switch (this) {
      case HoldType.jug: return '저그';
      case HoldType.pinch: return '핀치';
      case HoldType.crimp: return '크림프';
      case HoldType.sloper: return '슬로퍼';
      case HoldType.pocket: return '포켓';
    }
  }
}

// 홀드 크기
enum HoldSize { small, medium, large }

extension HoldSizeLabel on HoldSize {
  String get label {
    switch (this) {
      case HoldSize.small: return '소';
      case HoldSize.medium: return '중';
      case HoldSize.large: return '대';
    }
  }
}

// 홀드 데이터 모델
class HoldData {
  final int id;
  final double x;
  final double y;
  final double width;
  final double height;
  bool isSelected;
  HoldType? type;
  HoldSize? size;
  bool isStart;
  bool isTop;

  HoldData({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isSelected = false,
    this.type,
    this.size,
    this.isStart = false,
    this.isTop = false,
  });
}

class SolutionTagScreen extends StatefulWidget {
  const SolutionTagScreen({super.key});

  @override
  State<SolutionTagScreen> createState() => _SolutionTagScreenState();
}

class _SolutionTagScreenState extends State<SolutionTagScreen> {

  // TODO: Roboflow API 응답으로 교체
  final List<HoldData> _holds = [
    HoldData(id: 0, x: 0.2, y: 0.3, width: 0.08, height: 0.08),
    HoldData(id: 1, x: 0.5, y: 0.2, width: 0.07, height: 0.07),
    HoldData(id: 2, x: 0.7, y: 0.5, width: 0.09, height: 0.09),
    HoldData(id: 3, x: 0.3, y: 0.6, width: 0.08, height: 0.08),
    HoldData(id: 4, x: 0.6, y: 0.75, width: 0.07, height: 0.07),
  ];

  void _onHoldTap(HoldData hold) {
    setState(() {
      hold.isSelected = !hold.isSelected;
    });

    if (hold.isSelected) {
      _showTagBottomSheet(hold);
    }
  }

  void _showTagBottomSheet(HoldData hold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagBottomSheet(
        hold: hold,
        onSave: (type, size, isStart, isTop) {
          setState(() {
            hold.type = type;
            hold.size = size;
            hold.isStart = isStart;
            hold.isTop = isTop;
          });
        },
      ),
    );
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '사용하는 홀드에\n태그를 적용해주세요',
                style: AppFonts.bold.xl.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 이미지 + 홀드 바운딩 박스
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.light.light,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.light.darkest,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // TODO: 실제 이미지로 교체
                            Center(
                              child: Image.asset(
                                'assets/icons/photo.png',
                                width: 48,
                                height: 48,
                              ),
                            ),

                            // 홀드 바운딩 박스들
                            ..._holds.map((hold) {
                              final left = hold.x * constraints.maxWidth - (hold.width * constraints.maxWidth / 2);
                              final top = hold.y * constraints.maxHeight - (hold.height * constraints.maxHeight / 2);
                              final w = hold.width * constraints.maxWidth;
                              final h = hold.height * constraints.maxHeight;

                              // 시작/끝 홀드에 따라 색상 구분
                              final Color borderColor = hold.isStart
                                  ? AppColors.clear.darkest
                                  : hold.isTop
                                  ? AppColors.error.darkest
                                  : hold.isSelected
                                  ? AppColors.signature.darkest
                                  : AppColors.light.darkest;

                              final Color fillColor = hold.isStart
                                  ? AppColors.clear.darkest.withValues(alpha: 0.2)
                                  : hold.isTop
                                  ? AppColors.error.darkest.withValues(alpha: 0.2)
                                  : hold.isSelected
                                  ? AppColors.signature.darkest.withValues(alpha: 0.2)
                                  : Colors.transparent;

                              return Positioned(
                                left: left,
                                top: top,
                                width: w,
                                height: h,
                                child: GestureDetector(
                                  onTap: () => _onHoldTap(hold),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: borderColor,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: fillColor,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ButtonPrimary(
                text: '다음',
                onPressed: () {
                  final selected = _holds.where((h) => h.isSelected).toList();
                  debugPrint('선택된 홀드: ${selected.length}개');
                  // TODO: 다음 화면 이동
                },
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

class _TagBottomSheet extends StatefulWidget {
  final HoldData hold;
  final Function(HoldType? type, HoldSize? size, bool isStart, bool isTop) onSave;

  const _TagBottomSheet({
    required this.hold,
    required this.onSave,
  });

  @override
  State<_TagBottomSheet> createState() => _TagBottomSheetState();
}

class _TagBottomSheetState extends State<_TagBottomSheet> {
  HoldType? _selectedType;
  HoldSize? _selectedSize;
  bool _isStart = false;
  bool _isTop = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.hold.type;
    _selectedSize = widget.hold.size;
    _isStart = widget.hold.isStart;
    _isTop = widget.hold.isTop;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.light.lightest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들바
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.light.darkest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 홀드 타입
          Text(
            '홀드 타입',
            style: AppFonts.bold.xl.copyWith(
              color: AppColors.dark.darkest,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HoldType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = isSelected ? null : type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.signature.darkest
                        : AppColors.light.lightest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.signature.darkest,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: AppFonts.regular.m.copyWith(
                      color: isSelected
                          ? AppColors.light.lightest
                          : AppColors.dark.darkest,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 홀드 크기
          Text(
            '홀드 크기',
            style: AppFonts.bold.xl.copyWith(
              color: AppColors.dark.darkest,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HoldSize.values.map((size) {
              final isSelected = _selectedSize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = isSelected ? null : size;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.signature.darkest
                        : AppColors.light.lightest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.signature.darkest,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    size.label,
                    style: AppFonts.regular.m.copyWith(
                      color: isSelected
                          ? AppColors.light.lightest
                          : AppColors.dark.darkest,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 시작홀드 / 끝홀드
          Text(
            '홀드 역할',
            style: AppFonts.bold.xl.copyWith(
              color: AppColors.dark.darkest,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // 시작홀드
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isStart = !_isStart;
                    if (_isStart) _isTop = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isStart
                        ? AppColors.clear.darkest
                        : AppColors.light.lightest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.clear.darkest,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '시작홀드',
                    style: AppFonts.regular.m.copyWith(
                      color: _isStart
                          ? AppColors.light.lightest
                          : AppColors.dark.darkest,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 끝홀드
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isTop = !_isTop;
                    if (_isTop) _isStart = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isTop
                        ? AppColors.error.darkest
                        : AppColors.light.lightest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.darkest,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '끝홀드',
                    style: AppFonts.regular.m.copyWith(
                      color: _isTop
                          ? AppColors.light.lightest
                          : AppColors.dark.darkest,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          ButtonPrimary(
            text: '저장',
            onPressed: () {
              widget.onSave(_selectedType, _selectedSize, _isStart, _isTop);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}