class User {
  final String id;
  String name;
  String phoneNumber;
  String? photo; // base64 string

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'photo': photo,
    };
  }
}
