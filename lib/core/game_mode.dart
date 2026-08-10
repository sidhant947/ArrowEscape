enum GameMode {
  classic,
  zen,
  timeAttack;

  String get label {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.zen:
        return 'Zen';
      case GameMode.timeAttack:
        return 'Time Attack';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return '3 Lives. Procedural puzzles. Can you beat the timer?';
      case GameMode.zen:
        return 'No lives, no timers. Just pure relaxing puzzle solving.';
      case GameMode.timeAttack:
        return 'Race against the clock! Escape arrows to gain extra time.';
    }
  }
}
