import 'package:flutter/material.dart';

enum AppMode { pizarra, desktop }

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.desktop;

  AppMode get mode => _mode;
  bool get isPizarra => _mode == AppMode.pizarra;
  bool get isDesktop => _mode == AppMode.desktop;

  void setMode(AppMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  // Sugerir modo basado en tamaño de pantalla
  static AppMode suggestMode(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 1400 ? AppMode.pizarra : AppMode.desktop;
  }
}