# PostureGuard - Proje Dosya Yapısı

Bu dosya, projenin modüler dizin yapısını ve her dizinin amacını açıklar.

## 📁 Ana Dizin Yapısı

```
posture_guard/
│
├── lib/                          # Tüm Dart/Flutter kaynak kodları
│   │
│   ├── main.dart                 # ✅ ANA GİRİŞ NOKTASI
│   │                             # - MaterialApp ve tema yapılandırması
│   │                             # - PostureMonitorScreen başlatılıyor
│   │
│   ├── screens/                  # 🖼️ UI EKRANLARI
│   │                             # Gelecekte eklenecek:
│   │                             # - home_screen.dart (Ana ekran)
│   │                             # - settings_screen.dart (Ayarlar)
│   │                             # - statistics_screen.dart (İstatistikler)
│   │
│   ├── services/                 # ⚙️ SERVİSLER ve İŞ MANTIKLARI
│   │                             # Gelecekte eklenecek:
│   │                             # - sensor_service.dart (Sensör yönetimi)
│   │                             # - background_service.dart (Arka plan işlemleri)
│   │                             # - notification_service.dart (Bildirimler)
│   │
│   ├── database/                 # 💾 VERİTABANI İŞLEMLERİ
│   │                             # Gelecekte eklenecek:
│   │                             # - database_helper.dart (SQLite CRUD işlemleri)
│   │                             # - posture_logs_db.dart (posture_logs tablosu)
│   │
│   ├── models/                   # 📦 VERİ MODELLERİ
│   │                             # Gelecekte eklenecek:
│   │                             # - posture_log.dart (Veritabanı modeli)
│   │                             # - sensor_data.dart (Sensör veri modeli)
│   │
│   └── utils/                    # 🛠️ YARDIMCI FONKSİYONLAR
│                                 # Gelecekte eklenecek:
│                                 # - constants.dart (Sabit değerler: eşik açıları vb.)
│                                 # - helpers.dart (Genel yardımcı fonksiyonlar)
│
├── pubspec.yaml                  # ✅ PAKET BAĞIMLILIKLARI
│                                 # - sensors_plus
│                                 # - sqflite
│                                 # - path
│                                 # - flutter_background_service
│
└── README.md                     # 📖 PROJE DOKÜMANTASYONU

```

## 🎯 Dizin Amaçları ve Sorumluluklar

### **lib/screens/**
- **Amaç:** Tüm kullanıcı arayüzü ekranlarını barındırır
- **İçerik:** Stateful/Stateless Widget'lar
- **Sorumluluk:** Sadece UI ve kullanıcı etkileşimleri

### **lib/services/**
- **Amaç:** İş mantığı ve sistem servisleri
- **İçerik:** Singleton servis sınıfları
- **Sorumluluk:** Sensör okuma, arka plan işlemleri, notifikasyonlar

### **lib/database/**
- **Amaç:** Veritabanı işlemleri
- **İçerik:** SQLite CRUD operasyonları
- **Sorumluluk:** Veri kaydetme, okuma, silme, güncelleme

### **lib/models/**
- **Amaç:** Veri yapılarını tanımlar
- **İçerik:** Dart sınıfları (toJson, fromJson metodları)
- **Sorumluluk:** Verilerin şekillendirilmesi ve dönüştürülmesi

### **lib/utils/**
- **Amaç:** Yardımcı araçlar ve sabitler
- **İçerik:** Genel fonksiyonlar, enum'lar, sabitler
- **Sorumluluk:** Tekrar kullanılabilir kod parçaları

---

## 🧱 Modüler Tasarım Prensibi

Bu yapı **"Separation of Concerns"** (İşlevlerin Ayrılması) ilkesini takip eder:

1. **UI ↔ İş Mantığı Ayrımı:** Ekranlar sadece görünümle ilgilenir
2. **Tek Sorumluluk Prensibi:** Her dizin tek bir sorumluluğa sahip
3. **Ölçeklenebilirlik:** Yeni özellikler kolayca eklenebilir
4. **Bakım Kolaylığı:** Her şey mantıklı bir yerde

---

**Açıklama Güncellenme Tarihi:** 10 Aralık 2025  
**Durum:** İskelet yapı tamamlandı ✅
