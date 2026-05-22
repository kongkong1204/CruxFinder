// lib/screens/Solution.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';
import '../components/DropDown.dart';
import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import 'AnalysisUpload.dart';

class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key});

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;

  String _selectedWallHeight = '300cm';
  final List<String> _wallHeightItems = [
    '300cm', '350cm', '400cm', '450cm', '500cm',
  ];

  String _selectedWallAngle = '수직';
  final List<String> _wallAngleItems = ['수직'];

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
                      onTap: _showPickerSheet,
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
                      onPressed: _showPickerSheet,
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
                      text: '다음',
                      onPressed: _selectedImage == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnalysisUploadScreen(
                                    initialImage: _selectedImage!,
                                    wallHeight: _selectedWallHeight,
                                    wallAngle: _selectedWallAngle,
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomTabBar(selectedIndex: 2),
    );
  }
}
