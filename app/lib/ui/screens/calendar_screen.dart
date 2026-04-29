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

  final List<String> _moods = ['🤩', '🙂', '😐', '😞', '😭'];
  final List<String> _readiness = [
    'Полностью готов!',
    'Потихоньку начну',
    'Не уверен',
    'Не хочу ничего...',
  ];

  final List<String> _weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  final List<String> _months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final settings = context.watch<SettingsProvider>();
    
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // Подготовка данных для графиков
    List<double> taskCounts = [];
    List<double> moodAverages = [];
    List<String> labels = [];
    int totalTasksForPeriod = 0;

    final now = DateTime.now();

    if (_selectedPeriodIndex == 0) {
      // === НЕДЕЛЯ (последние 7 дней) ===
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        DateTime start = DateTime(date.year, date.month, date.day);
        DateTime end = DateTime(date.year, date.month, date.day, 23, 59, 59);
        
        int count = taskProvider.getCompletedCountBetween(start, end);
        totalTasksForPeriod += count;
        taskCounts.add(count.toDouble());
        moodAverages.add(taskProvider.getMoodAverageBetween(start, end));
        labels.add(_weekDays[date.weekday - 1]);
      }
    } else if (_selectedPeriodIndex == 1) {
      // === МЕСЯЦ (последние 4 недели) ===
      for (int i = 3; i >= 0; i--) {
        DateTime end = now.subtract(Duration(days: i * 7));
        DateTime start = end.subtract(const Duration(days: 6));
        start = DateTime(start.year, start.month, start.day);
        end = DateTime(end.year, end.month, end.day, 23, 59, 59);

        int count = taskProvider.getCompletedCountBetween(start, end);
        totalTasksForPeriod += count;
        taskCounts.add(count.toDouble());
        moodAverages.add(taskProvider.getMoodAverageBetween(start, end));
        labels.add('${4-i} нед.');
      }
    } else if (_selectedPeriodIndex == 2) {
      // === ГОД (последние 12 месяцев) ===
      for (int i = 11; i >= 0; i--) {
        DateTime start = DateTime(now.year, now.month - i, 1);
        DateTime end = DateTime(start.year, start.month + 1, 0, 23, 59, 59); // Последний день месяца

        int count = taskProvider.getCompletedCountBetween(start, end);
        totalTasksForPeriod += count;
        taskCounts.add(count.toDouble());
        moodAverages.add(taskProvider.getMoodAverageBetween(start, end));
        labels.add(_months[start.month - 1]);
      }
    }

    // Нормализация высоты столбиков (чтобы самый высокий занимал 100% высоты контейнера)
    double maxTask = taskCounts.isEmpty ? 0 : taskCounts.reduce((a, b) => a > b ? a : b);
    List<double> normalizedTaskFactors = taskCounts.map((v) => maxTask == 0 ? 0.05 : (v / maxTask).clamp(0.05, 1.0)).toList();
    List<double> normalizedMoodFactors = moodAverages.map((v) => v == 0.0 ? 0.05 : v.clamp(0.05, 1.0)).toList();

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
                opacity: isDark ? 0.1 : 0.4,
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
                opacity: isDark ? 0.1 : 0.4,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Выполнено задач', style: TextStyle(color: textColor, fontSize: 16)),
                        Text('$totalTasksForPeriod', style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildBarChart(normalizedTaskFactors, labels, theme.colorScheme.primary, theme, textColor),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === ГРАФИК НАСТРОЕНИЯ ===
              Text(
                'ИНДЕКС НАСТРОЕНИЯ',
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                blur: settings.blurRadius,
                opacity: isDark ? 0.1 : 0.4,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Среднее настроение', style: TextStyle(color: textColor, fontSize: 16)),
                        Text(
                          normalizedMoodFactors.last > 0.6 ? '🤩' : (normalizedMoodFactors.last > 0.3 ? '😐' : '😭'), 
                          style: const TextStyle(fontSize: 24)
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildBarChart(normalizedMoodFactors, labels, Colors.orangeAccent, theme, textColor), // Оранжевый график для настроения
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === ДНЕВНИК (ИСТОРИЯ) ===
              Text(
                'ИСТОРИЯ',
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                blur: settings.blurRadius,
                opacity: isDark ? 0.1 : 0.4,
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
                      children: taskProvider.moodLogs.take(10).map((log) { // Показываем только 10 последних
                        final dateStr = log['log_date'] as String;
                        final isToday = dateStr == now.toIso8601String().split('T')[0];
                        final displayDate = isToday ? 'Сегодня' : dateStr;
                        
                        final moodIndex = log['mood_score'] as int;
                        final readinessIndex = log['readiness_score'] as int;
                        final emoji = (moodIndex >= 0 && moodIndex < _moods.length) ? _moods[moodIndex] : '❓';
                        final desc = (readinessIndex >= 0 && readinessIndex < _readiness.length) ? _readiness[readinessIndex] : '...';

                        return Column(
                          children: [
                            _buildMoodRow(displayDate, desc, emoji, textColor),
                            if (log != taskProvider.moodLogs.take(10).last)
                              Divider(color: textColor.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                          ],
                        );
                      }).toList(),
                    ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

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

  // Универсальный метод построения графика
  Widget _buildBarChart(List<double> factors, List<String> labels, Color activeColor, ThemeData theme, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(factors.length, (index) {
        bool isCurrentPeriod = index == factors.length - 1; // Подсвечиваем последний столбик
        return Column(
          children: [
            Container(
              height: 100,
              width: _selectedPeriodIndex == 2 ? 20 : 30, // Делаем столбики тоньше в режиме года
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart,
                    height: constraints.maxHeight * factors[index],
                    decoration: BoxDecoration(
                      color: isCurrentPeriod ? theme.colorScheme.secondary : activeColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels[index],
              style: TextStyle(
                color: isCurrentPeriod ? theme.colorScheme.secondary : textColor.withValues(alpha: 0.54),
                fontWeight: isCurrentPeriod ? FontWeight.bold : FontWeight.normal,
                fontSize: _selectedPeriodIndex == 2 ? 10 : 12, // Уменьшаем шрифт месяцев для года
              ),
            ),
          ],
        );
      }),
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