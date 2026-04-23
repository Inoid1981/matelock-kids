import 'package:flutter/material.dart';

import '../models/android_config.dart';
import '../models/child_profile.dart';
import '../models/unlock_session.dart';
import '../utils/app_constants.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';

class ProtectedAppsTestScreen extends StatefulWidget {
  final ChildProfile profile;
  final List<String> blockedApps;
  final AndroidConfig config;
  final List<UnlockSession> unlockSessions;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final Future<bool?> Function(String appName) onRequestOpenApp;

  const ProtectedAppsTestScreen({
    super.key,
    required this.profile,
    required this.blockedApps,
    required this.config,
    required this.unlockSessions,
    required this.language,
    required this.onLanguageChanged,
    required this.onRequestOpenApp,
  });

  @override
  State<ProtectedAppsTestScreen> createState() =>
      _ProtectedAppsTestScreenState();
}

class _ProtectedAppsTestScreenState extends State<ProtectedAppsTestScreen> {
  late List<UnlockSession> unlockSessions;

  @override
  void initState() {
    super.initState();
    unlockSessions = widget.unlockSessions.where((e) => e.isActive).toList();
  }

  bool _isUnlocked(String appName) {
    return unlockSessions.any((s) => s.appName == appName && s.isActive);
  }

  DateTime? _getExpiry(String appName) {
    try {
      return unlockSessions
          .firstWhere((s) => s.appName == appName && s.isActive)
          .expiresAt;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openApp(String appName) async {
    if (_isUnlocked(appName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLabel(widget.language, appName)} ${tr(widget.language, 'accessAllowed')}',
          ),
        ),
      );
      return;
    }

    final granted = await widget.onRequestOpenApp(appName);

    if (granted == true) {
      final expiresAt = DateTime.now().add(
        Duration(minutes: widget.config.unlockMinutes),
      );
      unlockSessions.removeWhere((e) => e.appName == appName);
      unlockSessions.add(UnlockSession(appName: appName, expiresAt: expiresAt));
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanedSessions = unlockSessions.where((e) => e.isActive).toList();
    final blockedApps = List<String>.from(widget.blockedApps);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.language, 'testProtectedApps')),
        actions: [
          LanguageSwitcher(
            language: widget.language,
            onChanged: widget.onLanguageChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: blockedApps.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(widget.language, 'noBlockedApps'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(tr(widget.language, 'blockedAppsSubtitle')),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, cleanedSessions),
                      child: Text(tr(widget.language, 'backToPanel')),
                    ),
                  ],
                )
              : ListView(
                  children: [
                    Text(
                      'Apps protegidas: ${blockedApps.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...blockedApps.map((app) {
                      final unlocked = _isUnlocked(app);
                      final expiry = _getExpiry(app);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(unlocked ? Icons.lock_open : Icons.lock),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      appLabel(widget.language, app),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                unlocked && expiry != null
                                    ? '${tr(widget.language, 'unlockedUntil')} ${_formatDate(expiry)}'
                                    : tr(widget.language, 'locked'),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _openApp(app),
                                  child: Text(
                                    tr(widget.language, 'openProtectedApp'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (cleanedSessions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        tr(widget.language, 'unlockStatus'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...cleanedSessions.map(
                        (session) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.timer),
                            title: Text(
                              appLabel(widget.language, session.appName),
                            ),
                            subtitle: Text(
                              '${tr(widget.language, 'unlockedUntil')} ${_formatDate(session.expiresAt)}',
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, cleanedSessions),
                      child: Text(tr(widget.language, 'backToPanel')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
