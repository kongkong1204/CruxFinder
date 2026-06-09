// lib/screens/SolutionResult.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import '../models/analysis.dart';

// 경로 마킹 한 점 (start 또는 move 공용)
class RouteMark {
  final String label;   // 'S' 또는 '1', '2', ...
  final String limb;    // leftHand / rightHand / leftFoot / rightFoot
  final double x;        // 정규화 좌표 (0~1, 홀드 중심)
  final double y;
  final double width;    // 정규화 바운딩박스
  final double height;
  final bool isStart;    // 시작 자세 여부

  RouteMark({
    required this.label,
    required this.limb,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isStart,
  });

  bool get isHand => limb == 'leftHand' || limb == 'rightHand';
}

class SolutionResultScreen extends StatelessWidget {
  final File imageFile;
  final AnalysisResult result;       // imageWidth/Height 사용
  final Map<String, dynamic> solution; // 백엔드 findPath 결과

  const SolutionResultScreen({
    super.key,
    required this.imageFile,
    required this.result,
    required this.solution,
  });

  // solution.start + solution.moves → RouteMark 리스트로 변환
  List<RouteMark> _buildMarks() {
    final marks = <RouteMark>[];

    // 시작 자세: 4지점 모두 'S'로 표시
    final start = solution['start'] as Map<String, dynamic>?;
    if (start != null) {
      for (final limb in ['leftHand', 'rightHand', 'leftFoot', 'rightFoot']) {
        final p = start[limb] as Map<String, dynamic>?;
        if (p == null) continue;
        marks.add(RouteMark(
          label: 'S',
          limb: limb,
          x: (p['x'] as num).toDouble(),
          y: (p['y'] as num).toDouble(),
          width: (p['width'] as num).toDouble(),
          height: (p['height'] as num).toDouble(),
          isStart: true,
        ));
      }
    }

    // 이동: step 번호로 표시
    final moves = solution['moves'] as List<dynamic>? ?? [];
    for (final m in moves) {
      final mv = m as Map<String, dynamic>;
      marks.add(RouteMark(
        label: '${mv['step']}',
        limb: mv['limb'] as String,
        x: (mv['x'] as num).toDouble(),
        y: (mv['y'] as num).toDouble(),
        width: (mv['width'] as num).toDouble(),
        height: (mv['height'] as num).toDouble(),
        isStart: false,
      ));
    }

    return marks;
  }

  // 손/발 색 구분 (손: 파랑, 발: 주황, 시작: 회색)
  Color _markColor(RouteMark mark) {
    if (mark.isStart) return AppColors.clear.medium;
    return mark.isHand ? AppColors.signature.darkest
        : AppColors.error.lightest;
  }

  @override
  Widget build(BuildContext context) {
    final marks = _buildMarks();
    final imgW = result.imageWidth;
    final imgH = result.imageHeight;

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
                style: AppFonts.title.T.copyWith(color: AppColors.dark.darkest),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '추천 경로입니다',
                style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
              ),
            ),
            const SizedBox(height: 8),

            // 손/발 색상 범례
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _legendDot(AppColors.signature.darkest, '손'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.error.lightest, '발'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.clear.medium, '시작(S)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 이미지 + 경로 마킹 (SolutionTag와 동일한 좌표계 유지 방식)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: imgW,
                      height: imgH,
                      child: Stack(
                        children: [
                          Image.file(
                            imageFile,
                            width: imgW,
                            height: imgH,
                            fit: BoxFit.fill,
                          ),
                          // 각 마킹을 박스로 그림 (겹치면 약간씩 어긋나게 겹쳐짐)
                          ...marks.map((mark) {
                            final color = _markColor(mark);
                            // 정규화 좌표 → 이미지 픽셀 좌표
                            final left = mark.x * imgW - (mark.width * imgW) / 2;
                            final top = mark.y * imgH - (mark.height * imgH) / 2;
                            final w = mark.width * imgW;
                            final h = mark.height * imgH;
                            return Positioned(
                              left: left,
                              top: top,
                              width: w,
                              height: h,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: color, width: 3),
                                  borderRadius: BorderRadius.circular(4),
                                  color: color.withValues(alpha: 0.15),
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      mark.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                      ),
                                    ),
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
          ],
        ),
      ),
      bottomNavigationBar: CustomTabBar(selectedIndex: 2),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppFonts.regular.m.copyWith(color: AppColors.dark.darkest)),
      ],
    );
  }
}