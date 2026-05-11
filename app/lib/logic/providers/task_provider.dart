import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class TaskProvider extends ChangeNotifier {
  // === ПЕРЕМЕННЫЕ СОСТОЯНИЯ ===
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _taskTags = [];
  List<Map<String, dynamic>> _moodLogs = [];

  String _selectedGroupId = 'all'; 
  String _searchQuery = '';

  // === ГЕТТЕРЫ ===
  List<Map<String, dynamic>> get tasks {
    List<Map<String, dynamic>> filteredList = [];

    if (_selectedGroupId == 'all') {
      filteredList = _tasks.where((t) => t['is_completed'] == 0 && t['is_deleted'] == 0).toList();
    } else if (_selectedGroupId == 'completed') {
      filteredList = _tasks.where((t) => t['is_completed'] == 1 && t['is_deleted'] == 0).toList();
    } else {
      filteredList = _tasks.where((t) => t['group_id'] == _selectedGroupId && t['is_completed'] == 0 && t['is_deleted'] == 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((t) {
        final title = (t['title'] as String).toLowerCase();
        final content = (t['content'] as String).toLowerCase();
        return title.contains(_searchQuery) || content.contains(_searchQuery);
      }).toList();
    }

    return filteredList;
  }

  List<Map<String, dynamic>> get deletedTasks => _tasks.where((t) => t['is_deleted'] == 1).toList();
  List<Map<String, dynamic>> get groups => _groups;
  List<Map<String, dynamic>> get tags => _tags;
  List<Map<String, dynamic>> get moodLogs => _moodLogs;
  String get selectedGroupId => _selectedGroupId;

  TaskProvider() {
    refreshData();
  }

  Future<void> refreshData() async {
    final db = await DatabaseHelper.instance.database;
    _tasks = await db.query('tasks', orderBy: 'is_pinned DESC, created_at DESC');
    _groups = await db.query('groups');
    _tags = await db.query('tags');
    _taskTags = await db.query('task_tags');
    _moodLogs = await db.query('mood_logs', orderBy: 'log_date DESC');
    notifyListeners();
  }

  void selectGroup(String id) {
    _selectedGroupId = id;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // === ЛОГИКА КАЛЕНДАРЯ И НАСТРОЕНИЯ ===
  Future<void> addMoodLog(int moodScore, int readinessScore) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('mood_logs', {
      'id': const Uuid().v4(),
      'log_date': DateTime.now().toIso8601String().split('T')[0],
      'mood_score': moodScore,
      'readiness_score': readinessScore,
    });
    await refreshData();
  }

  // Подсчет выполненных задач за любой период (идеально для JSON)
  int getCompletedCountBetween(DateTime start, DateTime end) {
    return _tasks.where((t) {
      if (t['is_completed'] != 1) return false;
      try {
        final date = DateTime.parse(t['created_at']);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
               date.isBefore(end.add(const Duration(seconds: 1)));
      } catch (e) {
        return false;
      }
    }).length;
  }

  // Подсчет выполненных задач за конкретный день (нужно для умного помощника)
  int getCompletedCountForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getCompletedCountBetween(start, end);
  }

  // Расчет среднего настроения за период
  double getMoodAverageBetween(DateTime start, DateTime end) {
    final logs = _moodLogs.where((m) {
      try {
        final date = DateTime.parse(m['log_date']);
        return date.isAfter(start.subtract(const Duration(days: 1))) && 
               date.isBefore(end.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    if (logs.isEmpty) return 0.0;
    
    double sum = 0;
    for (var log in logs) {
      // 0 = 🤩, 4 = 😭. Переводим в шкалу от 0.0 до 1.0, где 1.0 - лучшее
      int score = log['mood_score'] as int;
      sum += (4 - score) / 4.0; 
    }
    return sum / logs.length;
  }

  // === ЛОГИКА ЗАДАЧ И ГРУПП ===
  List<Map<String, dynamic>> getTagsForTask(String taskId) {
    final tagIds = _taskTags.where((tt) => tt['task_id'] == taskId).map((tt) => tt['tag_id']).toList();
    return _tags.where((t) => tagIds.contains(t['id'])).toList();
  }

  Future<void> addTask(String title, String content, String? groupId, List<String> tagIds) async {
    final db = await DatabaseHelper.instance.database;
    final taskId = const Uuid().v4();
    await db.insert('tasks', {
      'id': taskId,
      'title': title,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'is_completed': 0,
      'is_pinned': 0,
      'is_deleted': 0,
      'group_id': groupId,
    });
    
    for (var tagId in tagIds) {
      await db.insert('task_tags', {'task_id': taskId, 'tag_id': tagId});
    }
    await refreshData();
  }

  Future<void> updateTask(String id, String title, String content, String? groupId, List<String> tagIds) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {
      'title': title,
      'content': content,
      'group_id': groupId,
      'created_at': DateTime.now().toIso8601String(), // Поднимаем наверх при смене группы или редактировании
    }, where: 'id = ?', whereArgs: [id]);
    
    await db.delete('task_tags', where: 'task_id = ?', whereArgs: [id]);
    for (var tagId in tagIds) {
      await db.insert('task_tags', {'task_id': id, 'tag_id': tagId});
    }
    await refreshData();
  }

  Future<void> toggleComplete(String id, int currentStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {
      'is_completed': currentStatus == 1 ? 0 : 1,
      'created_at': DateTime.now().toIso8601String(), // Обновляем время
    }, where: 'id = ?', whereArgs: [id]);
    await refreshData();
  }

  Future<void> togglePin(String id, int currentStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {'is_pinned': currentStatus == 1 ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
    await refreshData();
  }

  Future<void> moveToTrash(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
    await refreshData();
  }

  Future<void> restoreTask(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {
      'is_deleted': 0,
      'created_at': DateTime.now().toIso8601String(), // Чтобы восстановленная задача была сверху
    }, where: 'id = ?', whereArgs: [id]);
    await refreshData();
  }

  Future<void> deleteTaskPermanently(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await refreshData();
  }

  Future<void> emptyTrash() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks', where: 'is_deleted = 1');
    await refreshData();
  }

  Future<void> addGroup(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('groups', {'id': const Uuid().v4(), 'name': name, 'color_hex': '#8B5CF6'});
    await refreshData();
  }

  Future<void> deleteGroup(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {'group_id': null}, where: 'group_id = ?', whereArgs: [id]);
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
    if (_selectedGroupId == id) _selectedGroupId = 'all';
    await refreshData();
  }

  Future<void> addTag(String name, String colorHex) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('tags', {'id': const Uuid().v4(), 'name': name, 'color_hex': colorHex});
    await refreshData();
  }

  Future<void> deleteTag(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    await refreshData();
  }

  Future<void> fullReset() async {
    await DatabaseHelper.instance.clearDatabase();
    await refreshData(); 
  }

  Future<String?> exportData() async {
  try {
    final jsonString = await DatabaseHelper.instance.exportToJson();

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Для десктопа оставляем старый добрый диалог сохранения
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить резервную копию',
        fileName: 'novastep_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        return 'Данные успешно экспортированы!';
      }
    } else {
      // Для мобилок используем "Поделиться", это 100% обходит проблемы с правами
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/novastep_backup.json');
      await file.writeAsString(jsonString);
      
      final xFile = XFile(file.path);
      // Используем актуальный синтаксис share_plus:
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Резервная копия NovaStep',
        ),
      );
      return 'Меню экспорта открыто';
    }
    return null;
  } catch (e) {
    return 'Ошибка экспорта: $e';
  }
}

  Future<String?> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Выберите файл резервной копии',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        await DatabaseHelper.instance.importFromJson(jsonString);
        await refreshData(); 
        return 'Данные успешно восстановлены!';
      }
      return null; 
    } catch (e) {
      return 'Ошибка импорта: неверный формат файла';
    }
  }
}