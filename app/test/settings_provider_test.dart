import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager/logic/providers/settings_provider.dart';

void main() {
  // Перед запуском тестов мы создаем "виртуальную" память, 
  // чтобы приложению было куда сохранять данные во время проверки
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Тестирование SettingsProvider (Настройки и Безопасность)', () {
    
    test('Дефолтные значения заданы верно при первом запуске', () {
      final settings = SettingsProvider();
      
      // Проверяем базовые вещи
      expect(settings.isDarkMode, true);
      expect(settings.isPraiseEnabled, true);
      
      // Проверяем безопасность по умолчанию
      expect(settings.isPinEnabled, false);
      expect(settings.pinCode, '1234');
    });

    test('Изменение ПИН-кода корректно сохраняется в состояние', () async {
      final settings = SettingsProvider();
      
      // Имитируем ввод нового пароля пользователем
      await settings.updatePinCode('9999');
      
      // Проверяем, что пароль обновился
      expect(settings.pinCode, '9999');
    });

    test('Переключение темной темы работает корректно', () async {
      final settings = SettingsProvider();
      
      // Выключаем темную тему
      await settings.toggleTheme(false);
      
      // Проверяем, что теперь светлая
      expect(settings.isDarkMode, false);
    });

  });
}