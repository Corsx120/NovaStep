import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/settings_provider.dart';
import 'glass_container.dart';

class MoodTrackerWidget extends StatefulWidget {
  final VoidCallback onClose;

  const MoodTrackerWidget({super.key, required this.onClose});

  @override
  State<MoodTrackerWidget> createState() => _MoodTrackerWidgetState();
}

class _MoodTrackerWidgetState extends State<MoodTrackerWidget> {
  int? _selectedMood;
  int? _selectedReadiness;

  // Реверс: от радости к грусти
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
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    // Динамический цвет текста в зависимости от темы
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GlassContainer(
      blur: settings.blurRadius,
      opacity: isDark ? 0.1 : 0.4, // В светлой теме делаем стекло чуть плотнее
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Как твое настроение сегодня?',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: widget.onClose,
                child: Icon(Icons.close, color: textColor.withValues(alpha: 0.5), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_moods.length, (index) {
              final isSelected = _selectedMood == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary.withValues(alpha: 0.3) 
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(_moods[index], style: const TextStyle(fontSize: 40)),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text('Настрой на задачи:', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(_readiness.length, (index) {
              final isSelected = _selectedReadiness == index;
              return ChoiceChip(
                label: Text(_readiness[index]),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedReadiness = index),
                backgroundColor: textColor.withValues(alpha: 0.05),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : textColor.withValues(alpha: 0.8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
              );
            }),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _selectedMood != null && _selectedReadiness != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          widget.onClose();
                        },
                        child: const Text('Сохранить в дневник', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}