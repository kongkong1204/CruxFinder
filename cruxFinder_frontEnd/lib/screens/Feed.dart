// lib/screens/Feed.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/Card.dart';
import '../components/TabBar.dart';
import '../styles/colors.dart';
import '../styles/fonts.dart';

class FeedItem {
  final String memo;
  final String dateText;
  final String absoluteGrade;
  final String relativeGrade;

  FeedItem({
    required this.memo,
    required this.dateText,
    required this.absoluteGrade,
    required this.relativeGrade,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      memo: json['memo'] ?? '',
      dateText: json['dateText'] ?? '',
      absoluteGrade: json['absoluteGrade'] ?? '',
      relativeGrade: json['relativeGrade'] ?? '',
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
    await Future.delayed(const Duration(seconds: 1));

    try {
      final fakeData = [
        FeedItem(
          memo: '메모 내용 작성 란',
          dateText: '2026.03.22',
          absoluteGrade: 'V5',
          relativeGrade: '6',
        ),
        FeedItem(
          memo: '메모 내용 작성 란',
          dateText: '2026.03.21',
          absoluteGrade: 'V4',
          relativeGrade: '5',
        ),
        FeedItem(
          memo: '슬로퍼가 너무 힘들었다',
          dateText: '2026.03.20',
          absoluteGrade: 'V3',
          relativeGrade: '4',
        ),
      ];

      if (!mounted) return;

      setState(() {
        feeds = fakeData;
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
                'Feed',
                style: AppFonts.title.T.copyWith(
                  color: AppColors.dark.darkest,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (errorMessage != null) {
                    return Center(
                      child: Text(errorMessage!),
                    );
                  }

                  if (feeds.isEmpty) {
                    return Center(
                      child: Text(
                        '피드가 없습니다.',
                        style: AppFonts.bold.m.copyWith(
                          color: AppColors.signature.darkest,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
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
                          onMoreTap: () {},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomTabBar(
        selectedIndex: selectedTabIndex,
      ),
    );
  }
}