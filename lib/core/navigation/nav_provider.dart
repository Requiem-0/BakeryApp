import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  void triggerHomeTap() {
    notifyListeners();
  }

  void triggerCategoryChange() {
    notifyListeners();
  }
}
