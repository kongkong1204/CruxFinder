// lib/screens/FeedUpload.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../components/ButtonPrimary.dart';
import '../components/ButtonSecondary.dart';
import '../components/DropDown.dart';
import '../components/TabBar.dart';
import '../components/TextField.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class FeedUploadScreen extends StatefulWidget {
  const FeedUploadScreen({super.key});

  @override
  State<FeedUploadScreen> createState() => _FeedUploadScreenState();
}

class _FeedUploadScreenState extends State<FeedUploadScreen> {
  final TextEditingController _memoController = TextEditingController();

  DateTime _selectedDateTime = DateTime(2025, 4, 1, 9, 41);
  File? _selectedImage;
  bool _isSubmitting = false;

  String _selectedVGrade = 'VB';
  String _selectedMyDifficulty = '1';

  final List<String> _vGradeItems = [
    'VB', 'V0', 'V1', 'V2', 'V3', 'V4',
    'V5', 'V6', 'V7', 'V8', 'V9', 'V10+',
  ];

  final List<String> _myDifficultyItems = [
    '1', '2', '3', '4', '5',
    '6', '7', '8', '9', '10',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submitUpload() async {
    if (_memoController.text.trim().isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService().createFeed(
        memo: _memoController.text.trim(),
        climbedAt: _selectedDateTime,
        vGrade: _selectedVGrade,
        myDifficulty: _selectedMyDifficulty,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '업로드 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _showCupertinoDateTimePicker() async {
    DateTime tempDate = _selectedDateTime;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: AppColors.light.lightest,
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('취소'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('확인'),
                      onPressed: () {
                        setState(() {
                          _selectedDateTime = tempDate;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _selectedDateTime,
                  use24hFormat: false,
                  onDateTimeChanged: (value) {
                    tempDate = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
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
                'upload',
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
                    _UploadImageSection(
                      selectedImage: _selectedImage,
                      onTapChangePhoto: _pickImage,
                    ),
                    const SizedBox(height: 18),

                    Text(
                      '문제에 대해 자유롭게 메모하세요',
                      style: AppFonts.bold.xs.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _memoController,
                      placeholder: 'text',
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DateChip(
                          text: _formatDate(_selectedDateTime),
                          onTap: _showCupertinoDateTimePicker,
                        ),
                        const SizedBox(width: 8),
                        _DateChip(
                          text: _formatTime(_selectedDateTime),
                          onTap: _showCupertinoDateTimePicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropDown(
                            title: 'V등급 난이도',
                            items: _vGradeItems,
                            initialValue: _selectedVGrade,
                            onChanged: (value) {
                              setState(() {
                                _selectedVGrade = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropDown(
                            title: '나의 체감 난이도',
                            items: _myDifficultyItems,
                            initialValue: _selectedMyDifficulty,
                            onChanged: (value) {
                              setState(() {
                                _selectedMyDifficulty = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    ButtonPrimary(
                      text: _isSubmitting ? '업로드 중...' : '업로드',
                      onPressed: _submitUpload,
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
        selectedIndex: 3,
      ),
    );
  }
}

class _UploadImageSection extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onTapChangePhoto;

  const _UploadImageSection({
    required this.selectedImage,
    required this.onTapChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.light.darkest, width: 2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            alignment: Alignment.center,
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      selectedImage!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset('assets/icons/photo.png'),
          ),
          const SizedBox(height: 12),
          ButtonSecondary(
            text: selectedImage != null ? '사진 변경하기' : '사진 선택하기',
            onPressed: onTapChangePhoto,
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _DateChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.light.medium,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppFonts.regular.m.copyWith(
            color: AppColors.dark.darkest,
          ),
        ),
      ),
    );
  }
}