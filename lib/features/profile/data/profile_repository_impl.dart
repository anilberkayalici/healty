import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/profile.dart';
import 'profile_repository.dart';

/// SharedPreferences implementation of ProfileRepository
/// Singleton to ensure single source of truth
class ProfileRepositoryImpl implements ProfileRepository {
  // Singleton pattern
  ProfileRepositoryImpl._();
  static final ProfileRepositoryImpl _instance = ProfileRepositoryImpl._();
  factory ProfileRepositoryImpl() => _instance;

  // Storage keys
  static const String _keyName = 'profile_name';
  static const String _keyHeightCm = 'profile_height_cm';
  static const String _keyWeightKg = 'profile_weight_kg';
  static const String _keyGender = 'profile_gender';

  // Broadcast stream for live updates
  final _controller = StreamController<UserProfile>.broadcast();
  UserProfile? _cachedProfile;

  @override
  Future<UserProfile> load() async {
    if (_cachedProfile != null) return _cachedProfile!;

    try {
      final prefs = await SharedPreferences.getInstance();

      final name = prefs.getString(_keyName);
      final heightCm = prefs.getDouble(_keyHeightCm);
      final weightKg = prefs.getDouble(_keyWeightKg);
      final gender = prefs.getString(_keyGender);

      // If no saved data, use defaults
      if (name == null) {
        _cachedProfile = UserProfile.defaultProfile();
      } else {
        _cachedProfile = UserProfile(
          name: name,
          heightCm: heightCm,
          weightKg: weightKg,
          gender: gender,
        );
      }

      // Emit initial value
      _controller.add(_cachedProfile!);

      return _cachedProfile!;
    } catch (e) {
      // Fallback to default
      _cachedProfile = UserProfile.defaultProfile();
      return _cachedProfile!;
    }
  }

  @override
  Future<void> save(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyName, profile.name);

      if (profile.heightCm != null) {
        await prefs.setDouble(_keyHeightCm, profile.heightCm!);
      } else {
        await prefs.remove(_keyHeightCm);
      }

      if (profile.weightKg != null) {
        await prefs.setDouble(_keyWeightKg, profile.weightKg!);
      } else {
        await prefs.remove(_keyWeightKg);
      }

      if (profile.gender != null) {
        await prefs.setString(_keyGender, profile.gender!);
      } else {
        await prefs.remove(_keyGender);
      }

      // Update cache and emit to stream
      _cachedProfile = profile;
      _controller.add(profile);
    } catch (e) {
      // Silent fail - keep old cache
    }
  }

  @override
  Stream<UserProfile> watch() async* {
    // Emit current value immediately if available
    if (_cachedProfile != null) {
      yield _cachedProfile!;
    } else {
      // Load and emit
      yield await load();
    }

    // Then yield all future updates
    yield* _controller.stream;
  }

  /// Clean up resources (optional, call on app dispose if needed)
  void dispose() {
    _controller.close();
  }
}
