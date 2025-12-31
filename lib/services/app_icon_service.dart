import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Service to fetch real app icons from installed apps on Android
class AppIconService {
  static const _channel = MethodChannel('posture_guard/app_icons');

  static final Map<String, Uint8List?> _cache = {};

  /// Get app icon bytes from package name
  /// Returns cached value if available, otherwise fetches from platform
  static Future<Uint8List?> getIconBytes(String packageName) async {
    if (_cache.containsKey(packageName)) return _cache[packageName];
    
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': packageName},
      );
      _cache[packageName] = bytes;
      return bytes;
    } catch (_) {
      _cache[packageName] = null;
      return null;
    }
  }

  /// Clear the icon cache (useful for memory management)
  static void clearCache() => _cache.clear();
}
