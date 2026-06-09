// lib/components/ActionSheetOverlay.dart
//
// 화면 하단에 액션 버튼들을 오버레이로 띄우는 공통 위젯.
// 바텀시트(showModalBottomSheet) 대신 Stack 위에 얹어 사용한다.
//
// 사용 예:
// Stack(children: [
//   ...본문...,
//   ActionSheetOverlay(
//     visible: _showSheet,
//     actions: [
//       ActionSheetItem(label: '갤러리에서 선택', onTap: _pickFromGallery),
//       ActionSheetItem(label: '카메라로 촬영', onTap: _pickFromCamera),
//     ],
//     onCancel: () => setState(() => _showSheet = false),
//   ),
// ])

import 'package:flutter/material.dart';

import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';
import '../styles/colors.dart';

class ActionSheetItem {
  final String label;
  final VoidCallback onTap;
  // 위험 동작(예: 삭제) 강조용. true면 색을 다르게 줄 수 있음(색은 추후 조절).
  final bool isDestructive;

  const ActionSheetItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

class ActionSheetOverlay extends StatelessWidget {
  final bool visible;
  final List<ActionSheetItem> actions;
  final VoidCallback onCancel;
  final String cancelLabel;

  const ActionSheetOverlay({
    super.key,
    required this.visible,
    required this.actions,
    required this.onCancel,
    this.cancelLabel = '취소',
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Stack(
        children: [
          // 바깥 어두운 배경 — 탭하면 닫힘
          GestureDetector(
            onTap: onCancel,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          // 하단 버튼 묶음
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 액션 버튼들 (네 디자인 시스템 버튼 사용)
                    ...actions.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child:
                      ButtonPrimary(
                        text: a.label,
                        onPressed: () {
                          onCancel();   // 먼저 오버레이 닫고
                          a.onTap();    // 액션 실행
                        },
                      ),
                    )),
                    // 취소 버튼
                    ButtonSecondary(
                      text: cancelLabel,
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}