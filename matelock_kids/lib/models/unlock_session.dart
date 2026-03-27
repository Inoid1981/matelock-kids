class UnlockSession {
  final String appName;
  final DateTime expiresAt;

  UnlockSession({
    required this.appName,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory UnlockSession.fromMap(Map<String, dynamic> map) {
    return UnlockSession(
      appName: map['appName'] ?? '',
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now(),
    );
  }
}