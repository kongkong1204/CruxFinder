// lib/screens/feed.dart

import 'package:crux_finder/screens/feed_edit.dart';
import 'package:crux_finder/screens/feed_upload.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:flutter/material.dart';
import '../components/card.dart';
import '../components/tab_bar.dart';
import '../services/api_service.dart';

class FeedItem {
  final int id;
  final String memo;
  final String dateText;
  final String absoluteGrade;
  final String relativeGrade;
  final DateTime climbedAt;

  FeedItem({
    required this.id,
    required this.memo,
    required this.dateText,
    required this.absoluteGrade,
    required this.relativeGrade,
    required this.climbedAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final climbedAt = DateTime.parse(json['climbedAt']);
    final dateText =
        '${climbedAt.year}.${climbedAt.month.toString().padLeft(2, '0')}.${climbedAt.day.toString().padLeft(2, '0')}';
    return FeedItem(
      id: json['id'],
      memo: json['memo'] ?? '',
      dateText: dateText,
      absoluteGrade: json['vGrade'] ?? '',
      relativeGrade: json['myDifficulty'] ?? '',
      climbedAt: climbedAt,
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int selectedTabIndex = 1;

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
        feeds = data.map((e) => FeedItem.fromJson(e)).toList();
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

  void _onTabTap(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeedUploadPage()),
      ).then((_) => _loadFeeds());
      return;
    }
    setState(() {
      selectedTabIndex = index;
    });
  }

  void _onMoreTap(FeedItem feed) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedEditPage(
                      feedId: feed.id,
                      initialMemo: feed.memo,
                      initialDateTime: feed.climbedAt,
                      initialVGrade: feed.absoluteGrade,
                      initialMyDifficulty: feed.relativeGrade,
                    ),
                  ),
                ).then((refreshed) {
                  if (refreshed == true) _loadFeeds();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(feed);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FeedItem feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('피드 삭제'),
        content: const Text('이 피드를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'feed',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
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
                          padding: const EdgeInsets.only(bottom: 20),
                          child: FeedCard(
                            memo: feed.memo,
                            dateText: feed.dateText,
                            absoluteGrade: feed.absoluteGrade,
                            relativeGrade: feed.relativeGrade,
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
      bottomNavigationBar: CustomTabBar(
        selectedIndex: selectedTabIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
