import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // === 1. Все состояния ===
  bool _isDarkMode = true;
  double _blurRadius = 15.0;
  String _userName = 'Пользователь';
  
  // Новые состояния, которых не хватало:
  double _fontSize = 16.0;
  bool _isPraiseEnabled = true;
  bool _isReminderEnabled = true;

  // === 2. Геттеры для UI ===
  bool get isDarkMode => _isDarkMode;
  double get blurRadius => _blurRadius;
  String get userName => _userName;
  
  // Новые геттеры:
  double get fontSize => _fontSize;
  bool get isPraiseEnabled => _isPraiseEnabled;
  bool get isReminderEnabled => _isReminderEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  // === 3. Загрузка данных ===
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _blurRadius = prefs.getDouble('blurRadius') ?? 15.0;
    _userName = prefs.getString('userName') ?? 'Пользователь';
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _isPraiseEnabled = prefs.getBool('isPraiseEnabled') ?? true;
    _isReminderEnabled = prefs.getBool('isReminderEnabled') ?? true;
    notifyListeners();
  }

  // === 4. Методы сохранения (Сеттеры) ===
  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> updateBlur(double value) async {
    _blurRadius = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blurRadius', value);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    notifyListeners();
  }

  // Новые методы:
  Future<void> updateFontSize(double value) async {
    _fontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
    notifyListeners();
  }

  Future<void> togglePraise(bool value) async {
    _isPraiseEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPraiseEnabled', value);
    notifyListeners();
  }

  Future<void> toggleReminder(bool value) async {
    _isReminderEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isReminderEnabled', value);
    notifyListeners();
  }
}