class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final int coins;
  final int lifetimeCoins;
  final String tier;
  final bool isAdmin;
  final bool isBanned;
  final bool isActive;
  final bool emailVerified;
  final bool mfaEnabled;
  final bool onboardingCompleted;
  final String? lastLoginAt;
  final String createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? stats;

  User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.coins = 0,
    this.lifetimeCoins = 0,
    this.tier = 'freemium',
    this.isAdmin = false,
    this.isBanned = false,
    this.isActive = true,
    this.emailVerified = false,
    this.mfaEnabled = false,
    this.onboardingCompleted = false,
    this.lastLoginAt,
    required this.createdAt,
    this.updatedAt,
    this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      coins: json['coins'] as int? ?? 0,
      lifetimeCoins: json['lifetime_coins'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'freemium',
      isAdmin: json['is_admin'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      stats: json['stats'] as Map<String, dynamic>?,
    );
  }

  String get displayNameOrEmail =>
      (displayName != null && displayName!.isNotEmpty)
      ? displayName!
      : (email ?? id);

  String get initial => displayNameOrEmail[0].toUpperCase();

  bool get isDeleted => !isActive && isBanned;
}
