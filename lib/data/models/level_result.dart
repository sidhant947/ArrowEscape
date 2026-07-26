class LevelResult {
  final int levelNumber;
  final int stars;
  final int livesLost;
  final bool completed;
  final DateTime completedAt;

  LevelResult({
    required this.levelNumber,
    required this.stars,
    required this.livesLost,
    required this.completed,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'stars': stars,
    'livesLost': livesLost,
    'completed': completed,
    'completedAt': completedAt.toIso8601String(),
  };

  factory LevelResult.fromJson(Map<String, dynamic> json) => LevelResult(
    levelNumber: json['levelNumber'] as int,
    stars: json['stars'] as int,
    livesLost: json['livesLost'] as int,
    completed: json['completed'] as bool,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}