import 'package:shared_preferences/shared_preferences.dart';

/// Hydration storage service
/// Persists water intake data using SharedPreferences
class HydrationStorageService {
  static const String _keyDailyGoal = 'hydration_daily_goal_ml';
  static const String _keyConsumed = 'hydration_consumed_ml';
  static const String _keyGlassTimestamps = 'hydration_glass_timestamps';
  static const String _keyLastReset = 'hydration_last_reset_date';

  /// Save daily goal in milliliters
  Future<void> saveDailyGoal(int goalMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, goalMl);
  }

  /// Load daily goal in milliliters
  Future<int> loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyGoal) ?? 3000; // Default 3L
  }

  /// Save consumed amount in milliliters
  Future<void> saveConsumed(int consumedMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConsumed, consumedMl);
  }

  /// Load consumed amount in milliliters
  Future<int> loadConsumed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConsumed) ?? 0;
  }

  /// Save glass timestamps
  Future<void> saveGlassHistory(List<DateTime> timestamps) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStrings = timestamps.map((t) => t.toIso8601String()).toList();
    await prefs.setStringList(_keyGlassTimestamps, timestampStrings);
  }

  /// Load glass timestamps
  Future<List<DateTime>> loadGlassHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStrings = prefs.getStringList(_keyGlassTimestamps) ?? [];
    return timestampStrings.map((s) => DateTime.parse(s)).toList();
  }

  /// Save last reset date
  Future<void> saveLastResetDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastReset, date.toIso8601String());
  }

  /// Load last reset date
  Future<DateTime> loadLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_keyLastReset);
    return dateString != null ? DateTime.parse(dateString) : DateTime.now();
  }

  /// Check if day has changed and needs reset
  Future<bool> needsReset() async {
    final lastReset = await loadLastResetDate();
    final now = DateTime.now();
    
    final lastResetDay = DateTime(lastReset.year, lastReset.month, lastReset.day);
    final today = DateTime(now.year, now.month, now.day);
    
    return today.isAfter(lastResetDay);
  }

  /// Reset consumed data for new day
  Future<void> resetForNewDay() async {
    await saveConsumed(0);
    await saveGlassHistory([]);
    await saveLastResetDate(DateTime.now());
  }

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDailyGoal);
    await prefs.remove(_keyConsumed);
    await prefs.remove(_keyGlassTimestamps);
    await prefs.remove(_keyLastReset);
  }
}
