import 'package:flutter/material.dart';
import 'package:movie_diary_app/constants.dart';
import 'package:movie_diary_app/screens/home_screen.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';
import 'package:movie_diary_app/screens/my_page_screen.dart';

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
    ), // 홈 -> 검색 탭 전환
    MovieSearchScreen(
      key: _searchKey,
      onBack: () => _onItemTapped(0),
    ), // 검색 -> 홈 탭 전환
    const MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index && index == 0) {
      // 이미 홈 탭에 있는데 다시 누르면 새로고침
      _homeKey.currentState?.refresh();
    }

    // 검색 탭으로 이동하거나(다른 탭에서), 이미 검색 탭인데 다시 누른 경우 모두 초기화
    if (index == 1) {
      _searchKey.currentState?.reset();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E), // Dark background for nav bar
        selectedItemColor: kPrimaryRedColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        showSelectedLabels: true,
      ),
    );
  }
}
