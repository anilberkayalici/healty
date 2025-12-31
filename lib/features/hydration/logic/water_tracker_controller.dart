import 'package:flutter/material.dart';
import '../models/water_intake_state.dart';
import '../services/hydration_storage_service.dart';

/// Water tracker controller
/// Manages hydration state and business logic
class WaterTrackerController extends ChangeNotifier {
  final HydrationStorageService _storage;
  
  WaterIntakeState _state = WaterIntakeState.initial();
  WaterIntakeState get state => _state;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  WaterTrackerController({HydrationStorageService? storage})
      : _storage = storage ?? HydrationStorageService() {
    _init();
  }

  /// Initialize - load data and check for day reset
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if we need to reset for a new day
      if (await _storage.needsReset()) {
        await _storage.resetForNewDay();
      }

      // Load persisted data
      final goalMl = await _storage.loadDailyGoal();
      final consumedMl = await _storage.loadConsumed();
      final glassHistory = await _storage.loadGlassHistory();
      final lastResetDate = await _storage.loadLastResetDate();

      _state = WaterIntakeState(
        dailyGoalMl: goalMl,
        consumedMl: consumedMl,
        glassHistory: glassHistory,
        lastResetDate: lastResetDate,
      );
    } catch (e) {
      // On error, use initial state
      _state = WaterIntakeState.initial();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a 200ml glass of water
  Future<void> addWater() async {
    // Don't add water if already at or above goal
    if (_state.consumedMl >= _state.dailyGoalMl) {
      return;
    }

    final newConsumed = _state.consumedMl + 200;
    final newHistory = [..._state.glassHistory, DateTime.now()];

    _state = _state.copyWith(
      consumedMl: newConsumed,
      glassHistory: newHistory,
    );

    await _storage.saveConsumed(newConsumed);
    await _storage.saveGlassHistory(newHistory);

    notifyListeners();
  }

  /// Remove last added glass (undo)
  Future<void> removeWater() async {
    if (_state.consumedMl <= 0 || _state.glassHistory.isEmpty) {
      return;
    }

    final newConsumed = _state.consumedMl - 200;
    final newHistory = List<DateTime>.from(_state.glassHistory)..removeLast();

    _state = _state.copyWith(
      consumedMl: newConsumed,
      glassHistory: newHistory,
    );

    await _storage.saveConsumed(newConsumed);
    await _storage.saveGlassHistory(newHistory);

    notifyListeners();
  }

  /// Update daily goal (in liters)
  Future<void> updateDailyGoal(double goalLiters) async {
    // Clamp goal between 1.0 and 5.0 liters
    final clampedGoal = goalLiters.clamp(1.0, 5.0);
    final goalMl = (clampedGoal * 1000).toInt();
    
    _state = _state.copyWith(dailyGoalMl: goalMl);

    await _storage.saveDailyGoal(goalMl);

    notifyListeners();
  }

  /// Get motivational message based on progress
  String getMotivationalMessage() {
    final progress = _state.progressPercentage;
    final remaining = _state.remainingMl;

    if (progress >= 1.0) {
      return "Harika! Günlük hedefini tamamladın! 🎉";
    } else if (progress >= 0.75) {
      return "Çok iyi gidiyorsun! Hedefe çok yakınsın 💪";
    } else if (progress >= 0.5) {
      return "Yarıdan fazlasını tamamladın! Devam et 💧";
    } else if (progress >= 0.25) {
      return "İyi başlangıç! Bir bardak daha içersen çok iyi olur 🙂";
    } else if (remaining > 0) {
      return "Harika bir gün! Su içmeyi unutma 🌿";
    } else {
      return "Hidrasyon için ilk adımını at! 💙";
    }
  }

  /// Refresh data (for manual refresh)
  Future<void> refresh() async {
    await _init();
  }
}
