import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Duruş Durumu Enum - Düzeltilmiş Mantık
/// Telefon DİK olduğunda (yüksek açı) güvenli, EĞİLDİĞİNDE (düşük açı) tehlikeli
enum PostureStatus {
  safe,    // Yeşil: Açı > 70° (Telefon dik - Güvenli)
  warning, // Sarı: 45° <= Açı <= 70° (Orta eğim - Dikkat)
  danger,  // Kırmızı: Açı < 45° (Telefon aşağı/yatay - Tehlike)
}

/// Duruş Verisi Modeli
/// Sensörden alınan ham veri ve hesaplanan durum bilgisi
class PostureData {
  final double angle;           // Hesaplanan pitch açısı (derece)
  final PostureStatus status;    // Durum seviyesi (safe/warning/danger)
  final DateTime timestamp;      // Veri alım zamanı

  PostureData({
    required this.angle,
    required this.status,
    required this.timestamp,
  });

  /// Açıdan durumu hesapla - Düzeltilmiş Mantık
  /// Yüksek açı (dik telefon) = Güvenli
  /// Düşük açı (eğik telefon) = Tehlikeli
  factory PostureData.fromAngle(double angle) {
    PostureStatus status;
    
    // Telefon dik (70° üstü) - GÜVENLİ
    if (angle > 70) {
      status = PostureStatus.safe;
    }
    // Telefon orta eğim (45-70 arası) - DİKKAT
    else if (angle >= 45) {
      status = PostureStatus.warning;
    }
    // Telefon aşağı/yatay (45° altı) - TEHLİKE
    else {
      status = PostureStatus.danger;
    }

    return PostureData(
      angle: angle,
      status: status,
      timestamp: DateTime.now(),
    );
  }

  /// Durum mesajı (Türkçe)
  String get statusMessage {
    switch (status) {
      case PostureStatus.safe:
        return 'Mükemmel Duruş';
      case PostureStatus.warning:
        return 'Duruşa Dikkat Et';
      case PostureStatus.danger:
        return 'TEHLİKE! Boyun Çok Eğik';
    }
  }

  /// Durum detay açıklaması
  String get statusDetails {
    switch (status) {
      case PostureStatus.safe:
        return 'Boyun sağlığın korunuyor';
      case PostureStatus.warning:
        return 'Telefonu biraz daha yukarı kaldır';
      case PostureStatus.danger:
        return 'Ciddi boyun stresi - Hemen düzelt!';
    }
  }
}

/// Duruş Servisi (BEYİN)
/// Sensör yönetimi ve açı hesaplama mantığı
/// Separation of Concerns: SADECE iş mantığı, UI kodu yok
class PostureService {
  // Singleton instance
  static final PostureService _instance = PostureService._internal();
  factory PostureService() => _instance;
  PostureService._internal();

  // Stream controller - UI'a veri akışı için
  final StreamController<PostureData> _postureStreamController =
      StreamController<PostureData>.broadcast();

  // Sensör dinleyicisi
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Son hesaplanan açı
  double _currentAngle = 0.0;
  double get currentAngle => _currentAngle;

  /// Duruş verileri stream'i (UI'ın dinleyeceği)
  Stream<PostureData> get postureStream => _postureStreamController.stream;

  /// Sensörleri dinlemeye başla
  void startMonitoring() {
    // Eğer zaten dinliyorsa, tekrar başlatma
    if (_accelerometerSubscription != null) {
      return;
    }

    // Accelerometer verilerini dinle
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Pitch açısını hesapla
        double calculatedAngle = _calculatePitchAngle(event);
        
        // Açıyı kaydet
        _currentAngle = calculatedAngle;
        
        // Durum verisini oluştur ve stream'e gönder
        PostureData data = PostureData.fromAngle(calculatedAngle);
        _postureStreamController.add(data);
      },
      onError: (error) {
        // Hata durumunu logla
        print('❌ Sensör hatası: $error');
      },
    );
  }

  /// Sensör dinlemeyi durdur
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// Pitch açısını hesapla (Bilimsel Algoritma)
  /// 
  /// Formül: pitch = atan2(y, sqrt(x² + z²)) × (180/π)
  /// 
  /// Koordinat sistemi:
  /// - X: Telefonun sağ/sol ekseni
  /// - Y: Telefonun ileri/geri ekseni
  /// - Z: Telefonun yukarı/aşağı ekseni (yerçekimi)
  /// 
  /// Pitch: Telefonun öne/arkaya eğilme açısı (derece cinsinden)
  double _calculatePitchAngle(AccelerometerEvent event) {
    // atan2 ile açı hesapla (radyan cinsinden)
    double pitchRadians = math.atan2(
      event.y,
      math.sqrt(event.x * event.x + event.z * event.z),
    );

    // Radyandan dereceye çevir
    double pitchDegrees = pitchRadians * (180 / math.pi);

    // Mutlak değerini al (negatif durumları önle)
    return pitchDegrees.abs();
  }

  /// Servisi temizle (bellek sızıntısını önle)
  void dispose() {
    stopMonitoring();
    _postureStreamController.close();
  }
}
