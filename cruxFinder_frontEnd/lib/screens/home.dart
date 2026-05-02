// lib/screens/Home.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/Card.dart';
import '../components/TabBar.dart';
import '../components/ButtonPrimary.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTabIndex = 0;

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
                    return const Center(
                      child: Text('피드가 없습니다.'),
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
              child: ButtonPrimary(text: '시작하기', onPressed: () {}),
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