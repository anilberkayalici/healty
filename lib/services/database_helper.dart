import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton pattern ile veritabanı yönetim servisi
/// Bu sınıf uygulamada sadece bir kez oluşturulur ve tüm veritabanı işlemlerini yönetir
class DatabaseHelper {
  // Singleton instance - Uygulama boyunca tek bir örnek
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  // Factory constructor - Her çağrıldığında aynı instance'ı döndürür
  factory DatabaseHelper() => _instance;
  
  // Private constructor - Dışarıdan new ile oluşturulamaz
  DatabaseHelper._internal();
  
  // Veritabanı objesi
  static Database? _database;
  
  // Tablo ve sütun isimleri (Sabit değerler)
  static const String tableName = 'posture_logs';
  static const String columnId = 'id';
  static const String columnTimestamp = 'timestamp';
  static const String columnDurationSeconds = 'duration_seconds';
  
  /// Veritabanı getter - Eğer yoksa oluşturur, varsa mevcut olanı döndürür
  Future<Database> get database async {
    // Eğer veritabanı zaten oluşturulmuşsa, onu döndür
    if (_database != null) return _database!;
    
    // Veritabanı yoksa, oluştur
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Veritabanını başlat ve tabloyu oluştur
  Future<Database> _initDatabase() async {
    // Veritabanı dosyasının kaydedileceği yolu al
    String path = join(await getDatabasesPath(), 'posture_guard.db');
    
    // Veritabanını aç veya oluştur (versiyon 1)
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  /// Veritabanı ilk oluşturulduğunda çağrılır - Tabloyu kur
  Future<void> _onCreate(Database db, int version) async {
    // posture_logs tablosunu oluştur
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTimestamp TEXT NOT NULL,
        $columnDurationSeconds INTEGER NOT NULL
      )
    ''');
  }
  
  /// Yeni bir duruş ihlali kaydı ekle
  /// [timestamp] - İhlalin gerçekleştiği zaman (ISO 8601 formatında)
  /// [durationSeconds] - İhlalin süresi (saniye cinsinden)
  Future<int> insertViolation(String timestamp, int durationSeconds) async {
    Database db = await database;
    
    // Veriyi map olarak hazırla
    Map<String, dynamic> row = {
      columnTimestamp: timestamp,
      columnDurationSeconds: durationSeconds,
    };
    
    // Veritabanına kaydet ve eklenen satırın ID'sini döndür
    return await db.insert(tableName, row);
  }
  
  /// Bugün gerçekleşen tüm ihlalleri getir
  Future<List<Map<String, dynamic>>> getTodayViolations() async {
    Database db = await database;
    
    // Bugünün başlangıç zamanı (00:00:00)
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    String startOfDayStr = startOfDay.toIso8601String();
    
    // Bugünden itibaren olan kayıtları sorgula
    return await db.query(
      tableName,
      where: '$columnTimestamp >= ?',
      whereArgs: [startOfDayStr],
      orderBy: '$columnTimestamp DESC', // En yeniden eskiye doğru
    );
  }
  
  /// Bugünkü toplam ihlal sayısını getir
  Future<int> getTodayViolationCount() async {
    List<Map<String, dynamic>> violations = await getTodayViolations();
    return violations.length;
  }
  
  /// Tüm kayıtları getir (test/debug amaçlı)
  Future<List<Map<String, dynamic>>> getAllViolations() async {
    Database db = await database;
    return await db.query(tableName, orderBy: '$columnTimestamp DESC');
  }
  
  /// Veritabanındaki tüm kayıtları sil (test amaçlı)
  Future<int> deleteAllViolations() async {
    Database db = await database;
    return await db.delete(tableName);
  }
  
  /// Belirli bir kaydı sil
  Future<int> deleteViolation(int id) async {
    Database db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
