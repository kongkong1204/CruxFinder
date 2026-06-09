// lib/screens/SolutionDevTest.dart
//
// 개발용 테스트 화면.
// 사진은 에셋 고정, 데이터셋(wall/user/holds)은 아래 _datasetJson에 직접 박아서
// 백엔드 /analysis/solve-test 를 호출해 경로를 받아 마킹을 그린다.
// 신체 데이터는 버튼으로 골라 바로 바꿔 테스트할 수 있다.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../styles/colors.dart';
import '../styles/fonts.dart';

// ── 여기에 테스트 데이터를 박는다 ────────────────────────────
// 이미지 크기(wall.imageWidth/Height)와 홀드 좌표는 고정,
// user(신체)만 아래 _userPresets에서 골라 덮어쓴다.

const String _imageUrl = 'http://localhost:3000/uploads/4643.jpg'; // 테스트 이미지 URL

// 벽 + 홀드 (신체 제외)
const Map<String, dynamic> _wall = {
  'heightCm': 350,
  'imageWidth': 3213,
  'imageHeight': 5712,
  'angle': 'vertical',
};

const List<Map<String, dynamic>> _holds = [
  {
    "id": 21,
    "x": 0.5543106131341425,
    "y": 0.2708333333333333,
    "width": 0.10208527855586678,
    "height": 0.045168067226890755,
    "isStart": false,
    "isTop": true,
    "tags": {
      "type": "jug",
      "size": "l"
    }
  },
  {
    "id": 25,
    "x": 0.8496732026143791,
    "y": 0.7724964985994398,
    "width": 0.0778089013383131,
    "height": 0.04884453781512605,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "l"
    }
  },
  {
    "id": 28,
    "x": 0.7278244631185807,
    "y": 0.3898809523809524,
    "width": 0.08496732026143791,
    "height": 0.04411764705882353,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 32,
    "x": 0.6413009648303766,
    "y": 0.44336484593837533,
    "width": 0.08061002178649238,
    "height": 0.04569327731092437,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 35,
    "x": 0.6386554621848739,
    "y": 0.4876575630252101,
    "width": 0.07282913165266107,
    "height": 0.044292717086834736,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 50,
    "x": 0.580765639589169,
    "y": 0.6769957983193278,
    "width": 0.05291005291005291,
    "height": 0.03326330532212885,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "sloper",
      "size": "m"
    }
  },
  {
    "id": 55,
    "x": 0.8678804855275444,
    "y": 0.9746148459383753,
    "width": 0.047619047619047616,
    "height": 0.0350140056022409,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "sloper",
      "size": "m"
    }
  },
  {
    "id": 60,
    "x": 0.9145658263305322,
    "y": 0.6222864145658263,
    "width": 0.07314036725801432,
    "height": 0.03553921568627451,
    "isStart": true,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 62,
    "x": 0.8233737939620293,
    "y": 0.6255252100840336,
    "width": 0.0582010582010582,
    "height": 0.029411764705882353,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 73,
    "x": 0.6812947401182695,
    "y": 0.8689600840336135,
    "width": 0.037970743853096796,
    "height": 0.017682072829131652,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "s"
    }
  }
];

// 바꿔가며 테스트할 신체 프리셋
const List<Map<String, dynamic>> _userPresets = [
  {'label': '키175', 'heightCm': 175, 'armReachCm': 175, 'inseamCm': 83, 'weightKg': 68},
  {'label': '키170', 'heightCm': 170, 'armReachCm': 170, 'inseamCm': 75, 'weightKg': 60},
  {'label': '키165', 'heightCm': 165, 'armReachCm': 160, 'inseamCm': 68, 'weightKg': 58},
  {'label': '키160', 'heightCm': 160, 'armReachCm': 158, 'inseamCm': 65, 'weightKg': 52},
];

// 백엔드 주소 (에뮬레이터면 10.0.2.2, 실기기면 PC IP로 변경)
const String _baseUrl = 'http://localhost:3000';
// ──────────────────────────────────────────────────────────

class RouteMark {
  final String label;
  final String limb;
  final double x;
  final double y;
  final double width;
  final double height;
  final bool isStart;

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

class SolutionDevTestScreen extends StatefulWidget {
  const SolutionDevTestScreen({super.key});

  @override
  State<SolutionDevTestScreen> createState() => _SolutionDevTestScreenState();
}

class _SolutionDevTestScreenState extends State<SolutionDevTestScreen> {
  int _selectedPreset = 0;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _solution;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  double get _imgW => (_wall['imageWidth'] as num).toDouble();
  double get _imgH => (_wall['imageHeight'] as num).toDouble();

  Future<void> _runTest() async {
    setState(() {
      _loading = true;
      _error = null;
      _solution = null;
    });

    try {
      final user = Map<String, dynamic>.from(_userPresets[_selectedPreset])
        ..remove('label');

      final body = {
        'wall': _wall,
        'user': user,
        'holds': _holds,
      };

      final res = await _dio.post('/analysis/solve-test', data: body);
      final solution = res.data['solution'] as Map<String, dynamic>?;

      if (solution == null || solution['ok'] != true) {
        setState(() => _error = solution?['message'] ?? '경로 탐색 실패');
        return;
      }
      setState(() => _solution = solution);
    } on DioException catch (e) {
      setState(() => _error = 'DioError: ${e.response?.statusCode} ${e.message}');
    } catch (e) {
      setState(() => _error = '오류: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<RouteMark> _buildMarks() {
    final s = _solution;
    if (s == null) return [];
    final marks = <RouteMark>[];

    final start = s['start'] as Map<String, dynamic>?;
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

    final moves = s['moves'] as List<dynamic>? ?? [];
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

  Color _markColor(RouteMark mark) {
    if (mark.isStart) return AppColors.clear.medium;
    return mark.isHand ? AppColors.signature.darkest
        : AppColors.error.lightest;
  }

  @override
  Widget build(BuildContext context) {
    final marks = _buildMarks();

    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      appBar: AppBar(title: const Text('경로 테스트 (개발용)')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 신체 프리셋 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: List.generate(_userPresets.length, (i) {
                  final sel = i == _selectedPreset;
                  return ChoiceChip(
                    label: Text(_userPresets[i]['label'] as String),
                    selected: sel,
                    onSelected: (_) => setState(() => _selectedPreset = i),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            // 실행 버튼 + 범례
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _loading ? null : _runTest,
                    child: Text(_loading ? '실행 중...' : '경로 탐색'),
                  ),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.signature.darkest, '손'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.error.lightest, '발'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.clear.medium, '시작(S)'),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            if (_solution != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '이동 ${(_solution!['moves'] as List).length}회 · 총비용 ${(_solution!['totalCost'] as num).toStringAsFixed(0)}',
                  style: AppFonts.regular.m.copyWith(color: AppColors.dark.darkest),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _imgW,
                      height: _imgH,
                      child: Stack(
                        children: [
                          Image.network(
                            _imageUrl,
                            width: _imgW,
                            height: _imgH,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stack) => Container(
                              width: _imgW,
                              height: _imgH,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Text('이미지 로드 실패\n(백엔드 서버 확인)', textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          ...marks.map((mark) {
                            final color = _markColor(mark);
                            final left = mark.x * _imgW - (mark.width * _imgW) / 2;
                            final top = mark.y * _imgH - (mark.height * _imgH) / 2;
                            final w = mark.width * _imgW;
                            final h = mark.height * _imgH;
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
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppFonts.regular.m.copyWith(color: AppColors.dark.darkest)),
      ],
    );
  }
}