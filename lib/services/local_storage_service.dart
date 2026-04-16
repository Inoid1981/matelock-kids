import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/android_config.dart';
import '../models/app_stats.dart';
import '../models/child_profile.dart';
import '../models/unlock_session.dart';

class LocalStorageService {
  static const String childrenKey = 'children_profiles';
  static const String activeChildIdKey = 'active_child_id';
  static const String blockedAppsPrefix = 'blocked_apps_';
  static const String statsPrefix = 'app_stats_';
  static const String androidConfigPrefix = 'android_config_';
  static const String unlockSessionsPrefix = 'unlock_sessions_';
  static const String setupDonePrefix = 'setup_done_';
  static const String protectionEnabledPrefix = 'protection_enabled_';
  static const String parentPinKey = 'parent_pin';

  static Future<void> saveChildren(List<ChildProfile> children) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = children.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(childrenKey, jsonList);
  }

  static Future<List<ChildProfile>> loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(childrenKey) ?? [];
    return raw.map((e) => ChildProfile.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveActiveChildId(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeChildIdKey, childId);
  }

  static Future<String?> loadActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(activeChildIdKey);
  }

  static Future<void> saveStats(String childId, AppStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$statsPrefix$childId', jsonEncode(stats.toMap()));
  }

  static Future<AppStats> loadStats(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$statsPrefix$childId');
    if (raw == null) return AppStats();
    return AppStats.fromMap(jsonDecode(raw));
  }

  static Future<void> deleteStats(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$statsPrefix$childId');
  }

  static Future<void> saveBlockedApps(String childId, List<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$blockedAppsPrefix$childId', apps);
  }

  static Future<List<String>> loadBlockedApps(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$blockedAppsPrefix$childId') ?? <String>[];
  }

  static Future<void> deleteBlockedApps(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$blockedAppsPrefix$childId');
  }

  static Future<void> saveAndroidConfig(
    String childId,
    AndroidConfig config,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$androidConfigPrefix$childId',
      jsonEncode(config.toMap()),
    );
  }

  static Future<AndroidConfig> loadAndroidConfig(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$androidConfigPrefix$childId');
    if (raw == null) return AndroidConfig();
    return AndroidConfig.fromMap(jsonDecode(raw));
  }

  static Future<void> deleteAndroidConfig(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$androidConfigPrefix$childId');
  }

  static Future<void> saveUnlockSessions(
    String childId,
    List<UnlockSession> sessions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = sessions.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('$unlockSessionsPrefix$childId', raw);
  }

  static Future<List<UnlockSession>> loadUnlockSessions(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$unlockSessionsPrefix$childId') ?? [];
    return raw.map((e) => UnlockSession.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> deleteUnlockSessions(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$unlockSessionsPrefix$childId');
  }

  static Future<void> saveSetupDone(String childId, bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$setupDonePrefix$childId', done);
  }

  static Future<bool> loadSetupDone(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$setupDonePrefix$childId') ?? false;
  }

  static Future<void> deleteSetupDone(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$setupDonePrefix$childId');
  }

  static Future<void> saveProtectionEnabled(
    String childId,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$protectionEnabledPrefix$childId', enabled);
  }

  static Future<bool> loadProtectionEnabled(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$protectionEnabledPrefix$childId') ?? true;
  }

  static Future<void> deleteProtectionEnabled(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$protectionEnabledPrefix$childId');
  }

  static Future<void> saveParentPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(parentPinKey, pin);
  }

  static Future<String?> loadParentPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(parentPinKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key == childrenKey ||
          key == activeChildIdKey ||
          key == parentPinKey ||
          key.startsWith(statsPrefix) ||
          key.startsWith(blockedAppsPrefix) ||
          key.startsWith(androidConfigPrefix) ||
          key.startsWith(unlockSessionsPrefix) ||
          key.startsWith(setupDonePrefix) ||
          key.startsWith(protectionEnabledPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
