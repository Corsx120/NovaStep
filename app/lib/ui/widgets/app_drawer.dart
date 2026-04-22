import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/settings_provider.dart';
import 'glass_container.dart';
import '../screens/calendar_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/trash_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    // Исправлено: теперь в светлой теме используется глубокий синий
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        blur: settings.blurRadius,
        opacity: isDark ? 0.12 : 0.3,
        child: SafeArea(
          child: Column(
            children: [
              // --- ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                      child: Icon(Icons.person_rounded, size: 40, color: textColor),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  settings.userName,
                                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _showNameDialog(context, settings),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(Icons.edit_rounded, size: 16, color: theme.colorScheme.secondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Гость', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: textColor.withValues(alpha: 0.1), height: 1),

              // --- ПУНКТЫ МЕНЮ ---
              _buildMenuItem(
                context,
                icon: Icons.calendar_month_rounded,
                title: 'Календарь и Статистика',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.delete_outline_rounded,
                title: 'Недавно удаленные',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context); // Закрываем меню
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TrashScreen())); // Открываем корзину
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.settings_rounded,
                title: 'Настройки',
                textColor: textColor,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required Color textColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: textColor.withValues(alpha: 0.7), size: 26),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      hoverColor: textColor.withValues(alpha: 0.05),
    );
  }

  // --- СТЕКЛЯННЫЙ ДИАЛОГ СМЕНЫ ИМЕНИ ---
  void _showNameDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userName);
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
                  Text('Как к тебе обращаться?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller, 
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Введи имя",
                      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withValues(alpha: 0.3))),
                    ),
                    textCapitalization: TextCapitalization.words,
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
                          if (controller.text.trim().isNotEmpty) {
                            settings.updateUserName(controller.text.trim());
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Сохранить'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}