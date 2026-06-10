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

const String _imageUrl = 'http://localhost:3000/uploads/4630.jpg'; // 테스트 이미지 URL

// 벽 + 홀드 (신체 제외)
const Map<String, dynamic> _wall = {
  'heightCm': 350,
  'imageWidth': 3213,
  'imageHeight': 5712,
  'angle': 'vertical',
};

const List<Map<String, dynamic>> _holds = [
  {
    "id": 0,
    "x": 0.27606598194833487,
    "y": 0.7651435574229691,
    "width": 0.1686896981014628,
    "height": 0.0898109243697479,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "sloper",
      "size": "l"
    }
  },
  {
    "id": 7,
    "x": 0.5239651416122004,
    "y": 0.8231792717086834,
    "width": 0.16588857765328355,
    "height": 0.05217086834733894,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "sloper",
      "size": "l"
    }
  },
  {
    "id": 9,
    "x": 0.4584500466853408,
    "y": 0.32204131652661067,
    "width": 0.14254590725178962,
    "height": 0.05304621848739496,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "l"
    }
  },
  {
    "id": 16,
    "x": 0.29551820728291317,
    "y": 0.6061799719887955,
    "width": 0.11858076563958916,
    "height": 0.0467436974789916,
    "isStart": true,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 19,
    "x": 0.39822595704948643,
    "y": 0.42436974789915966,
    "width": 0.1223155929038282,
    "height": 0.04131652661064426,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "l"
    }
  },
  {
    "id": 25,
    "x": 0.3952692187986306,
    "y": 0.8607317927170869,
    "width": 0.06535947712418301,
    "height": 0.02468487394957983,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 27,
    "x": 0.5132275132275133,
    "y": 0.7321428571428571,
    "width": 0.05913476501711796,
    "height": 0.03221288515406162,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 28,
    "x": 0.637410519763461,
    "y": 0.553046218487395,
    "width": 0.06598194833488952,
    "height": 0.025560224089635854,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 33,
    "x": 0.4095860566448802,
    "y": 0.46279761904761907,
    "width": 0.06100217864923747,
    "height": 0.028186274509803922,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 34,
    "x": 0.20868347338935575,
    "y": 0.8920693277310925,
    "width": 0.05259881730469966,
    "height": 0.0313375350140056,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 35,
    "x": 0.46747587924058515,
    "y": 0.36659663865546216,
    "width": 0.04730781201369437,
    "height": 0.028711484593837534,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 37,
    "x": 0.5753190164954871,
    "y": 0.6383053221288515,
    "width": 0.0575785869903517,
    "height": 0.0350140056022409,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 38,
    "x": 0.42172424525365704,
    "y": 0.5525210084033614,
    "width": 0.049797696856520385,
    "height": 0.028011204481792718,
    "isStart": false,
    "isTop": false,
    "tags": {
      "type": "jug",
      "size": "m"
    }
  },
  {
    "id": 90,
    "x": 0.4880174291938998,
    "y": 0.2184873949579832,
    "width": 0.07905384375972611,
    "height": 0.03676470588235294,
    "isStart": false,
    "isTop": true,
    "tags": {
      "type": "jug",
      "size": "m"
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