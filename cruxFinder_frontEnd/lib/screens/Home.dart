// lib/screens/Home.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/Card.dart';
import '../components/TabBar.dart';
import '../components/ButtonPrimary.dart';
import '../components/ActionSheetOverlay.dart';
import '../services/api_service.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';
import 'FeedEdit.dart';
import 'Solution.dart';

class FeedItem {
  final int id;
  final String memo;
  final String dateText;
  final String absoluteGrade;
  final String relativeGrade;
  final String? imageUrl;
  final DateTime climbedAt;
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
    required this.vGrade,
    required this.myDifficulty,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // 백엔드 Feed: id, memo, climbedAt(ISO), vGrade, myDifficulty, imageUrl
    final climbed = DateTime.tryParse(json['climbedAt']?.toString() ?? '') ??
        DateTime.now();
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
      vGrade: json['vGrade'] ?? '',
      myDifficulty: json['myDifficulty'] ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTabIndex = 0;
  bool _showSheet = false;
  FeedItem? _sheetTarget;   // 시트가 대상으로 하는 피드

  bool isLoading = true;
  String? errorMessage;
  List<FeedItem> feeds = [];

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService().getFeeds();
      if (!mounted) return;
      setState(() {
        feeds = data.map((e) => FeedItem.fromJson(e)).take(5).toList();
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
                    'Crux Finder',
                    style: AppFonts.title.T.copyWith(
                      color: AppColors.dark.darkest,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '최근 기록',
                    style: AppFonts.bold.l.copyWith(
                      color: AppColors.dark.darkest,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Builder(
                      builder: (context) {
                        if (isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (errorMessage != null) {
                          return Center(child: Text(errorMessage!));
                        }
                        if (feeds.isEmpty) {
                          return const Center(child: Text('피드가 없습니다.'));
                        }
                        return RefreshIndicator(
                          onRefresh: _loadFeeds,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: feeds.length,
                            itemBuilder: (context, index) {
                              final feed = feeds[index];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(0,20,0,20),
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Crux Finder와 함께 분석하기',
                    style: AppFonts.bold.xl.copyWith(
                      color: AppColors.dark.darkest,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ButtonPrimary(
                    text: '시작하기',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SolutionScreen()),
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
