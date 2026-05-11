import 'dart:math';

class PraiseManager {
  static String getRandomPraise(String userName) {
    // Список теперь внутри метода, чтобы подставлять userName
    final List<String> phrases = [
      "Ого, $userName! Просто машина продуктивности! 🚀",
      "Минус одна задача - плюс сто к уверенности, $userName! 💪",
      "NovaStep гордится тобой, $userName! Продолжай в том же духе. ✨",
      "Это было мощно! Пора заварить чаек, $userName? ☕",
      "Ты на шаг ближе к своей цели, $userName. Так держать! 🎯",
      "Еще одна победа в копилку! Сегодня твой день, $userName. 🌟",
      "Твоя продуктивность просто зашкаливает, $userName! 🔥",
      "Сделано! Отличная работа, $userName! 😉",
      "Маленький шаг для тебя, $userName, огромный шаг для успеха! 🛰️",
      "Задачи трепещут перед тобой, $userName! ⚔️",
    ];
    return phrases[Random().nextInt(phrases.length)];
  }

  // Фраза для перерыва
  static String getBreakMessage(int count, String userName) {
    return "Ого, $userName, уже $count задач за сегодня! 🤯 Пора сделать перерыв на 10-15 минут, чтобы перезагрузиться. Заслуженный отдых! 🍵";
  }

  // Фраза для вечернего итога
  static String getEveningSummary(int count, String userName) {
    if (count == 0) return "Сегодня задач не закрыто, но завтра — новый день и новые возможности, $userName! Отдыхай! 🌙";
    if (count < 3) return "Сегодня закрыто $count задач. Маленькими шагами к большой цели! Доброй ночи, $userName! 😴";
    return "Вау, $userName! Сегодня выполнено целых $count задач! Настоящий героизм. Теперь время заслуженного отдыха! 🏆🌙";
  }
}