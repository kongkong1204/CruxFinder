// lib/screens/FeedEdit.dart

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class FeedEditScreen extends StatefulWidget {
  final int feedId;
  final String initialMemo;
  final DateTime initialDateTime;
  final String initialVGrade;
  final String initialMyDifficulty;
  final String? initialImageUrl;

  const FeedEditScreen({
    super.key,
    required this.feedId,
    required this.initialMemo,
    required this.initialDateTime,
    required this.initialVGrade,
    required this.initialMyDifficulty,
    this.initialImageUrl,
  });

  @override
  State<FeedEditScreen> createState() => _FeedEditScreenState();
}

class _FeedEditScreenState extends State<FeedEditScreen> {
  final TextEditingController _memoController = TextEditingController();
  final _picker = ImagePicker();

  late DateTime _selectedDateTime;
  late String _selectedVGrade;
  late String _selectedMyDifficulty;

  String? _existingImageUrl;
  File? _newImageFile;
  bool _removeImage = false;
  bool _isSubmitting = false;

  final List<String> _vGradeItems = [
    'VB', 'V0', 'V1', 'V2', 'V3', 'V4',
    'V5', 'V6', 'V7', 'V8', 'V9', 'V10+',
  ];

  final List<String> _myDifficultyItems = [
    '1', '2', '3', '4', '5',
    '6', '7', '8', '9', '10',
  ];

  bool get _hasImage =>
      !_removeImage && (_newImageFile != null || _existingImageUrl != null);

  @override
  void initState() {
    super.initState();
    _memoController.text = widget.initialMemo;
    _selectedDateTime = widget.initialDateTime;
    _selectedVGrade = widget.initialVGrade;
    _selectedMyDifficulty = widget.initialMyDifficulty;
    _existingImageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _newImageFile = File(picked.path);
      _removeImage = false;
    });
  }

  void _onRemoveImage() {
    setState(() {
      _newImageFile = null;
      _removeImage = true;
    });
  }

  Future<void> _submitEdit() async {
    if (_memoController.text.trim().isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService().updateFeed(
        feedId: widget.feedId,
        memo: _memoController.text.trim(),
        climbedAt: _selectedDateTime,
        vGrade: _selectedVGrade,
        myDifficulty: _selectedMyDifficulty,
        imagePath: _newImageFile?.path,
        removeImage: _removeImage && _newImageFile == null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data['message'] ?? '수정 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 날짜 선택 (년/월/일)
  Future<void> _showDatePicker() async {
    DateTime temp = _selectedDateTime;
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
                        setState(() => _selectedDateTime = temp);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDateTime,
                  onDateTimeChanged: (value) {
                    temp = DateTime(
                      value.year, value.month, value.day,
                      _selectedDateTime.hour, _selectedDateTime.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 시간 선택 (시/분)
  Future<void> _showTimePicker() async {
    DateTime temp = _selectedDateTime;
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
                        setState(() => _selectedDateTime = temp);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _selectedDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (value) {
                    temp = DateTime(
                      _selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day,
                      value.hour, value.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 년. 월. 일
  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}. ${two(dt.month)}. ${two(dt.day)}';
  }

  // 시:분 (24시간제)
  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
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
                'edit',
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
                    _EditImageSection(
                      existingImageUrl: _existingImageUrl,
                      newImageFile: _newImageFile,
                      isRemoved: _removeImage,
                      onTapChangePhoto: _showPickerSheet,
                      onRemoveImage: _hasImage ? _onRemoveImage : null,
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
                          onTap: _showDatePicker,
                        ),
                        const SizedBox(width: 8),
                        _DateChip(
                          text: _formatTime(_selectedDateTime),
                          onTap: _showTimePicker,
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
                      text: _isSubmitting ? '처리 중...' : '수정 완료',
                      onPressed: _submitEdit,
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

class _EditImageSection extends StatelessWidget {
  final String? existingImageUrl;
  final File? newImageFile;
  final bool isRemoved;
  final VoidCallback onTapChangePhoto;
  final VoidCallback? onRemoveImage;

  const _EditImageSection({
    required this.existingImageUrl,
    required this.newImageFile,
    required this.isRemoved,
    required this.onTapChangePhoto,
    this.onRemoveImage,
  });

  bool get _hasImage =>
      !isRemoved && (newImageFile != null || existingImageUrl != null);

  Widget _buildPreview() {
    if (newImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          newImageFile!,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }
    if (existingImageUrl != null && !isRemoved) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          existingImageUrl!,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (ctx, err, stack) => SizedBox(
            height: 120,
            child: Center(
              child: Icon(Icons.broken_image, color: AppColors.light.darkest, size: 40),
            ),
          ),
        ),
      );
    }
    return Image.asset('assets/icons/photo.png');
  }

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
            child: _buildPreview(),
          ),
          const SizedBox(height: 12),
          ButtonSecondary(
            text: _hasImage ? '사진 변경하기' : '사진 선택하기',
            onPressed: onTapChangePhoto,
          ),
          if (onRemoveImage != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRemoveImage,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '이미지 제거',
                  style: AppFonts.regular.m.copyWith(
                    color: AppColors.error.darkest,
                  ),
                ),
              ),
            ),
          ],
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