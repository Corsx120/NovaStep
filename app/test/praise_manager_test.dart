import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/logic/services/praise_manager.dart';

void main() {
  // group объединяет тесты одного модуля в логический блок
  group('Тестирование PraiseManager (Умный помощник)', () {

    test('getRandomPraise возвращает непустую строку (похвала существует)', () {
      // Act (Действие)
      final praise = PraiseManager.getRandomPraise();
      
      // Assert (Проверка)
      expect(praise.isNotEmpty, true);
      expect(praise.length > 5, true); // Проверяем, что это не просто 1 буква
    });

    test('getBreakMessage содержит правильное количество задач', () {
      // Arrange (Подготовка)
      const taskCount = 5;

      // Act
      final message = PraiseManager.getBreakMessage(taskCount);

      // Assert
      expect(message.contains('5'), true); // Проверяем, что цифра вставилась в текст
      expect(message.contains('перерыв'), true); // Проверяем ключевое слово
    });

    test('getEveningSummary возвращает верный текст для 0 задач', () {
      final message = PraiseManager.getEveningSummary(0);
      
      expect(message.contains('не закрыто'), true);
      expect(message.contains('завтра'), true);
    });

    test('getEveningSummary возвращает верный текст для малого числа задач (1-2)', () {
      final message = PraiseManager.getEveningSummary(2);
      
      expect(message.contains('2'), true);
      expect(message.contains('Маленькими шагами'), true);
    });

    test('getEveningSummary возвращает верный текст для 3+ задач (Успешный день)', () {
      final message = PraiseManager.getEveningSummary(8);
      
      expect(message.contains('8'), true);
      expect(message.contains('герой дня'), true);
    });

  });
}