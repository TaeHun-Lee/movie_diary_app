import 'package:flutter/material.dart';
import 'package:movie_diary_app/screens/explore_screen.dart';
import 'package:movie_diary_app/screens/home_screen.dart';
import 'package:movie_diary_app/screens/movie_search_screen.dart';
import 'package:movie_diary_app/screens/my_page_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _bottomNavIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ExploreScreen(),
    const MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // '글쓰기' 탭
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MovieSearchScreen()),
      );
    } else {
      setState(() {
        _bottomNavIndex = index;
      });
    }
  }

  int get _pageIndex {
    if (_bottomNavIndex >= 2) {
      return _bottomNavIndex - 1;
    }
    return _bottomNavIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: '탐색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: '글쓰기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _bottomNavIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
