// lib/screens/AnalysisUpload.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';

class Hold {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  const Hold({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });

  factory Hold.fromJson(Map<String, dynamic> json) => Hold(
        id: json['id'].toString(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
      );
}

class AnalysisResult {
  final String imageUrl;
  final double imageWidth;
  final double imageHeight;
  final List<Hold> holds;
  final bool isDev;

  const AnalysisResult({
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.holds,
    required this.isDev,
  });
}

class AnalysisUploadScreen extends StatefulWidget {
  const AnalysisUploadScreen({super.key});

  @override
  State<AnalysisUploadScreen> createState() => _AnalysisUploadScreenState();
}

class _AnalysisUploadScreenState extends State<AnalysisUploadScreen> {
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isAnalyzing = false;
  AnalysisResult? _result;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
    });
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    if (_selectedImage == null || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    try {
      final data = await ApiService().analyzeImage(_selectedImage!.path);
      if (!mounted) return;
      final holds = (data['holds'] as List)
          .map((h) => Hold.fromJson(h as Map<String, dynamic>))
          .toList();
      setState(() {
        _result = AnalysisResult(
          imageUrl: data['imageUrl'] as String,
          imageWidth: (data['imageWidth'] as num).toDouble(),
          imageHeight: (data['imageHeight'] as num).toDouble(),
          holds: holds,
          isDev: data['dev'] == true,
        );
      });
      if (_result!.isDev) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[개발] Roboflow 미연동 — 더미 홀드 표시 중')),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '분석 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
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
                    '이미지 분석',
                    style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _selectedImage == null
                  ? _buildPlaceholder()
                  : _buildImagePreview(),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_selectedImage != null && _result == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ButtonPrimary(
                        text: _isAnalyzing ? '분석 중...' : '홀드 분석 시작',
                        onPressed: _analyze,
                      ),
                    ),
                  ButtonSecondary(
                    text: _selectedImage == null ? '사진 선택' : '다른 사진 선택',
                    onPressed: _showPickerSheet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 80, color: AppColors.light.darkest),
          const SizedBox(height: 16),
          Text(
            '클라이밍 벽 사진을 선택해주세요',
            style: AppFonts.regular.l.copyWith(color: AppColors.dark.lightest),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_result != null) {
      return _buildResultOverlay();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_selectedImage!, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final result = _result!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.clear.darkest, size: 18),
              const SizedBox(width: 6),
              Text(
                '홀드 ${result.holds.length}개 감지됨',
                style: AppFonts.bold.m.copyWith(color: AppColors.dark.darkest),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: result.imageWidth,
                  height: result.imageHeight,
                  child: Stack(
                    children: [
                      Image.file(
                        _selectedImage!,
                        width: result.imageWidth,
                        height: result.imageHeight,
                        fit: BoxFit.fill,
                      ),
                      CustomPaint(
                        painter: _HoldOverlayPainter(holds: result.holds),
                        child: SizedBox(
                          width: result.imageWidth,
                          height: result.imageHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HoldOverlayPainter extends CustomPainter {
  final List<Hold> holds;

  const _HoldOverlayPainter({required this.holds});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFF4AD66D).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = const Color(0xFF4AD66D).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (final hold in holds) {
      final rect = Rect.fromCenter(
        center: Offset(hold.x, hold.y),
        width: hold.width,
        height: hold.height,
      );
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, boxPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HoldOverlayPainter old) => old.holds != holds;
}
