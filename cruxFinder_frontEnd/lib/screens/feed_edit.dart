// lib/screens/feed_edit.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:crux_finder/components/button_primary.dart';
import 'package:crux_finder/components/drop_down.dart';
import 'package:crux_finder/components/tab_bar.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class FeedEditPage extends StatefulWidget {
  final int feedId;
  final String initialMemo;
  final DateTime initialDateTime;
  final String initialVGrade;
  final String initialMyDifficulty;
  final String? initialImageUrl;

  const FeedEditPage({
    super.key,
    required this.feedId,
    required this.initialMemo,
    required this.initialDateTime,
    required this.initialVGrade,
    required this.initialMyDifficulty,
    this.initialImageUrl,
  });

  @override
  State<FeedEditPage> createState() => _FeedEditPageState();
}

class _FeedEditPageState extends State<FeedEditPage> {
  final TextEditingController _memoController = TextEditingController();

  late DateTime _selectedDateTime;
  late String _selectedVGrade;
  late String _selectedMyDifficulty;

  int _selectedTabIndex = 3;
  bool _isSubmitting = false;

  String? _existingImageUrl;
  bool _removeExistingImage = false;
  bool _hasImage = false;

  final List<String> _vGradeItems = [
    'VB',
    'V0',
    'V1',
    'V2',
    'V3',
    'V4',
    'V5',
    'V6',
    'V7',
    'V8',
    'V9',
    'V10+',
  ];

  final List<String> _myDifficultyItems = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];

  bool get _canSubmit {
    return _memoController.text.trim().isNotEmpty &&
        _selectedVGrade != 'text' &&
        _selectedMyDifficulty != 'text';
  }

  @override
  void initState() {
    super.initState();

    _memoController.text = widget.initialMemo;
    _selectedDateTime = widget.initialDateTime;
    _selectedVGrade = widget.initialVGrade;
    _selectedMyDifficulty = widget.initialMyDifficulty;
    _existingImageUrl = widget.initialImageUrl;
    _hasImage = widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty;

    _memoController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _showCupertinoDateTimePicker() async {
    DateTime tempDate = _selectedDateTime;

    await showCupertinoModalPopup<void>(
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

  void _onTapChangePhoto() {
    setState(() {
      if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        _removeExistingImage = !_removeExistingImage;
        _hasImage = !_removeExistingImage;
      } else {
        _hasImage = !_hasImage;
      }
    });
  }

  Future<void> _submitEdit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final requestBody = {
        'feedId': widget.feedId,
        'memo': _memoController.text.trim(),
        'climbedAt': _selectedDateTime.toIso8601String(),
        'vGrade': _selectedVGrade,
        'myDifficulty': _selectedMyDifficulty,
        'keepExistingImage': _existingImageUrl != null && !_removeExistingImage,
        'removeExistingImage': _removeExistingImage,
        'hasImage': _hasImage,
      };

      debugPrint('UPDATE FEED');
      debugPrint(requestBody.toString());

      // TODO:
      // await feedRepository.updateFeed(
      //   feedId: widget.feedId,
      //   requestBody: requestBody,
      // );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('피드가 수정되었어요.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정 중 오류가 발생했어요: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
    final buttonColor = _canSubmit
        ? AppColors.signature.darkest
        : AppColors.signature.darkest.withValues(alpha: 0.45);

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
                      style: AppFonts.bold.h1.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _EditImageSection(
                      hasImage: _hasImage,
                      isRemoved: _removeExistingImage,
                      onTapChangePhoto: _onTapChangePhoto,
                    ),

                    const SizedBox(height: 18),

                    Text(
                      '문제에 대해 자유롭게 메모하세요',
                      style: AppFonts.bold.h5.copyWith(
                        color: AppColors.dark.darkest,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _MemoInputBox(
                      controller: _memoController,
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
                          child: drop_down(
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
                          child: drop_down(
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
                      backgroundColor: buttonColor,
                      onPressed: _submitEdit,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            CustomTabBar(
              selectedIndex: _selectedTabIndex,
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditImageSection extends StatelessWidget {
  final bool hasImage;
  final bool isRemoved;
  final VoidCallback onTapChangePhoto;

  const _EditImageSection({
    required this.hasImage,
    required this.isRemoved,
    required this.onTapChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText = '사진 변경하기';

    if (isRemoved) {
      buttonText = '사진 다시 적용하기';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.light.darkest,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            alignment: Alignment.center,
            child: hasImage
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 120,
                color: AppColors.light.light,
                alignment: Alignment.center,
                child: Text(
                  '기존 또는 새 이미지',
                  style: AppFonts.light.m.copyWith(
                    color: AppColors.dark.darkest,
                  ),
                ),
              ),
            )
                : Image.asset('assets/icons/photo.png'),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 62,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.signature.darkest,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onTapChangePhoto,
              child: Text(
                buttonText,
                style: AppFonts.light.xl.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoInputBox extends StatelessWidget {
  final TextEditingController controller;

  const _MemoInputBox({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.signature.darkest,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: CupertinoTextField(
        controller: controller,
        maxLines: null,
        expands: true,
        padding: EdgeInsets.zero,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        placeholder: 'text',
        placeholderStyle: AppFonts.light.xl.copyWith(
          color: AppColors.dark.darkest.withValues(alpha: 0.55),
        ),
        style: AppFonts.light.xl.copyWith(
          color: AppColors.dark.darkest,
        ),
        cursorColor: AppColors.signature.darkest,
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
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppFonts.light.m.copyWith(
            color: AppColors.dark.darkest,
          ),
        ),
      ),
    );
  }
}