import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/settings_provider.dart';
import '../widgets/glass_container.dart';

class PinLockScreen extends StatefulWidget {
  final Widget child; // Основное приложение
  const PinLockScreen({super.key, required this.child});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredCode = '';
  bool _isUnlocked = false;

  void _onNumberPress(String number) {
    if (_enteredCode.length < 4) {
      setState(() => _enteredCode += number);
    }
    if (_enteredCode.length == 4) {
      final correctPin = context.read<SettingsProvider>().pinCode;
      if (_enteredCode == correctPin) {
        setState(() => _isUnlocked = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный пин-код'), duration: Duration(seconds: 1))
        );
        setState(() => _enteredCode = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    // Если пин-код выключен или уже введен верно - показываем приложение
    if (!settings.isPinEnabled || _isUnlocked) {
      return widget.child;
    }

    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [const Color(0xFF0F172A), const Color(0xFF2E1065)] : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: textColor.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text('Введите PIN-код', style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Индикаторы точек
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => Container(
                  margin: const EdgeInsets.all(8),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredCode.length ? const Color(0xFF8B5CF6) : textColor.withValues(alpha: 0.2),
                  ),
                )),
              ),
              const SizedBox(height: 40),
              // Клавиатура
              SizedBox(
                width: 280,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) return const SizedBox(); // Пустое место
                    if (index == 10) return _buildNumButton('0');
                    if (index == 11) return IconButton(onPressed: () => setState(() => _enteredCode = ''), icon: Icon(Icons.backspace_outlined, color: textColor));
                    return _buildNumButton('${index + 1}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumButton(String label) {
    return InkWell(
      onTap: () => _onNumberPress(label),
      borderRadius: BorderRadius.circular(40),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(40),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      ),
    );
  }
}