import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedPeriodIndex = 0; // 0 - Неделя, 1 - Месяц, 2 - Год

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF2E1065),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // === ПЕРЕКЛЮЧАТЕЛЬ ПЕРИОДА ===
              GlassContainer(
                padding: const EdgeInsets.all(4.0),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    _buildPeriodButton('Неделя', 0),
                    _buildPeriodButton('Месяц', 1),
                    _buildPeriodButton('Год', 2),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === ГРАФИК ПРОДУКТИВНОСТИ ===
              const Text(
                'ПРОДУКТИВНОСТЬ',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Выполнено задач', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('14', style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Имитация столбчатого графика
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChartBar(0.4, 'Пн'),
                        _buildChartBar(0.7, 'Вт'),
                        _buildChartBar(1.0, 'Ср', isToday: true), // Пик продуктивности!
                        _buildChartBar(0.3, 'Чт'),
                        _buildChartBar(0.8, 'Пт'),
                        _buildChartBar(0.2, 'Сб'),
                        _buildChartBar(0.1, 'Вс'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === ДНЕВНИК НАСТРОЕНИЯ ===
              const Text(
                'ИСТОРИЯ НАСТРОЕНИЯ',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    _buildMoodRow('Сегодня', 'Готов свернуть горы', '🤩'),
                    const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                    _buildMoodRow('Вчера', 'Немного устал, но держусь', '🫠'),
                    const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                    _buildMoodRow('Позавчера', 'Спокойный рабочий настрой', '🙂'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Вспомогательные методы для чистоты кода ---

  // Кнопка переключения периода (Неделя/Месяц/Год)
  Widget _buildPeriodButton(String title, int index) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Столбик графика
  Widget _buildChartBar(double heightFactor, String label, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          height: 120, // Максимальная высота графика
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
                      ? Theme.of(context).colorScheme.secondary 
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
            color: isToday ? Theme.of(context).colorScheme.secondary : Colors.white54,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Строка с записью настроения
  Widget _buildMoodRow(String date, String description, String emoji) {
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
                Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}