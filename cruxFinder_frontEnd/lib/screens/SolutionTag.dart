// lib/screens/SolutionHold.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../components/ButtonPrimary.dart';
import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import '../models/analysis.dart';

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

// 홀드 데이터 모델 (픽셀 좌표 — Roboflow center x/y/w/h)
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
  final File imageFile;
  final AnalysisResult result;

  const SolutionTagScreen({
    super.key,
    required this.imageFile,
    required this.result,
  });

  @override
  State<SolutionTagScreen> createState() => _SolutionTagScreenState();
}

class _SolutionTagScreenState extends State<SolutionTagScreen> {
  late List<HoldData> _holds;

  @override
  void initState() {
    super.initState();
    // Roboflow 픽셀 좌표 그대로 유지 (FittedBox가 스케일 처리)
    _holds = widget.result.holds.asMap().entries.map((entry) {
      final i = entry.key;
      final h = entry.value;
      return HoldData(id: i, x: h.x, y: h.y, width: h.width, height: h.height);
    }).toList();
  }

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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'solution',
                    style: AppFonts.title.T.copyWith(color: AppColors.dark.darkest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '사용하는 홀드에\n태그를 적용해주세요',
                style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
              ),
            ),
            const SizedBox(height: 16),

            // 이미지 + 홀드 바운딩 박스
            // FittedBox로 이미지 좌표계를 그대로 유지 — BoxFit.cover처럼 크롭하면
            // 홀드 픽셀 좌표와 표시 위치가 어긋나므로 contain 사용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: widget.result.imageWidth,
                      height: widget.result.imageHeight,
                      child: Stack(
                        children: [
                          Image.file(
                            widget.imageFile,
                            width: widget.result.imageWidth,
                            height: widget.result.imageHeight,
                            fit: BoxFit.fill,
                          ),
                          // Positioned로 각 홀드 탭 가능하게 유지
                          ..._holds.map((hold) {
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
                              left: hold.x - hold.width / 2,
                              top: hold.y - hold.height / 2,
                              width: hold.width,
                              height: hold.height,
                              child: GestureDetector(
                                onTap: () => _onHoldTap(hold),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor, width: 2),
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
                  ),
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
                  // TODO: 다음 화면(솔루션 결과) 이동
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomTabBar(selectedIndex: 2),
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
            style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
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
            style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
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
            style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
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
