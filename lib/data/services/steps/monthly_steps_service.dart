import 'step_service.dart';
import 'weekly_steps_service.dart'; // DailyStepEntry'yi kullanmak için

/// Aylık adım verisi (o ayın günleri)
class MonthlyStepsData {
  final List<DailyStepEntry> days;

  MonthlyStepsData(this.days);

  /// Bugüne kadar tamamlanmış günler (gelecek günleri hariç tutar)
  List<DailyStepEntry> get _completedDays {
    final DateTime today = DateTime.now();
    return days.where((d) => !d.date.isAfter(today)).toList();
  }

  /// Toplam adım sayısı (SADECE bugüne kadar)
  int get totalSteps {
    return _completedDays.fold(0, (sum, d) => sum + d.steps);
  }

  /// Ortalama adım sayısı (SADECE bugüne kadar)
  double get averageSteps {
    final completed = _completedDays;
    if (completed.isEmpty) return 0;
    final total = completed.fold(0, (sum, d) => sum + d.steps);
    return total / completed.length;
  }

  /// Maksimum adım sayısı (grafik normalizasyonu için)
  int get maxSteps {
    if (days.isEmpty) return 0;
    return days.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
  }

  /// Aylık 4 haftalık toplam (Month modunda 4 bar için)
  /// W1: 1-7. günler, W2: 8-14, W3: 15-21, W4: 22-ay sonu
  List<int> get weeklyTotals {
    if (days.isEmpty) return [0, 0, 0, 0];
    
    int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
    
    for (var day in days) {
      final dayOfMonth = day.date.day;
      if (dayOfMonth <= 7) {
        w1 += day.steps;
      } else if (dayOfMonth <= 14) {
        w2 += day.steps;
      } else if (dayOfMonth <= 21) {
        w3 += day.steps;
      } else {
        w4 += day.steps;
      }
    }
    
    return [w1, w2, w3, w4];
  }

  /// Haftalık maksimum (4 bar normalizasyonu için)
  int get maxWeeklyTotal {
    final totals = weeklyTotals;
    if (totals.isEmpty) return 0;
    return totals.reduce((a, b) => a > b ? a : b);
  }
}

/// Aylık adım servisi
class MonthlyStepsService {
  final StepService stepService;

  MonthlyStepsService(this.stepService);

  /// Mevcut ayın verilerini getir
  /// StepService cache'inden gerçek geçmiş veriler
  MonthlyStepsData getCurrentMonthData() {
    final DateTime now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // Sonraki ayın 1. günü
    final nextMonth = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    
    // Bu aydaki gün sayısı
    final daysInMonth = nextMonth.difference(firstDayOfMonth).inDays;

    final List<DailyStepEntry> days = [];

    for (int i = 0; i < daysInMonth; i++) {
      final date = firstDayOfMonth.add(Duration(days: i));
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

    return MonthlyStepsData(days);
  }
}
