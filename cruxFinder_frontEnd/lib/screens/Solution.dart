// lib/screens/Solution.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';
import '../components/DropDown.dart';
import '../components/TabBar.dart';
import '../components/ActionSheetOverlay.dart';
import '../services/api_service.dart';
import '../models/analysis.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import 'SolutionTag.dart';

class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key});

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showSheet = false;

  String _selectedWallHeight = '300cm';
  final List<String> _wallHeightItems = [
    '300cm', '350cm', '400cm', '450cm', '500cm',
  ];

  String _selectedWallAngle = 'vertical';
  final List<String> _wallAngleItems = ['slab', 'vertical'];

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() => _selectedImage = File(picked.path));
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
      final data = await ApiService().analyzeImage(
        _selectedImage!.path,
        wallHeight: _selectedWallHeight,
        wallTags: _selectedWallAngle,
      );

      if (!mounted) return;

      final holds = (data['holds'] as List)
          .map((h) => Hold.fromJson(h as Map<String, dynamic>))
          .toList();

      final result = AnalysisResult(
        routeId: data['routeId'] as int,  // 추가
        imageUrl: data['imageUrl'] as String,
        imageWidth: (data['imageWidth'] as num).toDouble(),
        imageHeight: (data['imageHeight'] as num).toDouble(),
        holds: holds,
        isDev: data['dev'] == true,
      );

      if (result.isDev) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[개발] Roboflow 미연동 — 더미 홀드 표시 중')),
        );
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SolutionTagScreen(
            imageFile: _selectedImage!,
            result: result,
            wallHeight: _selectedWallHeight,
            wallTags: _selectedWallAngle,
          )
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      debugPrint('DioException: ${e.response?.statusCode}');
      debugPrint('DioException data: ${e.response?.data}');
      debugPrint('DioException message: ${e.message}');
      final message = e.response?.data['message'] ?? '분석 실패';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.lightest,
      body: Stack(
        children: [
          SafeArea(
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
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '최적의 솔루션을 찾기위해\n문제 정면 사진을 선택해 주세요',
                          style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
                        ),
                        const SizedBox(height: 12),

                        // 사진 프리뷰
                        GestureDetector(
                          onTap: () => setState(() => _showSheet = true),
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.light.darkest,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
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
                        ),
                        const SizedBox(height: 12),

                        ButtonSecondary(
                          text: _selectedImage == null ? '사진 선택' : '다른 사진 선택',
                          onPressed: () => setState(() => _showSheet = true),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          '벽 정보를 입력해 주세요',
                          style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
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
                                  setState(() => _selectedWallHeight = value);
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
                                  setState(() => _selectedWallAngle = value);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        ButtonPrimary(
                          text: _isAnalyzing ? '분석 중...' : '다음',
                          onPressed: _selectedImage == null || _isAnalyzing
                              ? null
                              : _analyze,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ActionSheetOverlay(
            visible: _showSheet,
            actions: [
              ActionSheetItem(
                label: '갤러리에서 선택',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ActionSheetItem(
                label: '카메라로 촬영',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
            onCancel: () => setState(() => _showSheet = false),
          ),
        ],
      ),
      bottomNavigationBar: CustomTabBar(selectedIndex: 2),
    );
  }
}
