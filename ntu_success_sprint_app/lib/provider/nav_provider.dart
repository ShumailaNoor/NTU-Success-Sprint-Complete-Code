// navigation_provider.dart
import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 1; // Default page is Available Programs

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
