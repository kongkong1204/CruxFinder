// lib/screens/Feed.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/Card.dart';
import '../components/TabBar.dart';
import '../components/ActionSheetOverlay.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import 'FeedEdit.dart';

class FeedItem {
  final int id;
  final String memo;
  final String dateText;
  final String absoluteGrade;
  final String relativeGrade;
  final String? imageUrl;
  final DateTime climbedAt;
  final DateTime createdAt;
  final String vGrade;
  final String myDifficulty;

  FeedItem({
    required this.id,
    required this.memo,
    required this.dateText,
    required this.absoluteGrade,
    required this.relativeGrade,
    required this.imageUrl,
    required this.climbedAt,
    required this.createdAt,
    required this.vGrade,
    required this.myDifficulty,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // 백엔드 Feed: id, memo, climbedAt(ISO), createdAt(ISO), vGrade, myDifficulty, imageUrl
    final climbed = DateTime.tryParse(json['climbedAt']?.toString() ?? '') ??
        DateTime.now();
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        climbed;
    String two(int n) => n.toString().padLeft(2, '0');
    final dateText =
        '${climbed.year}.${two(climbed.month)}.${two(climbed.day)}';

    return FeedItem(
      id: json['id'] as int,
      memo: json['memo'] ?? '',
      dateText: dateText,
      absoluteGrade: json['vGrade'] ?? '',
      relativeGrade: json['myDifficulty'] ?? '',
      imageUrl: json['imageUrl'] as String?,
      climbedAt: climbed,
      createdAt: created,
      vGrade: json['vGrade'] ?? '',
      myDifficulty: json['myDifficulty'] ?? '',
    );
  }
}

// 날짜만 비교 (시/분 무시)
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// 해당 날짜가 속한 주의 일요일(주 시작)을 구함
DateTime _weekStart(DateTime d) {
  final base = DateTime(d.year, d.month, d.day);
  return base.subtract(Duration(days: base.weekday % 7)); // 일요일=0 기준
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int selectedTabIndex = 1;
  bool _showSheet = false;
  FeedItem? _sheetTarget;

  bool isLoading = true;
  String? errorMessage;
  List<FeedItem> feeds = [];

  // 선택된 날짜 (이 날짜의 피드만 표시). 기본: 오늘
  DateTime _selectedDate = DateTime.now();
  // 현재 보고 있는 주의 시작(일요일)
  late DateTime _visibleWeekStart;

  @override
  void initState() {
    super.initState();
    _visibleWeekStart = _weekStart(_selectedDate);
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService().getFeeds();
      final list = data
          .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        feeds = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // 선택된 날짜(등반일 기준)의 피드만 필터
  List<FeedItem> get _filteredFeeds =>
      feeds.where((f) => _isSameDay(f.climbedAt, _selectedDate)).toList();

  void _onMoreTap(FeedItem feed) {
    setState(() {
      _sheetTarget = feed;
      _showSheet = true;
    });
  }

  void _openEdit(FeedItem feed) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedEditScreen(
          feedId: feed.id,
          initialMemo: feed.memo,
          initialDateTime: feed.climbedAt,
          initialVGrade: feed.absoluteGrade,
          initialMyDifficulty: feed.relativeGrade,
          initialImageUrl: feed.imageUrl,
        ),
      ),
    ).then((refreshed) {
      if (refreshed == true) _loadFeeds();
    });
  }

  Future<void> _confirmDelete(FeedItem feed) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('피드 삭제'),
        content: const Text('이 피드를 삭제할까요?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().deleteFeed(feed.id);
      _loadFeeds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFeeds;

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
                    'feed',
                    style: AppFonts.title.T.copyWith(
                      color: AppColors.dark.darkest,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 주간 캘린더 (좌우 슬라이드로 주 이동)
                _WeekCalendar(
                  weekStart: _visibleWeekStart,
                  selectedDate: _selectedDate,
                  onSelectDate: (d) => setState(() => _selectedDate = d),
                  onPrevWeek: () => setState(() {
                    _visibleWeekStart =
                        _visibleWeekStart.subtract(const Duration(days: 7));
                  }),
                  onNextWeek: () => setState(() {
                    _visibleWeekStart =
                        _visibleWeekStart.add(const Duration(days: 7));
                  }),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (errorMessage != null) {
                        return Center(child: Text(errorMessage!));
                      }
                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _loadFeeds,
                          child: ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  '이 날짜의 피드가 없습니다.',
                                  style: AppFonts.bold.m.copyWith(
                                    color: AppColors.signature.darkest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _loadFeeds,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final feed = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: FeedCard(
                                memo: feed.memo,
                                dateText: feed.dateText,
                                absoluteGrade: feed.absoluteGrade,
                                relativeGrade: feed.relativeGrade,
                                imageUrl: feed.imageUrl,
                                onMoreTap: () => _onMoreTap(feed),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ActionSheetOverlay(
            visible: _showSheet,
            actions: [
              ActionSheetItem(
                label: '수정',
                onTap: () => _openEdit(_sheetTarget!),
              ),
              ActionSheetItem(
                label: '삭제',
                isDestructive: true,
                onTap: () => _confirmDelete(_sheetTarget!),
              ),
            ],
            onCancel: () => setState(() => _showSheet = false),
          ),
        ],
      ),
      bottomNavigationBar: CustomTabBar(
        selectedIndex: selectedTabIndex,
      ),
    );
  }
}

// ── 주간 캘린더 위젯 ─────────────────────────────────────────
class _WeekCalendar extends StatelessWidget {
  final DateTime weekStart;       // 이 주의 일요일
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const _WeekCalendar({
    required this.weekStart,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    // 이 주의 7일
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return GestureDetector(
      // 좌우 스와이프로 주 이동
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < 0) {
          onNextWeek(); // 왼쪽으로 밀면 다음 주
        } else if (v > 0) {
          onPrevWeek(); // 오른쪽으로 밀면 이전 주
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = days[i];
            final isSelected = _isSameDay(day, selectedDate);
            return GestureDetector(
              onTap: () => onSelectDate(day),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    _weekdayLabels[i],
                    style: AppFonts.bold.xs.copyWith(
                      color: AppColors.dark.darkest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.signature.darkest
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: AppFonts.regular.m.copyWith(
                        color: isSelected
                            ? AppColors.light.lightest
                            : AppColors.dark.darkest,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}