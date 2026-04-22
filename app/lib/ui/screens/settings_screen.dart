import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Настройки', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
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
                      title: Text('Темная тема', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      value: settings.isDarkMode,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) => settings.toggleTheme(value),
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, indent: 16, endIndent: 16),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Сила размытия стекла', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    Slider(
                      value: settings.blurRadius,
                      min: 0.0,
                      max: 40.0,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                      onChanged: (value) => settings.updateBlur(value),
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, indent: 16, endIndent: 16),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                      child: Text('Базовый размер шрифта', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Пример текста', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: settings.fontSize)),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: isDark ? Colors.white : Colors.black87),
                                onPressed: () => settings.updateFontSize((settings.fontSize - 1).clamp(12.0, 24.0)),
                              ),
                              Text('${settings.fontSize.toInt()}', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline, color: isDark ? Colors.white : Colors.black87),
                                onPressed: () => settings.updateFontSize((settings.fontSize + 1).clamp(12.0, 24.0)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === БЛОК 2: УМНЫЙ ПОМОЩНИК ===
              _buildSectionTitle('УМНЫЙ ПОМОЩНИК', theme),
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Хвалить за успехи', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      subtitle: Text('Получать мотивирующие фразы', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6), fontSize: 12)),
                      value: settings.isPraiseEnabled,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) => settings.togglePraise(value),
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text('Мягкие напоминания', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      subtitle: Text('Напоминать о забытых задачах', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6), fontSize: 12)),
                      value: settings.isReminderEnabled,
                      activeThumbColor: theme.colorScheme.secondary,
                      onChanged: (value) => settings.toggleReminder(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === БЛОК 3: ДАННЫЕ ===
              _buildSectionTitle('ДАННЫЕ', theme),
              GlassContainer(
                blur: settings.blurRadius,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.file_download_outlined, color: isDark ? Colors.white : Colors.black87),
                      title: Text('Экспорт статистики (PDF)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Генерация отчета...'), backgroundColor: theme.colorScheme.primary),
                        );
                      },
                    ),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: const Text('Очистить корзину', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === БЛОК 4: О ПРИЛОЖЕНИИ ===
              Center(
                child: Column(
                  children: [
                    Text('NovaStep v1.0.0', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Разработано главным архитектором', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12)),
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