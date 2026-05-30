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
  final _memoController = TextEditingController();
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

  bool get _canSubmit =>
      _memoController.text.trim().isNotEmpty && !_isSubmitting;

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
    _memoController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _memoController
      ..removeListener(_refresh)
      ..dispose();
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
    if (!_canSubmit) return;
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

  Future<void> _showDateTimePicker() async {
    DateTime tempDate = _selectedDateTime;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
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
                      setState(() => _selectedDateTime = tempDate);
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
                onDateTimeChanged: (value) => tempDate = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.light.lightest,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'edit',
                      style: AppFonts.bold.xl.copyWith(color: AppColors.dark.darkest),
                    ),
                    const SizedBox(height: 28),

                    _EditImageSection(
                      existingImageUrl: _existingImageUrl,
                      newImageFile: _newImageFile,
                      isRemoved: _removeImage,
                      onPickImage: _showPickerSheet,
                      onRemoveImage: _hasImage ? _onRemoveImage : null,
                    ),

                    const SizedBox(height: 18),

                    Text(
                      '문제에 대해 자유롭게 메모하세요',
                      style: AppFonts.bold.xs.copyWith(color: AppColors.dark.darkest),
                    ),
                    const SizedBox(height: 12),

                    _MemoInputBox(controller: _memoController),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DateChip(text: _formatDate(_selectedDateTime), onTap: _showDateTimePicker),
                        const SizedBox(width: 8),
                        _DateChip(text: _formatTime(_selectedDateTime), onTap: _showDateTimePicker),
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
                            onChanged: (value) => setState(() => _selectedVGrade = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropDown(
                            title: '나의 체감 난이도',
                            items: _myDifficultyItems,
                            initialValue: _selectedMyDifficulty,
                            onChanged: (value) => setState(() => _selectedMyDifficulty = value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    ButtonPrimary(
                      text: _isSubmitting ? '처리 중...' : '수정 완료',
                      onPressed: _canSubmit ? _submitEdit : null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            CustomTabBar(selectedIndex: 3),
          ],
        ),
      ),
    );
  }
}

class _EditImageSection extends StatelessWidget {
  final String? existingImageUrl;
  final File? newImageFile;
  final bool isRemoved;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const _EditImageSection({
    required this.existingImageUrl,
    required this.newImageFile,
    required this.isRemoved,
    required this.onPickImage,
    this.onRemoveImage,
  });

  bool get _hasImage =>
      !isRemoved && (newImageFile != null || existingImageUrl != null);

  Widget _buildPreview() {
    if (newImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          newImageFile!,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
        ),
      );
    }
    if (existingImageUrl != null && !isRemoved) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          existingImageUrl!,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (ctx, err, stack) => SizedBox(
            height: 160,
            child: Center(
              child: Icon(Icons.broken_image, color: AppColors.light.darkest, size: 40),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: Center(child: Image.asset('assets/icons/photo.png')),
    );
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
          _buildPreview(),
          const SizedBox(height: 12),
          ButtonSecondary(
            text: _hasImage ? '다른 사진 선택' : '사진 선택하기',
            onPressed: onPickImage,
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

class _MemoInputBox extends StatelessWidget {
  final TextEditingController controller;

  const _MemoInputBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.signature.darkest, width: 2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: CupertinoTextField(
        controller: controller,
        maxLines: null,
        expands: true,
        padding: EdgeInsets.zero,
        decoration: const BoxDecoration(color: Colors.transparent),
        placeholder: 'text',
        placeholderStyle: AppFonts.regular.xl.copyWith(
          color: AppColors.dark.darkest.withValues(alpha: 0.55),
        ),
        style: AppFonts.regular.xl.copyWith(color: AppColors.dark.darkest),
        cursorColor: AppColors.signature.darkest,
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _DateChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppFonts.regular.m.copyWith(color: AppColors.dark.darkest),
        ),
      ),
    );
  }
}
