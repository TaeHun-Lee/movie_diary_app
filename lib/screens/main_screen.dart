import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/screens/home_screen.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';
import 'package:movie_diary_app/screens/my_diary_list_screen.dart';
import 'package:movie_diary_app/screens/my_page_screen.dart';
import 'package:movie_diary_app/component/custom_drawer.dart';
import 'package:movie_diary_app/providers/navigation_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 메인 스크린 고유의 ScaffoldKey 생성
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 캐싱을 위한 필드
  late NavigationProvider _navProvider;

  // 각 탭의 내비게이션 상태를 관리하기 위한 키
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();
  final GlobalKey<MovieSearchScreenState> _searchKey = GlobalKey();
  final GlobalKey<MyDiaryListScreenState> _diaryListKey = GlobalKey();
  final GlobalKey<MyPageScreenState> _myPageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // initState에서 프로바이더의 노티파이어를 리스너로 등록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navProvider = Provider.of<NavigationProvider>(context, listen: false);
        _navProvider.openDrawerNotifier.addListener(_onOpenDrawerEvent);
        _navProvider.resetTabNotifier.addListener(_onResetTabEvent);
        _navProvider.pushToTabNotifier.addListener(_onPushToTabEvent);
      }
    });
  }

  @override
  void dispose() {
    // 리스너 해제
    _navProvider.openDrawerNotifier.removeListener(_onOpenDrawerEvent);
    _navProvider.resetTabNotifier.removeListener(_onResetTabEvent);
    _navProvider.pushToTabNotifier.removeListener(_onPushToTabEvent);
    super.dispose();
  }

  // Drawer 열기 이벤트 처리
  void _onOpenDrawerEvent() {
    if (mounted && _scaffoldKey.currentState != null) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  // 탭 리셋 이벤트 처리
  void _onResetTabEvent() {
    final index = _navProvider.resetTabNotifier.value;
    if (index != null && mounted) {
      final navigatorState = _navigatorKeys[index].currentState;
      if (navigatorState != null && navigatorState.canPop()) {
        navigatorState.popUntil((route) => route.isFirst);
      }
    }
  }

  // 특정 탭으로 푸시 이벤트 처리
  void _onPushToTabEvent() {
    final event = _navProvider.pushToTabNotifier.value;
    if (event != null && mounted) {
      // 탭 전환
      _onItemTapped(event.index);
      
      // 탭 전환 직후 내비게이터에 푸시
      // 약간의 지연을 주어 탭 전환이 완료된 후 푸시되도록 함
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final navigatorState = _navigatorKeys[event.index].currentState;
          if (navigatorState != null) {
            navigatorState.push(MaterialPageRoute(
              builder: (context) => event.screen,
            ));
          }
        }
      });
    }
  }

  void _onItemTapped(int index) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    
    // 선택된 탭의 내비게이터 상태 확인
    final navigatorState = _navigatorKeys[index].currentState;

    if (navProvider.selectedIndex == index) {
      // 이미 선택된 탭을 다시 누른 경우
      if (navigatorState != null && navigatorState.canPop()) {
        // 뒤로 갈 스택이 있다면 루트로 이동
        navigatorState.popUntil((route) => route.isFirst);
      } else {
        // 이미 루트라면 새로고침/초기화 수행
        _refreshCurrentTab(index);
      }
    } else {
      // 새로운 탭으로 전환하는 경우
      if (navigatorState != null && navigatorState.canPop()) {
        // 전환하려는 탭의 스택이 쌓여있다면 루트로 초기화 (10-1 요구사항)
        navigatorState.popUntil((route) => route.isFirst);
      }
      navProvider.setSelectedIndex(index);
      _scheduleTabRefresh(index);
    }
  }

  void _refreshCurrentTab(int index) {
    if (index == 0) {
      _homeKey.currentState?.refresh();
    } else if (index == 1) {
      _searchKey.currentState?.reset();
    } else if (index == 2) {
      _diaryListKey.currentState?.refresh();
    } else if (index == 3) {
      _myPageKey.currentState?.refresh();
    }
  }

  void _scheduleTabRefresh(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshCurrentTab(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final selectedIndex = navProvider.selectedIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (selectedIndex < 0 || selectedIndex >= _navigatorKeys.length) return;

        final NavigatorState? currentNavigator =
            _navigatorKeys[selectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          // 현재 탭에 뒤로 갈 스택이 있다면 pop
          currentNavigator.pop();
        } else {
          // 더 이상 pop 할 스택이 없고 홈 탭이 아니라면 홈 탭으로 이동
          if (selectedIndex != 0) {
            navProvider.setSelectedIndex(0);
          } else {
            // 홈 탭에서도 뒤로가기를 누르면 앱 종료 처리를 위한 pop 시도
            if (context.mounted) {
              final rootNavigator = Navigator.of(context);
              if (rootNavigator.canPop()) {
                rootNavigator.pop();
              }
            }
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey, // 고유한 로컬 Key
        backgroundColor: kSurface,
        drawer: const CustomDrawer(),
        body: IndexedStack(
          index: selectedIndex,
          children: [
            TabNavigator(
              navigatorKey: _navigatorKeys[0],
              rootPage: HomeScreen(
                key: _homeKey,
                onSearchTap: () => _onItemTapped(1),
                onDiaryTabTap: () => _onItemTapped(2),
              ),
            ),
            TabNavigator(
              navigatorKey: _navigatorKeys[1],
              rootPage: MovieSearchScreen(
                key: _searchKey,
                onBack: () => _onItemTapped(0),
              ),
            ),
            TabNavigator(
              navigatorKey: _navigatorKeys[2],
              rootPage: MyDiaryListScreen(key: _diaryListKey),
            ),
            TabNavigator(
              navigatorKey: _navigatorKeys[3],
              rootPage: MyPageScreen(key: _myPageKey),
            ),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: _GlassNavBar(
          selectedIndex: selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab Navigator
// ─────────────────────────────────────────────
class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootPage;

  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.rootPage,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
          settings: routeSettings,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Glassmorphic Bottom Navigation Bar
// ─────────────────────────────────────────────
class _GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({required this.selectedIndex, required this.onTap});

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: '홈',
    ),
    _NavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: '탐색',
    ),
    _NavItem(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      label: '다이어리',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: '프로필',
    ),
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
            border: Border.all(
              color: kOutlineVariant.withValues(alpha: 0.15),
              width: 1,
            ),
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? kPrimary : kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
