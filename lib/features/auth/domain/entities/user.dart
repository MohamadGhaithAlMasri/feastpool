enum UserRole { employee, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final UserRole role;
  final double ledgerBalance;
  final int mealsOrdered;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.ledgerBalance,
    required this.mealsOrdered,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    UserRole? role,
    double? ledgerBalance,
    int? mealsOrdered,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      ledgerBalance: ledgerBalance ?? this.ledgerBalance,
      mealsOrdered: mealsOrdered ?? this.mealsOrdered,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
