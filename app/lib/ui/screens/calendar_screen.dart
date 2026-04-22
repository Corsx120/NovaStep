import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/task_provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../widgets/glass_container.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedPeriodIndex = 0; // 0 - Неделя, 1 - Месяц, 2 - Год

  // Для расшифровки логов настроения из БД
  final List<String> _moods = ['🤩', '🙂', '😐', '😞', '😭'];
  final List<String> _readiness = [
    'Полностью готов!',
    'Потихоньку начну',
    'Не уверен',
    'Не хочу ничего...',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final settings = context.watch<SettingsProvider>();
    
    // Поддержка темной и светлой темы
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // Считаем выполненные задачи за последние 7 дней для заголовка
    int totalCompletedThisWeek = 0;
    for (int i = 0; i < 7; i++) {
      totalCompletedThisWeek += taskProvider.getCompletedCountForDate(DateTime.now().subtract(Duration(days: i)));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Статистика', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF2E1065), const Color(0xFF0F172A)]
              : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // === ПЕРЕКЛЮЧАТЕЛЬ ПЕРИОДА ===
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.all(4.0),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    _buildPeriodButton('Неделя', 0, theme, textColor, isDark),
                    _buildPeriodButton('Месяц', 1, theme, textColor, isDark),
                    _buildPeriodButton('Год', 2, theme, textColor, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === ГРАФИК ПРОДУКТИВНОСТИ ===
              Text(
                'ПРОДУКТИВНОСТЬ',
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Задач за неделю', style: TextStyle(color: textColor, fontSize: 16)),
                        Text('$totalCompletedThisWeek', style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Динамический график за 7 дней
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        // Идем с конца (6 дней назад -> сегодня)
                        final date = DateTime.now().subtract(Duration(days: 6 - index));
                        final count = taskProvider.getCompletedCountForDate(date);
                        
                        // Высчитываем высоту: если 0 задач - показываем минимум (0.05), если 10+ - максимум (1.0)
                        double factor = count == 0 ? 0.05 : (count / 10).clamp(0.1, 1.0); 
                        final labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                        
                        return _buildChartBar(
                          factor, 
                          labels[date.weekday - 1], 
                          isToday: index == 6, 
                          theme: theme, 
                          textColor: textColor
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === ДНЕВНИК НАСТРОЕНИЯ ===
              Text(
                'ИСТОРИЯ НАСТРОЕНИЯ',
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                blur: settings.blurRadius,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: taskProvider.moodLogs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Записей пока нет',
                          style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    )
                  : Column(
                      children: taskProvider.moodLogs.map((log) {
                        // Форматируем дату и проверяем, сегодня ли это
                        final dateStr = log['log_date'] as String;
                        final isToday = dateStr == DateTime.now().toIso8601String().split('T')[0];
                        final displayDate = isToday ? 'Сегодня' : dateStr;
                        
                        // Достаем индексы и подставляем эмодзи с текстом
                        final moodIndex = log['mood_score'] as int;
                        final readinessIndex = log['readiness_score'] as int;
                        final emoji = (moodIndex >= 0 && moodIndex < _moods.length) ? _moods[moodIndex] : '❓';
                        final desc = (readinessIndex >= 0 && readinessIndex < _readiness.length) ? _readiness[readinessIndex] : '...';

                        return Column(
                          children: [
                            _buildMoodRow(displayDate, desc, emoji, textColor),
                            if (log != taskProvider.moodLogs.last)
                              Divider(color: textColor.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                          ],
                        );
                      }).toList(),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Вспомогательные методы с поддержкой динамических цветов ---

  Widget _buildPeriodButton(String title, int index, ThemeData theme, Color textColor, bool isDark) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.8) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : textColor.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar(double heightFactor, String label, {bool isToday = false, required ThemeData theme, required Color textColor}) {
    return Column(
      children: [
        Container(
          height: 120, 
          width: 30,
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                height: constraints.maxHeight * heightFactor,
                decoration: BoxDecoration(
                  color: isToday 
                      ? theme.colorScheme.secondary 
                      : theme.colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isToday ? theme.colorScheme.secondary : textColor.withValues(alpha: 0.54),
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodRow(String date, String description, String emoji, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}