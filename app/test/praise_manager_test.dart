import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/logic/services/praise_manager.dart';

void main() {
  // Задаем тестовое имя пользователя
  const testUserName = 'Алекс';

  // group объединяет тесты одного модуля в логический блок
  group('Тестирование PraiseManager (Умный помощник)', () {

    test('getRandomPraise возвращает непустую строку и содержит имя', () {
      // Act (Действие)
      final praise = PraiseManager.getRandomPraise(testUserName);
      
      // Assert (Проверка)
      expect(praise.isNotEmpty, true);
      expect(praise.length > 5, true); // Проверяем, что это не просто 1 буква
      expect(praise.contains(testUserName), true); // Проверяем подстановку имени
    });

    test('getBreakMessage содержит правильное количество задач и имя', () {
      // Arrange (Подготовка)
      const taskCount = 5;

      // Act
      final message = PraiseManager.getBreakMessage(taskCount, testUserName);

      // Assert
      expect(message.contains('5'), true); // Проверяем, что цифра вставилась в текст
      expect(message.contains('перерыв'), true); // Проверяем ключевое слово
      expect(message.contains(testUserName), true); // Проверяем подстановку имени
    });

    test('getEveningSummary возвращает верный текст для 0 задач', () {
      final message = PraiseManager.getEveningSummary(0, testUserName);
      
      expect(message.contains('не закрыто'), true);
      expect(message.contains('завтра'), true);
      expect(message.contains(testUserName), true); // Проверяем подстановку имени
    });

    test('getEveningSummary возвращает верный текст для малого числа задач (1-2)', () {
      final message = PraiseManager.getEveningSummary(2, testUserName);
      
      expect(message.contains('2'), true);
      expect(message.contains('Маленькими шагами'), true);
      expect(message.contains(testUserName), true); // Проверяем подстановку имени
    });

    test('getEveningSummary возвращает верный текст для 3+ задач (Успешный день)', () {
      final message = PraiseManager.getEveningSummary(8, testUserName);
      
      expect(message.contains('8'), true);
      // Заменили проверку на "героизм", так как мы обновили саму фразу
      expect(message.contains('героизм'), true); 
      expect(message.contains(testUserName), true); // Проверяем подстановку имени
    });

  });
}