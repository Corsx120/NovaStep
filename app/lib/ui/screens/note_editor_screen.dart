import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart'; // для открытия настроек
import '../../logic/providers/task_provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../widgets/glass_container.dart';
import 'dart:io' show Platform;
import '../widgets/mouse_scroll_wrapper.dart';


class NoteEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? task;
  const NoteEditorScreen({super.key, this.task});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  
  String? _selectedGroupId;
  List<String> _selectedTagIds = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;

  final ScrollController _groupsScrollController = ScrollController();
  final ScrollController _tagsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    if (widget.task != null) {
      _titleController.text = widget.task!['title'];
      _contentController.text = widget.task!['content'];
      _selectedGroupId = widget.task!['group_id'];
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tags = context.read<TaskProvider>().getTagsForTask(widget.task!['id']);
        setState(() {
          _selectedTagIds = tags.map((t) => t['id'] as String).toList();
        });
      });
    }
  }

  @override
  void dispose() {
    _groupsScrollController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  TextEditingController get _activeController {
    if (_titleFocus.hasFocus) return _titleController;
    return _contentController;
  }

  // --- ЛОГИКА ГОЛОСОВОГО ВВОДА С ОБРАБОТКОЙ ОШИБОК ---
  void _listen() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize(
          onError: (val) {
            setState(() => _isListening = false);
            // Если прилетела ошибка во время инициализации или прослушивания
            _showMicrophoneErrorDialog();
          },
        );
        
        if (available) {
          setState(() => _isListening = true);
          final activeCtrl = _activeController;
          final previousText = activeCtrl.text;
          
          _speech.listen(
            localeId: 'ru_RU',
            onResult: (val) => setState(() {
              final spacer = previousText.isNotEmpty && !previousText.endsWith(' ') ? ' ' : '';
              activeCtrl.text = previousText + spacer + val.recognizedWords;
              activeCtrl.selection = TextSelection.fromPosition(TextPosition(offset: activeCtrl.text.length));
            }),
          );
        } else {
          // Если инициализация вернула false (нет доступа)
          setState(() => _isListening = false);
          _showMicrophoneErrorDialog();
        }
      } catch (e) {
        // Ловим жесткие системные ошибки (вроде HRESULT: 80045077 на Windows)
        setState(() => _isListening = false);
        _showMicrophoneErrorDialog();
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // --- ДИАЛОГОВОЕ ОКНО ОШИБКИ МИКРОФОНА ---
  void _showMicrophoneErrorDialog() {
    final theme = Theme.of(context);
    final settings = context.read<SettingsProvider>();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Ошибка микрофона 🎙️', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Text(
          Platform.isWindows 
            ? 'Приложению не удалось получить доступ к микрофону.\n\nУбедитесь, что в настройках Windows включен "Доступ к микрофону для классических приложений".'
            : 'Приложению не удалось получить доступ к микрофону. Убедитесь, что вы выдали необходимые разрешения в настройках устройства.',
          style: TextStyle(color: textColor.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          if (Platform.isWindows) // Кнопка только для ПК!
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                final Uri url = Uri.parse('ms-settings:privacy-microphone');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
              child: const Text('Открыть настройки'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.task == null ? 'Новая заметка' : 'Редактирование', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary, size: 28),
            onPressed: () {
            final titleText = _titleController.text.trim();
            final contentText = _contentController.text.trim();

            if (titleText.isNotEmpty) {
              if (widget.task == null) {
                taskProvider.addTask(titleText, contentText, _selectedGroupId, _selectedTagIds);
              } else {
                taskProvider.updateTask(widget.task!['id'], titleText, contentText, _selectedGroupId, _selectedTagIds);
              }
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Добавьте нормальный заголовок'))
              );
            }
          },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [const Color(0xFF0F172A), const Color(0xFF2E1065)] : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  blur: settings.blurRadius,
                  opacity: isDark ? 0.2 : 0.4,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isListening ? 'Слушаю вас...' : 'Голосовой ввод', 
                        style: TextStyle(
                          color: _isListening ? Colors.redAccent : textColor.withValues(alpha: 0.7), 
                          fontWeight: _isListening ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none, 
                          color: _isListening ? Colors.redAccent : theme.colorScheme.primary
                        ),
                        onPressed: _listen,
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView(
                    children: [
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        maxLength: 50,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        decoration: const InputDecoration(hintText: 'Заголовок...', border: InputBorder.none, counterText: '',),
                      ),
                      const Divider(),
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocus,
                        maxLines: null,
                        maxLength: 1000,
                        style: TextStyle(fontSize: 16, color: textColor.withValues(alpha: 0.8)),
                        decoration: const InputDecoration(hintText: 'Описание...', border: InputBorder.none),
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ТЕГИ:', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                          InkWell(onTap: () => _showAddTagDialog(context, taskProvider, textColor), child: Text('+ Новый тег', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: MouseHorizontalScroll(
                        controller: _tagsScrollController,
                        child: ListView(
                          controller: _tagsScrollController, // Передаем контроллер
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          children: taskProvider.tags.map((t) => _buildTagChip(t, textColor)).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text('ГРУППА:', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 40,
                      child: MouseHorizontalScroll(
                        controller: _groupsScrollController,
                        child: ListView(
                          controller: _groupsScrollController, // Передаем контроллер
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          children: [
                            _buildGroupOption('Без группы', null, textColor),
                            ...taskProvider.groups.map((g) => _buildGroupOption(g['name'], g['id'], textColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(Map<String, dynamic> tag, Color textColor) {
    final isSelected = _selectedTagIds.contains(tag['id']);
    final tagColor = Color(int.parse(tag['color_hex'].replaceFirst('#', '0xFF')));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onLongPress: () => _showDeleteTagDialog(context, tag['id'], tag['name']), // Для Android
        onSecondaryTap: () => _showDeleteTagDialog(context, tag['id'], tag['name']), // Для Windows
        child: FilterChip(
          label: Text(tag['name'], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor)),
          selected: isSelected,
          onSelected: (selected) => setState(() => selected ? _selectedTagIds.add(tag['id']) : _selectedTagIds.remove(tag['id'])),
          backgroundColor: Colors.transparent, selectedColor: tagColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: tagColor)),
        ),
      ),
    );
  }

  // диалог для удаления тега
  void _showDeleteTagDialog(BuildContext context, String tagId, String tagName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить тег "$tagName"?'),
        content: const Text('Тег будет удален из всех заметок.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTag(tagId);
              setState(() => _selectedTagIds.remove(tagId)); // Убираем из выбранных
              Navigator.pop(context);
            }, 
            child: const Text('Удалить', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildGroupOption(String name, String? id, Color textColor) {
    final isSelected = _selectedGroupId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(name, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedGroupId = id),
        selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        labelStyle: TextStyle(color: isSelected ? const Color(0xFF8B5CF6) : textColor),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, TaskProvider provider, Color textColor) {
    final controller = TextEditingController();
    final List<String> colors = ['#EF4444', '#F59E0B', '#10B981', '#3B82F6', '#8B5CF6', '#EC4899'];
    String selectedColor = colors[0];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Новый тег', style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, maxLength: 20, decoration: const InputDecoration(hintText: 'Например: Срочно', counterText: '',)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setState(() => selectedColor = c),
                  child: CircleAvatar(radius: 15, backgroundColor: Color(int.parse(c.replaceFirst('#', '0xFF'))), child: selectedColor == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
                )).toList(),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(onPressed: () { final text = controller.text.trim();
              if (text.isNotEmpty) {
                provider.addTag(text, selectedColor); 
                Navigator.pop(context); 
              } }, child: const Text('Создать')),
          ],
        ),
      ),
    );
  }
}