import '../../domain/entities/user.dart';

/// Modelo de usuario para SQLite (reemplaza Firestore).
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.plan,
    super.planRenewalDate,
    required super.createdAt,
    super.photoUrl,
  });

  // ── fromMap (SQLite) ─────────────────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      plan: _parsePlan(map['plan'] as String?),
      planRenewalDate: map['plan_renewal_date'] != null
          ? DateTime.parse(map['plan_renewal_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      photoUrl: map['photo_url'] as String?,
    );
  }

  // ── toMap (SQLite) ─────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'plan': plan.name,
        if (planRenewalDate != null)
          'plan_renewal_date': planRenewalDate!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        if (photoUrl != null) 'photo_url': photoUrl,
      };

  // ── fromEntity ─────────────────────────────────────────────────────────
  static UserModel fromEntity(User user) => UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        plan: user.plan,
        planRenewalDate: user.planRenewalDate,
        createdAt: user.createdAt,
        photoUrl: user.photoUrl,
      );

  @override
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserPlan? plan,
    DateTime? planRenewalDate,
    DateTime? createdAt,
    String? photoUrl,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        plan: plan ?? this.plan,
        planRenewalDate: planRenewalDate ?? this.planRenewalDate,
        createdAt: createdAt ?? this.createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  static UserPlan _parsePlan(String? v) =>
      UserPlan.values.firstWhere((p) => p.name == v, orElse: () => UserPlan.free);
}
