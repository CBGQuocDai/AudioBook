import 'package:flutter/material.dart';

class BookDetailProvider extends ChangeNotifier {
  int currentTab = 0;

  void changeTab(int index) {
    currentTab = index;
    notifyListeners();
  }
}