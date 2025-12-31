import 'dart:io';
import 'package:usage_stats/usage_stats.dart';

/// Uygulama kullanım kaydı modeli
class AppUsageEntry {
  final String packageName;
  final String appName; // Şimdilik packageName, ileride app label olabilir
  final Duration foregroundTime;

  AppUsageEntry({
    required this.packageName,
    required this.appName,
    required this.foregroundTime,
  });
}

/// Ekran süresi özet verisi
class ScreenTimeSummary {
  final Duration totalForegroundTime;
  final List<AppUsageEntry> topApps; // En çok kullanılan 5 uygulama (süreye göre sıralı)
  final bool permissionGranted;
  final bool supported;

  ScreenTimeSummary({
    required this.totalForegroundTime,
    required this.topApps,
    required this.permissionGranted,
    required this.supported,
  });

  /// Platform desteklenmiyor (iOS vs.)
  static ScreenTimeSummary unsupported() => ScreenTimeSummary(
        totalForegroundTime: Duration.zero,
        topApps: const [],
        permissionGranted: false,
        supported: false,
      );
}

/// Ekran süresi uyarı eşiği (dakika)
/// V1: Sadece constant, bildirim yok
const int kScreenTimeWarningThresholdMinutes = 30;

/// Ekran süresi takip servisi
/// Android'de usage_stats kullanarak günlük ekran kullanımını izler
class ScreenTimeService {
  /// Usage permission kontrolü
  Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Usage permission iste (Settings açılır)
  Future<void> requestUsagePermission() async {
    if (!Platform.isAndroid) return;
    try {
      await UsageStats.grantUsagePermission();
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Bugünün kullanım özetini getir
  Future<ScreenTimeSummary> getTodayUsageSummary() async {
    // Platform kontrolü
    if (!Platform.isAndroid) {
      return ScreenTimeSummary.unsupported();
    }

    // İzin kontrolü
    final hasPermission = await hasUsagePermission();
    if (!hasPermission) {
      return ScreenTimeSummary(
        totalForegroundTime: Duration.zero,
        topApps: const [],
        permissionGranted: false,
        supported: true,
      );
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Bugünkü usage stats'ları çek
      final stats = await UsageStats.queryUsageStats(startOfDay, now);

      // Package bazında toplam süreyi hesapla
      final Map<String, Duration> durationsByPackage = {};

      for (final s in stats) {
        final ms = int.tryParse(s.totalTimeInForeground ?? '0') ?? 0;
        if (ms <= 0) continue; // 0ms olan uygulamaları filtrele

        final duration = Duration(milliseconds: ms);
        final pkg = s.packageName ?? '';
        if (pkg.isEmpty) continue;

        durationsByPackage[pkg] =
            (durationsByPackage[pkg] ?? Duration.zero) + duration;
      }

      // Toplam ekran süresi
      final total = durationsByPackage.values.fold<Duration>(
        Duration.zero,
        (prev, d) => prev + d,
      );

      // AppUsageEntry listesi oluştur
      final entries = durationsByPackage.entries
          .map((e) => AppUsageEntry(
                packageName: e.key,
                appName: e.key, // V1: packageName kullan, ileride app label
                foregroundTime: e.value,
              ))
          .toList();

      // Süreye göre azalan sırada sırala, ilk 5'i al
      entries.sort((a, b) => b.foregroundTime.compareTo(a.foregroundTime));
      final topApps = entries.take(5).toList();

      return ScreenTimeSummary(
        totalForegroundTime: total,
        topApps: topApps,
        permissionGranted: true,
        supported: true,
      );
    } catch (e) {
      // Hata durumunda boş özet döndür
      return ScreenTimeSummary(
        totalForegroundTime: Duration.zero,
        topApps: const [],
        permissionGranted: true, // İzin var ama veri okunamadı
        supported: true,
      );
    }
  }

  /// Haftalık (son 7 gün) kullanım özetini getir
  Future<ScreenTimeSummary> getWeekUsageSummary() async {
    // Platform kontrolü
    if (!Platform.isAndroid) {
      return ScreenTimeSummary.unsupported();
    }

    // İzin kontrolü
    final hasPermission = await hasUsagePermission();
    if (!hasPermission) {
      return ScreenTimeSummary(
        totalForegroundTime: Duration.zero,
        topApps: const [],
        permissionGranted: false,
        supported: true,
      );
    }

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(const Duration(days: 7));

      // Son 7 günün usage stats'larını çek
      final stats = await UsageStats.queryUsageStats(startOfWeek, now);

      // Package bazında toplam süreyi hesapla
      final Map<String, Duration> durationsByPackage = {};

      for (final s in stats) {
        final ms = int.tryParse(s.totalTimeInForeground ?? '0') ?? 0;
        if (ms <= 0) continue;

        final duration = Duration(milliseconds: ms);
        final pkg = s.packageName ?? '';
        if (pkg.isEmpty) continue;

        durationsByPackage[pkg] =
            (durationsByPackage[pkg] ?? Duration.zero) + duration;
      }

      // Toplam ekran süresi
      final total = durationsByPackage.values.fold<Duration>(
        Duration.zero,
        (prev, d) => prev + d,
      );

      // AppUsageEntry listesi oluştur
      final entries = durationsByPackage.entries
          .map((e) => AppUsageEntry(
                packageName: e.key,
                appName: e.key,
                foregroundTime: e.value,
              ))
          .toList();

      // Süreye göre azalan sırada sırala, ilk 10'u al (hafta için daha fazla)
      entries.sort((a, b) => b.foregroundTime.compareTo(a.foregroundTime));
      final topApps = entries.take(10).toList();

      return ScreenTimeSummary(
        totalForegroundTime: total,
        topApps: topApps,
        permissionGranted: true,
        supported: true,
      );
    } catch (e) {
      // Hata durumunda boş özet döndür
      return ScreenTimeSummary(
        totalForegroundTime: Duration.zero,
        topApps: const [],
        permissionGranted: true,
        supported: true,
      );
    }
  }
}
