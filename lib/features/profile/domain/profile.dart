/// User profile domain model
class UserProfile {
  final String name;
  final double? heightCm;
  final double? weightKg;
  final String? gender;

  const UserProfile({
    required this.name,
    this.heightCm,
    this.weightKg,
    this.gender,
  });

  /// Default profile for first-time users
  factory UserProfile.defaultProfile() => const UserProfile(
        name: 'Alex',
        heightCm: 178,
        weightKg: 72.5,
        gender: 'male',
      );

  /// Copy with modifications
  UserProfile copyWith({
    String? name,
    double? heightCm,
    double? weightKg,
    String? gender,
  }) {
    return UserProfile(
      name: name ?? this.name,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
    );
  }

  /// Calculate BMI
  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          heightCm == other.heightCm &&
          weightKg == other.weightKg &&
          gender == other.gender;

  @override
  int get hashCode =>
      name.hashCode ^
      (heightCm?.hashCode ?? 0) ^
      (weightKg?.hashCode ?? 0) ^
      (gender?.hashCode ?? 0);
}
