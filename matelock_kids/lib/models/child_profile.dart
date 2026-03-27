class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String avatarId;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatarId': avatarId,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? 'Niño',
      age: map['age'] ?? 9,
      avatarId: map['avatarId'] ?? 'bear',
    );
  }

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarId,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}