import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool? isMale;
  String? token;

  void setGender(bool male) {
    isMale = male;
    notifyListeners();
  }

  void setToken(String? t) {
    token = t;
    notifyListeners();
  }

  void reset() {
    isMale = null;
    token = null;
    notifyListeners();
  }
} 