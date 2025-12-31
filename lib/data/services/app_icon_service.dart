import 'dart:typed_data';
import 'package:flutter/services.dart';

class AppIconData {
  final Uint8List? iconBytes;
  final String? displayName;

  AppIconData({this.iconBytes, this.displayName});
}

class AppIconService {
  static const platform = MethodChannel('com.example.posture_guard/app_icons');
  
  // Icon cache
  static final Map<String, AppIconData> _cache = {};

  /// Get app icon and display name from native Android
  static Future<AppIconData> getAppInfo(String packageName) async {
    // Return cached if available
    if (_cache.containsKey(packageName)) {
      return _cache[packageName]!;
    }

    try {
      final dynamic response = await platform.invokeMethod(
        'getAppIcon',
        {'packageName': packageName},
      );
      
      if (response is Map) {
        final iconBytes = response['icon'] as Uint8List?;
        final label = response['label'] as String?;
        final data = AppIconData(iconBytes: iconBytes, displayName: label);
        _cache[packageName] = data;
        return data;
      }
      
      // Fallback for null response
      final data = AppIconData();
      _cache[packageName] = data;
      return data;
    } catch (e) {
      // Cache empty data on error
      final data = AppIconData();
      _cache[packageName] = data;
      return data;
    }
  }

  /// Legacy method for backward compatibility
  static Future<Uint8List?> getIcon(String packageName) async {
    final data = await getAppInfo(packageName);
    return data.iconBytes;
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
  }
}
