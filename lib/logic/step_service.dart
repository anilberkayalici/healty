import 'dart:async';
import 'dart:convert';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın her yerinden erişilebilen adım sayar servisi.
/// Pedometer'dan gelen veriyi dinler ve bugünkü adım sayısını hesaplar.
/// 
/// Profesyonel cadence filtresi ile telefon sallama gibi spike'ları engeller.
/// SharedPreferences ile günlük adımları kalıcı saklar.
class StepService {
  // 🔒 Singleton pattern
  StepService._internal();
  static final StepService _instance = StepService._internal();
  factory StepService() => _instance;

  // UI'nin dinleyeceği stream
  final StreamController<int> _stepsController =
      StreamController<int>.broadcast();

  Stream<int> get stepCountStream => _stepsController.stream;

  StreamSubscription<StepCount>? _stepSubscription;

  // === PERSISTENCE STATE ===
  
  /// Günlük adım cache'i (kalıcı saklanıyor)
  Map<DateTime, int> _dailyStepsCache = {};

  // === CADENCE FILTER STATE ===
  
  /// Ham sensör verisi (telefon reboot'tan beri toplam)
  int? _lastRawSteps;
  
  /// Son event zamanı (cadence hesabı için)
  DateTime? _lastEventTime;
  
  /// Filtrelenmiş adım sayısı (lifetime total)
  int _filteredSteps = 0;
  
  /// Sensör reset olduğunda offset
  int _sensorBaseOffset = 0;
  
  /// Bilimsel dayanaklı maksimum kadans (adım/sn)
  /// 
  /// Açıklama:
  /// - Orta şiddette yürüyüş ≈ 105–120 adım/dk (1.7–2.0 adım/sn)
  /// - Koşu genelde 150–180 adım/dk (2.5–3.0 adım/sn)
  /// - 3.5 adım/sn üzerini (210 adım/dk) şüpheli kabul ediyoruz
  /// 
  /// Kaynaklar: Tudor-Locke yürüyüş kadansı çalışmaları, koşu kadansı rehberleri
  static const double _kMaxCadenceStepsPerSecond = 3.5;

  // === GÜNLÜK RESET STATE ===
  
  /// Gün başlangıcındaki filtrelenmiş adım sayısı
  int _dayStartFilteredSteps = 0;
  
  /// Şu anki tarih (gün değişimi kontrolü için)
  DateTime _currentDate = DateTime.now();

  // Bilimsel literatüre göre yetişkinler için 7k-9k arası sağlık açısından optimal aralık.
  int dailyGoal = 7000;

  bool _initialized = false;

  /// Uygulama açıldığında bir kere çağrılmalı.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) Kalıcı verileri yükle
    await _loadPersistedSteps();
    
    // 2) Bugünün adımlarını cache'ten al
    final today = _dateOnly(DateTime.now());
    _filteredSteps = _dailyStepsCache[today] ?? 0;
    _dayStartFilteredSteps = 0;
    _currentDate = DateTime.now();

    // 3) İzin iste
    final granted = await _requestActivityPermission();
    if (!granted) {
      // İzin yoksa mevcut cache değerini yayınla
      _stepsController.add(getTodayStepsSync());
      return;
    }

    // 4) Pedometer stream'ine abone ol
    _stepSubscription = Pedometer.stepCountStream.listen(
      _handleRawStepEvent,
      onError: _onStepError,
      cancelOnError: false,
    );
  }

  // === PERSISTENCE METHODS ===

  /// Tarihi ISO string'e çevir (YYYY-MM-DD)
  String _dateKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// DateTime'ı sadece gün olarak al (saat/dk/sn sıfırla)
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Kalıcı verileri yükle (SharedPreferences)
  Future<void> _loadPersistedSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawMap = prefs.getString("daily_steps_json");
      
      if (rawMap != null) {
        final Map<String, dynamic> decoded = jsonDecode(rawMap);
        _dailyStepsCache = decoded.map((k, v) =>
          MapEntry(DateTime.parse(k), v as int)
        );
      }
    } catch (e) {
      // Hata durumunda boş cache ile devam et
      _dailyStepsCache = {};
    }
  }

  /// Günlük adımları kalıcı kaydet (SharedPreferences)
  Future<void> _savePersistedSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> dailyStepsJson = _dailyStepsCache.map(
        (k, v) => MapEntry(_dateKey(k), v)
      );
      await prefs.setString("daily_steps_json", jsonEncode(dailyStepsJson));
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // === PERMISSION ===

  Future<bool> _requestActivityPermission() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) return true;
    return false;
  }

  // === CADENCE FILTER ===

  /// Ham sensör event'ini cadence filtresine yönlendir
  void _handleRawStepEvent(StepCount event) {
    _applyCadenceFilter(event.steps, event.timeStamp);
  }

  /// Cadence tabanlı spike filtresi + persistence
  void _applyCadenceFilter(int rawSteps, DateTime timeStamp) {
    final now = timeStamp;

    // Gün değişimi kontrolü
    if (!_isSameDate(now, _currentDate)) {
      _currentDate = now;
      _dayStartFilteredSteps = _filteredSteps;
    }

    // İlk event: state'i başlat
    if (_lastRawSteps == null || _lastEventTime == null) {
      _lastRawSteps = rawSteps;
      _lastEventTime = now;
      _sensorBaseOffset = rawSteps;
      
      // İlk event'te cache'ten gelen değeri koru
      final today = _dateOnly(now);
      _filteredSteps = _dailyStepsCache[today] ?? 0;
      _dayStartFilteredSteps = 0;
      
      _emitFilteredSteps();
      return;
    }

    int deltaRaw = rawSteps - _lastRawSteps!;

    // Sensör reset'i (telefon reboot, sensor restart)
    if (deltaRaw < 0) {
      _sensorBaseOffset = rawSteps;
      _lastRawSteps = rawSteps;
      _lastEventTime = now;
      _emitFilteredSteps();
      return;
    }

    final dtSeconds = now.difference(_lastEventTime!).inMilliseconds / 1000.0;

    _lastRawSteps = rawSteps;
    _lastEventTime = now;

    // Zaman farkı yoksa veya artış yoksa skip
    if (dtSeconds <= 0 || deltaRaw <= 0) {
      _emitFilteredSteps();
      return;
    }

    // === CADENCE FILTER CORE ===
    
    // Anlık kadans (adım/sn)
    final cadence = deltaRaw / dtSeconds;

    int allowedDelta = deltaRaw;

    if (cadence > _kMaxCadenceStepsPerSecond) {
      // Spike detected!
      final maxReasonable = (_kMaxCadenceStepsPerSecond * dtSeconds).round();
      allowedDelta = maxReasonable.clamp(0, deltaRaw);
    }

    // Filtrelenmiş adım sayısını güncelle
    _filteredSteps += allowedDelta;
    if (_filteredSteps < 0) _filteredSteps = 0;

    // === PERSISTENCE: Cache'e kaydet ===
    final today = _dateOnly(now);
    _dailyStepsCache[today] = _filteredSteps;
    
    // Asenkron kaydet (fire-and-forget)
    _savePersistedSteps();

    _emitFilteredSteps();
  }

  /// Filtrelenmiş adım sayısını stream'e gönder
  void _emitFilteredSteps() {
    final todaySteps = _filteredSteps - _dayStartFilteredSteps;
    final safeTodaySteps = todaySteps < 0 ? 0 : todaySteps;
    _stepsController.add(safeTodaySteps);
  }

  void _onStepError(error) {
    _stepsController.addError(error);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // === PUBLIC API ===

  /// Bugünkü filtrelenmiş adım sayısını döndür (senkron)
  int getTodayStepsSync() {
    final todaySteps = _filteredSteps - _dayStartFilteredSteps;
    return todaySteps < 0 ? 0 : todaySteps;
  }

  /// Belirli bir gün için adım sayısını döndür (haftalık/aylık servisler için)
  int getStepsForDate(DateTime date) {
    final day = _dateOnly(date);
    return _dailyStepsCache[day] ?? 0;
  }

  /// Tüm günlük adım cache'ini döndür (immutable)
  Map<DateTime, int> getAllDailySteps() => Map.unmodifiable(_dailyStepsCache);

  double get progressPercent {
    if (dailyGoal <= 0) return 0;
    final p = getTodayStepsSync() / dailyGoal;
    return p.clamp(0.0, 2.0);
  }

  Future<void> dispose() async {
    await _stepSubscription?.cancel();
    await _stepsController.close();
  }
}
