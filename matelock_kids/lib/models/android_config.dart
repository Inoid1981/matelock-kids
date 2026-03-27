class AndroidConfig {
  bool usageAccessGranted;
  bool overlayGranted;
  bool foregroundServiceGranted;
  int unlockMinutes;

  AndroidConfig({
    this.usageAccessGranted = false,
    this.overlayGranted = false,
    this.foregroundServiceGranted = false,
    this.unlockMinutes = 5,
  });

  bool get isReady =>
      usageAccessGranted && overlayGranted && foregroundServiceGranted;

  Map<String, dynamic> toMap() {
    return {
      'usageAccessGranted': usageAccessGranted,
      'overlayGranted': overlayGranted,
      'foregroundServiceGranted': foregroundServiceGranted,
      'unlockMinutes': unlockMinutes,
    };
  }

  factory AndroidConfig.fromMap(Map<String, dynamic> map) {
    return AndroidConfig(
      usageAccessGranted: map['usageAccessGranted'] ?? false,
      overlayGranted: map['overlayGranted'] ?? false,
      foregroundServiceGranted: map['foregroundServiceGranted'] ?? false,
      unlockMinutes: map['unlockMinutes'] ?? 5,
    );
  }
}