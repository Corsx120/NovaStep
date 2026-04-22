import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/task_provider.dart';
import '../../logic/providers/settings_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? task;
  const NoteEditorScreen({super.key, this.task});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedGroupId;
  List<String> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!['title'];
      _contentController.text = widget.task!['content'];
      _selectedGroupId = widget.task!['group_id'];
      
      // Загружаем теги, если редактируем заметку
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tags = context.read<TaskProvider>().getTagsForTask(widget.task!['id']);
        setState(() {
          _selectedTagIds = tags.map((t) => t['id'] as String).toList();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.task == null ? 'Новая заметка' : 'Редактирование', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary, size: 28),
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                if (widget.task == null) {
                  taskProvider.addTask(_titleController.text, _contentController.text, _selectedGroupId, _selectedTagIds);
                } else {
                  taskProvider.updateTask(widget.task!['id'], _titleController.text, _contentController.text, _selectedGroupId, _selectedTagIds);
                }
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF2E1065)] 
              : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        decoration: const InputDecoration(hintText: 'Заголовок...', border: InputBorder.none),
                      ),
                      const Divider(),
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        style: TextStyle(fontSize: settings.fontSize, color: textColor.withValues(alpha: 0.8)),
                        decoration: const InputDecoration(hintText: 'Описание...', border: InputBorder.none),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- СЕКЦИЯ ТЕГОВ И ГРУПП ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Секция Тегов
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ТЕГИ:', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () => _showAddTagDialog(context, taskProvider, textColor),
                            child: Text('+ Новый тег', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        children: taskProvider.tags.map((t) => _buildTagChip(t, textColor)).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Секция Групп
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text('ГРУППА:', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        children: [
                          _buildGroupOption('Без группы', null, textColor),
                          ...taskProvider.groups.map((g) => _buildGroupOption(g['name'], g['id'], textColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(Map<String, dynamic> tag, Color textColor) {
    final isSelected = _selectedTagIds.contains(tag['id']);
    final tagColor = Color(int.parse(tag['color_hex'].replaceFirst('#', '0xFF')));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(tag['name'], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selected ? _selectedTagIds.add(tag['id']) : _selectedTagIds.remove(tag['id']);
          });
        },
        backgroundColor: Colors.transparent,
        selectedColor: tagColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: tagColor)
        ),
      ),
    );
  }

  Widget _buildGroupOption(String name, String? id, Color textColor) {
    final isSelected = _selectedGroupId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(name, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedGroupId = id),
        selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        labelStyle: TextStyle(color: isSelected ? const Color(0xFF8B5CF6) : textColor),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, TaskProvider provider, Color textColor) {
    final controller = TextEditingController();
    // Простой набор цветов для тегов
    final List<String> colors = ['#EF4444', '#F59E0B', '#10B981', '#3B82F6', '#8B5CF6', '#EC4899'];
    String selectedColor = colors[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Новый тег', style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(hintText: 'Например: Срочно')),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setState(() => selectedColor = c),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                    child: selectedColor == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                )).toList(),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) provider.addTag(controller.text, selectedColor);
                Navigator.pop(context);
              }, 
              child: const Text('Создать')
            ),
          ],
        ),
      ),
    );
  }
}