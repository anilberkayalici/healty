import '../logic/step_service.dart';

/// Günlük adım kaydı modeli
class DailyStepEntry {
  final DateTime date;
  final int steps;

  DailyStepEntry({required this.date, required this.steps});
}

/// Haftalık adım verisi (7 gün: Pazartesi-Pazar)
class WeeklyStepsData {
  final List<DailyStepEntry> days;

  WeeklyStepsData(this.days);

  /// Bugüne kadar tamamlanmış günler (gelecek günleri hariç tutar)
  List<DailyStepEntry> get _completedDays {
    final DateTime today = DateTime.now();
    return days.where((d) => !d.date.isAfter(today)).toList();
  }

  /// Toplam adım sayısı (SADECE bugüne kadar)
  /// Gelecek günler hesaba katılmaz
  int get totalSteps {
    return _completedDays.fold(0, (sum, d) => sum + d.steps);
  }

  /// Ortalama adım sayısı (SADECE bugüne kadar)
  /// Gelecek günler hesaba katılmaz
  double get averageSteps {
    final completed = _completedDays;
    if (completed.isEmpty) return 0;
    final total = completed.fold(0, (sum, d) => sum + d.steps);
    return total / completed.length;
  }

  /// Maksimum adım sayısı (grafik normalizasyonu için tüm günler)
  int get maxSteps {
    if (days.isEmpty) return 0;
    return days.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
  }
}

/// Bilimsel kalori hesabı için sabitler
const double kBaseKcalPerStep = 0.04;
const double kReferenceWeightKg = 70.0;

/// Haftalık adım servisi
/// StepService ile entegre çalışır, kalıcı cache'ten geçmiş verisi alır
class WeeklyStepsService {
  final StepService stepService;

  WeeklyStepsService(this.stepService);

  /// Mevcut haftanın verilerini getir
  /// StepService cache'inden gerçek geçmiş veriler
  WeeklyStepsData getCurrentWeekData() {
    final DateTime now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Haftanın başlangıcı (Pazartesi)
    final startOfWeek = _getStartOfWeek(now);

    final List<DailyStepEntry> days = [];
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      int steps;
      if (dateOnly.isAfter(today)) {
        // GELECEK GÜNLER: 0 steps
        steps = 0;
      } else {
        // BUGÜN + GEÇMİŞ: StepService cache'inden al
        steps = stepService.getStepsForDate(dateOnly);
      }

      days.add(DailyStepEntry(date: dateOnly, steps: steps));
    }

    return WeeklyStepsData(days);
  }

  /// Haftanın başlangıcını (Pazartesi) hesapla
  DateTime _getStartOfWeek(DateTime date) {
    final daysSinceMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysSinceMonday));
  }

  /// Adımdan mesafe tahmini (km)
  double estimateDistanceKm(int steps) {
    const double stepLengthMeters = 0.78;
    return steps * stepLengthMeters / 1000.0;
  }

  /// Adımdan kalori tahmini (kcal) - BİLİMSEL FORMÜL
  double estimateCaloriesFromSteps(int steps, {double? weightKg}) {
    if (steps <= 0) return 0;

    final double effectiveWeightKg = weightKg ?? kReferenceWeightKg;
    final double scaleFactor = effectiveWeightKg / kReferenceWeightKg;
    final double kcalPerStep = kBaseKcalPerStep * scaleFactor;

    return steps * kcalPerStep;
  }
}
