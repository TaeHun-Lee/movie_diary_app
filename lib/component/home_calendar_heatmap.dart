import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/component/home_diary_card.dart';

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
    // Monday = 1, Sunday = 7 → offset for grid
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;

    final monthNames = [
      '', '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월',
    ];

    final totalViews =
        heatmap.values.fold<int>(0, (sum, count) => sum + count);

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monthNames[now.month]} 관람 기록',
                style: const TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kOnSurface,
                ),
              ),
              Text(
                '$totalViews편 관람',
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 12,
                  color: kOnSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingL),

          // Weekday labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map(
                  (d) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        d,
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

          // Calendar grid
          _buildCalendarGrid(
              context, daysInMonth, firstWeekday, heatmap, now.day),
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

    // Empty cells before first day (Monday-based: Monday=1)
    final emptyBefore = (firstWeekday - 1) % 7;
    for (int i = 0; i < emptyBefore; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
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
              border: isToday
                  ? Border.all(color: kPrimary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: kHeadlineFont,
                  fontSize: 11,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday && count == 0 ? kPrimary : textColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Fill remaining cells to complete the grid
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
    final dayEntries = entries.where((e) {
      final date = DateTime.tryParse(e.watchedDate);
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
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: kSurfaceLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXL + 4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingXL, kSpacingS, kSpacingXL, kSpacingL),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kRadiusS),
                    ),
                    child: Text(
                      '${dayEntries.length}편',
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

            // Entry list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(kSpacingXL, 0, kSpacingXL, kSpacing3XL),
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
