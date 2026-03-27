class UserModel {
  final String id;
  final String email;
  final String? name;
  final Map<String, double> budgets; // category -> limit

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.budgets = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'budgets': budgets,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      budgets: Map<String, double>.from(map['budgets'] ?? {}),
    );
  }
}
