import 'package:flutter/material.dart';
import '../../data/local/database_helper.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _taskTags = [];
  String _selectedGroupId = 'all'; 
  String _searchQuery = '';

  List<Map<String, dynamic>> get tasks {
    List<Map<String, dynamic>> filteredList = [];

    // Сначала фильтруем по выбранной группе
    if (_selectedGroupId == 'all') {
      filteredList = _tasks.where((t) => t['is_completed'] == 0 && t['is_deleted'] == 0).toList();
    } else if (_selectedGroupId == 'completed') {
      filteredList = _tasks.where((t) => t['is_completed'] == 1 && t['is_deleted'] == 0).toList();
    } else {
      filteredList = _tasks.where((t) => t['group_id'] == _selectedGroupId && t['is_completed'] == 0 && t['is_deleted'] == 0).toList();
    }

    // Затем фильтруем результат по поисковому запросу (если он не пустой)
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

  // Получить теги для конкретной задачи
  List<Map<String, dynamic>> getTagsForTask(String taskId) {
    final tagIds = _taskTags.where((tt) => tt['task_id'] == taskId).map((tt) => tt['tag_id']).toList();
    return _tags.where((t) => tagIds.contains(t['id'])).toList();
  }

  // --- ЛОГИКА ЗАДАЧ (обновлена с тегами) ---
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
    
    // Привязываем теги
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
    }, where: 'id = ?', whereArgs: [id]);
    
    // Обновляем теги: удаляем старые и записываем новые
    await db.delete('task_tags', where: 'task_id = ?', whereArgs: [id]);
    for (var tagId in tagIds) {
      await db.insert('task_tags', {'task_id': id, 'tag_id': tagId});
    }
    await refreshData();
  }

  Future<void> toggleComplete(String id, int currentStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {'is_completed': currentStatus == 1 ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
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
    await db.update('tasks', {'is_deleted': 0}, where: 'id = ?', whereArgs: [id]);
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

  // --- ЛОГИКА ГРУПП ---
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

  // --- ЛОГИКА ТЕГОВ ---
  Future<void> addTag(String name, String colorHex) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('tags', {'id': const Uuid().v4(), 'name': name, 'color_hex': colorHex});
    await refreshData();
  }
}