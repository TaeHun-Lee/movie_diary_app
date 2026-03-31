import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  
  // Drawer 열기 이벤트를 알리기 위한 노티파이어
  final ValueNotifier<int> openDrawerNotifier = ValueNotifier<int>(0);

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // Drawer 열기 이벤트를 발생시킵니다.
  void openMainDrawer() {
    openDrawerNotifier.value++;
  }
}
