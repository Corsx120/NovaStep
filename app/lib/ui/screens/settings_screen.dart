import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../../logic/providers/task_provider.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final taskProvider = context.watch<TaskProvider>(); 
    final theme = Theme.of(context);
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Настройки', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF2E1065), const Color(0xFF0F172A)]
              : [Colors.blue[50]!, Colors.purple[50]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // === БЛОК 1: ПЕРСОНАЛИЗАЦИЯ ИНТЕРФЕЙСА ===
              _buildSectionTitle('ИНТЕРФЕЙС', theme),
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text('Темная тема', style: TextStyle(color: textColor)),
                      value: settings.isDarkMode,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) => settings.toggleTheme(value),
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, indent: 16, endIndent: 16),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Сила размытия стекла', style: TextStyle(color: textColor)),
                    ),
                    Slider(
                      value: settings.blurRadius,
                      min: 0.0,
                      max: 40.0,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                      onChanged: (value) => settings.updateBlur(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === БЛОК 2: БЕЗОПАСНОСТЬ ===
              _buildSectionTitle('БЕЗОПАСНОСТЬ', theme),
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('ПИН-код при входе', style: TextStyle(color: textColor)),
                      subtitle: Text('Запрашивать пароль при запуске', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
                      value: settings.isPinEnabled,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) => settings.togglePin(value),
                    ),
                    if (settings.isPinEnabled) ...[
                      Divider(color: isDark ? Colors.white12 : Colors.black12, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text('Изменить ПИН-код', style: TextStyle(color: textColor)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _showChangePinDialog(context, settings, theme),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === БЛОК 3: УМНЫЙ ПОМОЩНИК И УВЕДОМЛЕНИЯ ===
              _buildSectionTitle('УМНЫЙ ПОМОЩНИК', theme),
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Хвалить за успехи', style: TextStyle(color: textColor)),
                      subtitle: Text('Получать мотивирующие фразы', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
                      value: settings.isPraiseEnabled,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) => settings.togglePraise(value),
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text('Ежедневные уведомления', style: TextStyle(color: textColor)),
                      subtitle: Text('Напоминать зайти в приложение вечером', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
                      value: settings.isReminderEnabled,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) {
                        settings.toggleReminder(value);
                        if (value) {
                          _showMessage(context, 'Уведомления включены', theme);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === БЛОК 4: ДАННЫЕ ===
              _buildSectionTitle('ДАННЫЕ', theme),
              GlassContainer(
                blur: settings.blurRadius,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.file_download_outlined, color: textColor),
                      title: Text('Экспорт резервной копии (JSON)', style: TextStyle(color: textColor)),
                      onTap: () async {
                        final result = await taskProvider.exportData();
                        if (result != null && context.mounted) {
                          _showMessage(context, result, theme);
                        }
                      },
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                    ListTile(
                      leading: Icon(Icons.file_upload_outlined, color: textColor),
                      title: Text('Восстановить из файла', style: TextStyle(color: textColor)),
                      onTap: () async {
                        final result = await taskProvider.importData();
                        if (result != null && context.mounted) {
                          _showMessage(context, result, theme);
                        }
                      },
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined, color: Colors.orangeAccent),
                      title: const Text('Очистить корзину', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      onTap: () {
                        taskProvider.emptyTrash();
                        _showMessage(context, 'Корзина успешно очищена', theme);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === БЛОК 5: ОПАСНАЯ ЗОНА ===
              _buildSectionTitle('ОПАСНАЯ ЗОНА', theme),
              GlassContainer(
                blur: settings.blurRadius,
                opacity: isDark ? 0.05 : 0.2,
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.priority_high_rounded, color: Colors.redAccent),
                  title: const Text('Сбросить все данные', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: Text('Удалит все задачи, группы и настройки', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  onTap: () => _showResetDialog(context, settings, taskProvider, theme),
                ),
              ),
              const SizedBox(height: 32),

              // === БЛОК 6: О ПРИЛОЖЕНИИ ===
              Center(
                child: Column(
                  children: [
                    Text('NovaStep v1.0.0', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Разработано Корсом', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательный метод для показа уведомлений
  void _showMessage(BuildContext context, String text, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)), 
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  // Диалог для смены ПИН-кода
  void _showChangePinDialog(BuildContext context, SettingsProvider settings, ThemeData theme) {
    final controller = TextEditingController();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Новый ПИН-код', style: TextStyle(color: textColor)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: TextStyle(color: textColor, letterSpacing: 16, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0000',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Отмена', style: TextStyle(color: textColor.withValues(alpha: 0.6)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.length == 4) {
                settings.updatePinCode(controller.text);
                Navigator.pop(context);
                _showMessage(context, 'ПИН-код успешно изменен!', theme);
              } else {
                _showMessage(context, 'ПИН-код должен состоять из 4 цифр', theme);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // Диалоговое окно для подтверждения сброса данных
  void _showResetDialog(BuildContext context, SettingsProvider settings, TaskProvider taskProvider, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Полный сброс?'),
        content: const Text('Это действие нельзя отменить. Все ваши задачи, группы и настройки будут удалены навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Отмена')
          ),
          TextButton(
            onPressed: () async {
              await taskProvider.fullReset();
              await settings.resetToDefaults();
              if (!context.mounted) return;
              Navigator.pop(context);
              _showMessage(context, 'Все данные сброшены к дефолту', theme);
            }, 
            child: const Text('Удалить всё', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
      ),
    );
  }
}