class User {
  final int id;
  final String email;
  final String fullName;
  final DateTime dob;
  final String gender;

  User({required this.id, required this.email, required this.fullName, required this.dob, required this.gender});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      dob: DateTime.parse(json['dob']),
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'dob': dob.toIso8601String(),
      'gender': gender,
    };
  }
}
