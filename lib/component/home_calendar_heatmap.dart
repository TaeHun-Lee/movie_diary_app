import 'package:flutter/material.dart';
import 'package:movie_diary_app/component/home_diary_card.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';

class HomeCalendarHeatmap extends StatelessWidget {
  final Map<int, int> heatmap;
  final List<DiaryEntry> entries;
  final VoidCallback? onRefresh;

  const HomeCalendarHeatmap({
    super.key,
    required this.heatmap,
    required this.entries,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final totalViews = heatmap.values.fold<int>(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(kSpacingXL),
      decoration: BoxDecoration(
        color: kSurfaceLowest,
        borderRadius: BorderRadius.circular(kRadiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: kSurfaceDim.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${now.month}월 관람 기록',
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kOnSurface,
                ),
              ),
              Text(
                '$totalViews회 관람',
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 12,
                  color: kOnSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map(
                  (weekday) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        weekday,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: kOnSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: kSpacingS),
          _buildCalendarGrid(
            context,
            daysInMonth,
            firstWeekday,
            heatmap,
            now.day,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    int daysInMonth,
    int firstWeekday,
    Map<int, int> heatmap,
    int today,
  ) {
    final cells = <Widget>[];
    final emptyBefore = (firstWeekday - 1) % 7;

    for (int i = 0; i < emptyBefore; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final count = heatmap[day] ?? 0;
      final isToday = day == today;

      Color bgColor;
      if (count >= 3) {
        bgColor = kPrimary.withValues(alpha: 0.85);
      } else if (count == 2) {
        bgColor = kPrimary.withValues(alpha: 0.5);
      } else if (count == 1) {
        bgColor = kPrimary.withValues(alpha: 0.2);
      } else {
        bgColor = kSurfaceLow;
      }

      final textColor = count >= 2 ? Colors.white : kOnSurfaceVariant;

      cells.add(
        GestureDetector(
          onTap: count > 0 ? () => _showDayEntries(context, day) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(kRadiusS),
              border: isToday ? Border.all(color: kPrimary, width: 2) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday && count == 0 ? kPrimary : textColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final totalCells = emptyBefore + daysInMonth;
    final remainingCells = (7 - (totalCells % 7)) % 7;
    for (int i = 0; i < remainingCells; i++) {
      cells.add(const SizedBox());
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: cells,
    );
  }

  void _showDayEntries(BuildContext context, int day) {
    final now = DateTime.now();
    final dayEntries = entries.where((entry) {
      final date = DateTime.tryParse(entry.watchedDate);
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == day;
    }).toList();

    if (dayEntries.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: kSurfaceLowest,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusXL + 4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kSurfaceDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kSpacingXL,
                kSpacingS,
                kSpacingXL,
                kSpacingL,
              ),
              child: Row(
                children: [
                  Text(
                    '${now.month}월 ${day}일 관람 기록',
                    style: const TextStyle(
                      fontFamily: kHeadlineFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kOnSurface,
                    ),
                  ),
                  const SizedBox(width: kSpacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kRadiusS),
                    ),
                    child: Text(
                      '${dayEntries.length}개',
                      style: const TextStyle(
                        fontFamily: kHeadlineFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  kSpacingXL,
                  0,
                  kSpacingXL,
                  kSpacingNav,
                ),
                itemCount: dayEntries.length,
                itemBuilder: (ctx, i) =>
                    HomeDiaryCard(entry: dayEntries[i], onRefresh: onRefresh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
