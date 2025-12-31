/// Water intake state model
/// Tracks daily hydration data
class WaterIntakeState {
  final int dailyGoalMl;
  final int consumedMl;
  final List<DateTime> glassHistory;
  final DateTime lastResetDate;

  WaterIntakeState({
    required this.dailyGoalMl,
    required this.consumedMl,
    required this.glassHistory,
    required this.lastResetDate,
  });

  /// Create initial state with 3L default goal
  factory WaterIntakeState.initial() {
    return WaterIntakeState(
      dailyGoalMl: 3000, // 3.0 Liters
      consumedMl: 0,
      glassHistory: [],
      lastResetDate: DateTime.now(),
    );
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (dailyGoalMl == 0) return 0.0;
    return (consumedMl / dailyGoalMl).clamp(0.0, 1.0);
  }

  /// Get remaining amount in milliliters
  int get remainingMl {
    final remaining = dailyGoalMl - consumedMl;
    return remaining > 0 ? remaining : 0;
  }

  /// Convert ml to liters for display
  double mlToLiters(int ml) => ml / 1000.0;

  /// Daily goal in liters
  double get dailyGoalLiters => mlToLiters(dailyGoalMl);

  /// Consumed amount in liters
  double get consumedLiters => mlToLiters(consumedMl);

  /// Remaining amount in liters
  double get remainingLiters => mlToLiters(remainingMl);

  /// Number of filled glasses (200ml each)
  int get filledGlassCount => (consumedMl / 200).floor();

  /// Copy with updated values
  WaterIntakeState copyWith({
    int? dailyGoalMl,
    int? consumedMl,
    List<DateTime>? glassHistory,
    DateTime? lastResetDate,
  }) {
    return WaterIntakeState(
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      consumedMl: consumedMl ?? this.consumedMl,
      glassHistory: glassHistory ?? this.glassHistory,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
