import '../domain/profile.dart';

/// Repository interface for user profile persistence
/// Single source of truth for profile data
abstract class ProfileRepository {
  /// Load saved profile (or default if none exists)
  Future<UserProfile> load();

  /// Save profile changes
  Future<void> save(UserProfile profile);

  /// Watch profile changes as a stream
  Stream<UserProfile> watch();
}
