# PostureGuard 🛡️

Boyun sağlığını koruyan akıllı mobil uygulama - Tech Neck önleyici

## 📋 Proje Vizyonu
İnsanların telefona bakarken boyunlarını 60 dereceden fazla eğmelerini engelleyen kritik sağlık uygulaması.

## 🏗️ Proje Yapısı (Modüler Dizin Sistemi)

```
posture_guard/
├── lib/
│   ├── main.dart              # Ana uygulama giriş noktası
│   ├── screens/               # UI ekranları
│   ├── services/              # Sensör servisleri ve arka plan işlemleri
│   ├── database/              # SQLite veritabanı işlemleri
│   ├── models/                # Veri modelleri (posture_log, vb.)
│   └── utils/                 # Yardımcı fonksiyonlar ve sabitler
└── pubspec.yaml               # Paket bağımlılıkları
```

## 📦 Kullanılan Paketler

1. **sensors_plus** (^4.0.2) - Accelerometer ve Gyroscope yönetimi
2. **sqflite** (^2.3.0) - Yerel SQL veritabanı
3. **path** (^1.8.3) - Dosya yolu yönetimi
4. **flutter_background_service** (^5.0.5) - Arka plan servisi altyapısı

## 🎯 Mevcut Durum (Adım 1 - İskelet Kod)

✅ **Tamamlanan Özellikler:**
- Modüler proje yapısı kuruldu
- Gerekli tüm paketler eklendi
- Sensör okuma sistemi hazır
- Pitch açısı hesaplama algoritması çalışıyor
- Dinamik UI geri bildirimi:
  - Açı < 60° → Yeşil arkaplan
  - Açı ≥ 60° → Kırmızı arkaplan
- Anlık açı değeri büyük yazı ile gösteriliyor

## 🔜 Sonraki Adımlar
- Blur efekti (BackdropFilter) implementasyonu
- SQLite veritabanı kurulumu (posture_logs tablosu)
- Arka plan servisi entegrasyonu
- Veri loglama sistemi

## 🚀 Kurulum ve Çalıştırma

```bash
# Paketleri yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

## 💡 Teknik Notlar

### Pitch Açısı Hesaplama
```dart
pitch = atan2(y, sqrt(x² + z²)) × (180/π)
```
- **x**: Yatay eksen (sağ/sol)
- **y**: Derinlik ekseni (ileri/geri)  
- **z**: Dikey eksen (yukarı/aşağı - yerçekimi)

---
**Geliştirici:** Senior Flutter Developer  
**Versiyon:** 1.0.0 (İskelet Kod)
