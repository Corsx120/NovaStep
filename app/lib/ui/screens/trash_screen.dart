import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/task_provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../widgets/glass_container.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final deletedTasks = taskProvider.deletedTasks;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Корзина', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (deletedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Очистить корзину',
              onPressed: () => _showEmptyTrashDialog(context, taskProvider, textColor, settings),
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
          child: deletedTasks.isEmpty
              ? Center(
                  child: Text(
                    'Корзина пуста',
                    style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: deletedTasks.length,
                  itemBuilder: (context, index) {
                    final task = deletedTasks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: GlassContainer(
                        blur: settings.blurRadius,
                        opacity: isDark ? 0.05 : 0.2, // Делаем чуть более блеклым
                        child: ListTile(
                          title: Text(
                            task['title'],
                            style: TextStyle(color: textColor.withValues(alpha: 0.6), decoration: TextDecoration.lineThrough),
                          ),
                          subtitle: Text(
                            task['content'],
                            maxLines: 1,
                            style: TextStyle(color: textColor.withValues(alpha: 0.4)),
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Восстановить',
                                onPressed: () => taskProvider.restoreTask(task['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                tooltip: 'Удалить навсегда',
                                onPressed: () => taskProvider.deleteTaskPermanently(task['id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showEmptyTrashDialog(BuildContext context, TaskProvider provider, Color textColor, SettingsProvider settings) {
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
                  Text('Очистить корзину?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 12),
                  Text(
                    'Все задачи будут удалены навсегда без возможности восстановления.',
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: Text('Отмена', style: TextStyle(color: textColor.withValues(alpha: 0.7)))
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          provider.emptyTrash();
                          Navigator.pop(context);
                        },
                        child: const Text('Очистить'),
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