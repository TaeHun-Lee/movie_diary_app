import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/screens/home_screen.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';
import 'package:movie_diary_app/screens/my_diary_list_screen.dart';
import 'package:movie_diary_app/screens/my_page_screen.dart';
import 'package:movie_diary_app/component/custom_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();
  final GlobalKey<MovieSearchScreenState> _searchKey = GlobalKey();

  List<Widget> get _pages => [
        HomeScreen(
          key: _homeKey,
          onSearchTap: () => _onItemTapped(1),
          onDiaryTabTap: () => _onItemTapped(2),
        ),
        MovieSearchScreen(
          key: _searchKey,
          onBack: () => _onItemTapped(0),
        ),
        const MyDiaryListScreen(),
        const MyPageScreen(),
      ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index && index == 0) {
      _homeKey.currentState?.refresh();
    }
    if (index == 1) {
      _searchKey.currentState?.reset();
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: const CustomAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      extendBody: true, // body가 네비게이션 바 아래까지 확장
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glassmorphic Bottom Navigation Bar
// ─────────────────────────────────────────────
class _GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: '홈'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: '탐색'),
    _NavItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: '다이어리'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: kSurfaceDim.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: bottomPadding > 0 ? bottomPadding : 12,
            left: 8,
            right: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == selectedIndex;
              return _NavBarItem(
                item: item,
                selected: selected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? kPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                color: selected ? kPrimary : kOnSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? kPrimary : kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
