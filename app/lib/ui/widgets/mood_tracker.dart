import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../../logic/providers/task_provider.dart';
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
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GlassContainer(
      blur: settings.blurRadius,
      opacity: isDark ? 0.1 : 0.4,
      padding: const EdgeInsets.all(10.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Как настроение?',
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis, // Добавит многоточие при нехватке места
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onClose,
                child: Icon(Icons.close, color: textColor.withValues(alpha: 0.5), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8), 
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4.0, // Расстояние между смайликами по горизонтали
              runSpacing: 4.0, // Расстояние по вертикали (если перенесутся на новую строку)
              children: List.generate(_moods.length, (index) {
                final isSelected = _selectedMood == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withValues(alpha: 0.3) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(_moods[index], style: const TextStyle(fontSize: 32)), 
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 10),
          Text('Настрой:', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 4),
          
          Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: List.generate(_readiness.length, (index) {
              final isSelected = _selectedReadiness == index;
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                label: Text(_readiness[index], style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedReadiness = index),
                backgroundColor: textColor.withValues(alpha: 0.05),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : textColor.withValues(alpha: 0.8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide.none,
              );
            }),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _selectedMood != null && _selectedReadiness != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0), 
                    child: SizedBox(
                      width: double.infinity,
                      height: 36, 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          context.read<TaskProvider>().addMoodLog(_selectedMood!, _selectedReadiness!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Записано! 📝'))
                          );
                          widget.onClose();
                        },
                        child: const Text('Сохранить', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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