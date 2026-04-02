import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  
  // Drawer 열기 이벤트를 알리기 위한 노티파이어
  final ValueNotifier<int> openDrawerNotifier = ValueNotifier<int>(0);
  
  // 탭 리셋 요청을 알리기 위한 노티파이어 (index 저장)
  final ValueNotifier<int?> resetTabNotifier = ValueNotifier<int?>(null);

  // 특정 탭으로 화면을 푸시하도록 알리는 노티파이어
  final ValueNotifier<PushTabEvent?> pushToTabNotifier = ValueNotifier<PushTabEvent?>(null);

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // 특정 탭의 스택을 초기화(리셋)하도록 요청합니다.
  void requestTabReset(int index) {
    resetTabNotifier.value = index;
  }

  // 특정 탭으로 화면을 푸시하도록 요청합니다.
  void pushToTab(int index, Widget screen) {
    pushToTabNotifier.value = PushTabEvent(index: index, screen: screen);
  }

  // Drawer 열기 이벤트를 발생시킵니다.
  void openMainDrawer() {
    openDrawerNotifier.value++;
  }
}

class PushTabEvent {
  final int index;
  final Widget screen;

  PushTabEvent({required this.index, required this.screen});
}
