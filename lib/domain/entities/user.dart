import 'package:equatable/equatable.dart';

/// Plan de suscripción del usuario.
enum UserPlan { free, premium }

/// Entidad pura de dominio: Usuario.
/// No depende de Firebase ni de ningún framework externo.
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserPlan plan;
  final DateTime? planRenewalDate;
  final DateTime createdAt;
  final String? photoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.plan = UserPlan.free,
    this.planRenewalDate,
    required this.createdAt,
    this.photoUrl,
  });

  bool get isPremium => plan == UserPlan.premium;

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserPlan? plan,
    DateTime? planRenewalDate,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      plan: plan ?? this.plan,
      planRenewalDate: planRenewalDate ?? this.planRenewalDate,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, email, plan, createdAt];
}
