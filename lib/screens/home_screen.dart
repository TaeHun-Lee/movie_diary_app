import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:movie_diary_app/component/home_content.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/providers/home_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onDiaryTabTap;

  const HomeScreen({super.key, this.onSearchTap, this.onDiaryTabTap});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().fetchHomeData();
    });
  }

  Future<void> refresh() async {
    await context.read<HomeProvider>().fetchHomeData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, child) {
            if (homeProvider.isLoading && homeProvider.homeData == null) {
              return _buildSkeletonLoading();
            } else if (homeProvider.homeData == null) {
              return _buildErrorState();
            } else {
              return HomeContent(
                data: homeProvider.homeData!,
                onRefresh: refresh,
                onSearchTap: widget.onSearchTap,
                onDiaryTabTap: widget.onDiaryTabTap,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: kSurfaceLow,
      highlightColor: kSurfaceLowest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 인사말 skeleton
            Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(
                width: 200,
                height: 28,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),

            // Featured Card skeleton
            Container(
                height: 220,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 28),

            // 벤토 그리드 skeleton (2×2)
            Row(children: [
              Expanded(
                  child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
            ]),
            const SizedBox(height: 32),

            // 가로 스크롤 skeleton
            Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: Row(
                  children: List.generate(
                      3,
                      (i) => Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14))),
                          ))),
            ),
            const SizedBox(height: 32),

            // 캘린더 skeleton
            Container(
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 32),

            // 다이어리 카드 skeleton × 3
            ...List.generate(
                3,
                (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18))),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final homeProvider = context.read<HomeProvider>();
    final message = homeProvider.errorMessage ?? '데이터를 불러오지 못했습니다.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: kSurfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 30,
                color: kOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 14,
                color: kOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (homeProvider.errorMessage == null)
              Text(
                '네트워크 연결을 확인해주세요.',
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 12,
                  color: kOnSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: refresh,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(
                    fontFamily: kHeadlineFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
