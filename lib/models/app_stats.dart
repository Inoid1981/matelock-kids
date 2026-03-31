import '../utils/translations.dart';

class AppStats {
  int totalAttempts;
  int correctAnswers;
  int wrongAnswers;
  int wrongAdditions;
  int wrongSubtractions;
  int wrongMultiplications;
  int wrongDivisions;
  int stars;
  int streak;
  int bestStreak;
  int difficultyLevel;
  List<String> unlockedAvatars;
  List<String> achievements;

  AppStats({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.wrongAdditions = 0,
    this.wrongSubtractions = 0,
    this.wrongMultiplications = 0,
    this.wrongDivisions = 0,
    this.stars = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.difficultyLevel = 1,
    List<String>? unlockedAvatars,
    List<String>? achievements,
  })  : unlockedAvatars = unlockedAvatars ?? ['bear'],
        achievements = achievements ?? [];

  double get successRate {
    if (totalAttempts == 0) return 0;
    return (correctAnswers / totalAttempts) * 100;
  }

  String mostFailedOperation(AppLanguage language) {
    final failures = {
      tr(language, 'additions'): wrongAdditions,
      tr(language, 'subtractions'): wrongSubtractions,
      tr(language, 'multiplications'): wrongMultiplications,
      tr(language, 'divisions'): wrongDivisions,
    };

    String result = tr(language, 'none');
    int maxValue = 0;

    failures.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
        result = key;
      }
    });

    if (maxValue == 0) return tr(language, 'none');
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAttempts': totalAttempts,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'wrongAdditions': wrongAdditions,
      'wrongSubtractions': wrongSubtractions,
      'wrongMultiplications': wrongMultiplications,
      'wrongDivisions': wrongDivisions,
      'stars': stars,
      'streak': streak,
      'bestStreak': bestStreak,
      'difficultyLevel': difficultyLevel,
      'unlockedAvatars': unlockedAvatars,
      'achievements': achievements,
    };
  }

  factory AppStats.fromMap(Map<String, dynamic> map) {
    return AppStats(
      totalAttempts: map['totalAttempts'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      wrongAdditions: map['wrongAdditions'] ?? 0,
      wrongSubtractions: map['wrongSubtractions'] ?? 0,
      wrongMultiplications: map['wrongMultiplications'] ?? 0,
      wrongDivisions: map['wrongDivisions'] ?? 0,
      stars: map['stars'] ?? 0,
      streak: map['streak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      difficultyLevel: map['difficultyLevel'] ?? 1,
      unlockedAvatars:
          List<String>.from(map['unlockedAvatars'] ?? const ['bear']),
      achievements: List<String>.from(map['achievements'] ?? const []),
    );
  }
}