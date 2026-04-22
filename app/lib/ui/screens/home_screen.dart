import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/task_provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/app_drawer.dart';
import '../widgets/mood_tracker.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMoodTracker = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Поиск задач...',
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                ),
                onChanged: (value) => taskProvider.setSearchQuery(value),
              )
            : const Text('NovaStep'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  taskProvider.setSearchQuery('');
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.grid_view), onPressed: () {}),
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
          child: CustomScrollView(
            slivers: [
              if (_showMoodTracker)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MoodTrackerWidget(onClose: () => setState(() => _showMoodTracker = false)),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildGlassChip(context, 'Все', 'all', taskProvider, settings),
                      _buildGlassChip(context, 'Выполненные', 'completed', taskProvider, settings),
                      ...taskProvider.groups.map((g) => _buildGlassChip(context, g['name'], g['id'], taskProvider, settings)),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: GestureDetector(
                          onTap: () => _showAddGroupDialog(context, taskProvider, settings),
                          child: const GlassContainer(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.add, color: Color(0xFF8B5CF6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.only(top: 12),
                sliver: taskProvider.tasks.isEmpty 
                  ? SliverFillRemaining(
                      child: Center(
                        child: Text(
                          taskProvider.selectedGroupId == 'completed' ? 'Список выполненных пуст' : 'Задач пока нет',
                          style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTaskCard(context, taskProvider.tasks[index], taskProvider, settings),
                        childCount: taskProvider.tasks.length,
                      ),
                    ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGlassChip(BuildContext context, String label, String id, TaskProvider provider, SettingsProvider settings) {
  final isSelected = provider.selectedGroupId == id;
  final isDark = settings.isDarkMode;
  
  return Padding(
    padding: const EdgeInsets.all(6.0),
    child: GestureDetector(
      onTap: () => provider.selectGroup(id),
      onLongPress: () {
        if (id != 'all' && id != 'completed') {
          _showDeleteGroupDialog(context, provider, label, id);
        }
      },
      child: GlassContainer(
        blur: settings.blurRadius,
        opacity: isSelected ? 0.3 : 0.1,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            label, 
            style: TextStyle(
              color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? Colors.white : const Color(0xFF0F172A)),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ),
      ),
    ),
  );
}

void _showDeleteGroupDialog(BuildContext context, TaskProvider provider, String name, String id) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Удалить группу "$name"?'),
      content: const Text('Задачи останутся, но потеряют привязку к этой группе.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        TextButton(
          onPressed: () {
            provider.deleteGroup(id);
            Navigator.pop(context);
          }, 
          child: const Text('Удалить', style: TextStyle(color: Colors.red))
        ),
      ],
    ),
  );
}

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task, TaskProvider provider, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final isPinned = task['is_pinned'] == 1;
    final taskTags = provider.getTagsForTask(task['id']); // Достаем теги для этой задачи
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassContainer(
        blur: settings.blurRadius,
        child: ListTile(
          leading: Checkbox(
            value: task['is_completed'] == 1,
            activeColor: const Color(0xFF8B5CF6),
            onChanged: (_) => provider.toggleComplete(task['id'], task['is_completed']),
          ),
          title: Text(
            task['title'], 
            style: TextStyle(
              color: textColor, 
              fontWeight: FontWeight.bold,
              decoration: task['is_completed'] == 1 ? TextDecoration.lineThrough : null,
            )
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task['content'], maxLines: 1, style: const TextStyle(color: Colors.grey)),
              // Выводим теги, если они есть
              if (taskTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: taskTags.map((tag) {
                      final tagColor = Color(int.parse(tag['color_hex'].replaceFirst('#', '0xFF')));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          tag['name'], 
                          style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                  color: isPinned ? Colors.orangeAccent : textColor.withValues(alpha: 0.3),
                  size: 20,
                ),
                onPressed: () => provider.togglePin(task['id'], task['is_pinned']),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: Color(0xFF8B5CF6)), 
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => NoteEditorScreen(task: task))
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22), 
                onPressed: () => provider.moveToTrash(task['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, TaskProvider provider, SettingsProvider settings) {
    final controller = TextEditingController();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: GlassContainer(
            blur: settings.blurRadius,
            padding: const EdgeInsets.all(24.0),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Новая группа', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller, 
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Название...',
                      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withValues(alpha: 0.3))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: Text('Отмена', style: TextStyle(color: textColor.withValues(alpha: 0.7)))
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (controller.text.isNotEmpty) provider.addGroup(controller.text);
                          Navigator.pop(context);
                        },
                        child: const Text('Создать'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}