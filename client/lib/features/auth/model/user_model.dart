class UserModel {
  final String id;
  final String name;
  final String email;
  final String token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
  });

  // Updated to match your backend response format
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // For login response from auth.py: {"token": "...", "user": {...}}
    // For signup response from auth.py: {"message": "...", "user": {...}}
    final userData = map['user'] as Map<String, dynamic>;

    return UserModel(
      id: userData['id'] as String,
      name: userData['name'] as String,
      email: userData['email'] as String,
      token: map['token'] as String? ?? '', // Token is at top level
    );
  }

  Map<String, dynamic> toMap() {
    // Format matches the request format expected by your backend
    return {
      'name': name,
      'email': email,
      'id': id,
      'token': token,
    };
  }

  @override
  String toString() {
    return 'UserModel(name: $name, email: $email, id: $id, token: $token)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.email == email &&
        other.id == id &&
        other.token == token;
  }

  @override
  int get hashCode {
    return name.hashCode ^ email.hashCode ^ id.hashCode ^ token.hashCode;
  }
}
