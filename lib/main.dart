import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/android_config.dart';
import 'models/app_stats.dart';
import 'models/child_profile.dart';
import 'models/unlock_session.dart';
import 'services/local_storage_service.dart';
import 'utils/app_constants.dart';
import 'utils/translations.dart';
import 'widgets/language_switcher.dart';
import 'widgets/pretty_card.dart';

const MethodChannel androidChannel = MethodChannel('matelock_kids/android');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MateLockKidsApp());
}

class MateLockKidsApp extends StatefulWidget {
  const MateLockKidsApp({super.key});

  @override
  State<MateLockKidsApp> createState() => _MateLockKidsAppState();
}

class _MateLockKidsAppState extends State<MateLockKidsApp> {
  AppLanguage language = AppLanguage.spanish;

  void changeLanguage(AppLanguage newLanguage) {
    setState(() {
      language = newLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MateLock Kids',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.indigo, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      home: StartupScreen(
        language: language,
        onLanguageChanged: changeLanguage,
      ),
    );
  }
}

class StartupScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const StartupScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool isLoading = true;
  List<ChildProfile> children = [];
  ChildProfile? activeChild;
  AppStats stats = AppStats();
  List<String> blockedApps = <String>[];
  String parentPin = '1234';
  AndroidConfig androidConfig = AndroidConfig();
  List<UnlockSession> unlockSessions = [];
  bool setupDone = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final loadedChildren = await LocalStorageService.loadChildren();
    final activeId = await LocalStorageService.loadActiveChildId();
    final loadedPin = await LocalStorageService.loadParentPin();

    ChildProfile? selectedChild;
    if (loadedChildren.isNotEmpty) {
      if (activeId != null) {
        try {
          selectedChild = loadedChildren.firstWhere((c) => c.id == activeId);
        } catch (_) {
          selectedChild = loadedChildren.first;
        }
      } else {
        selectedChild = loadedChildren.first;
      }
    }

    AppStats loadedStats = AppStats();
    List<String> loadedBlockedApps = [];
    AndroidConfig loadedAndroidConfig = AndroidConfig();
    List<UnlockSession> loadedSessions = [];
    bool loadedSetupDone = false;

    if (selectedChild != null) {
      loadedStats = await LocalStorageService.loadStats(selectedChild.id);
      loadedBlockedApps = await LocalStorageService.loadBlockedApps(
        selectedChild.id,
      );
      loadedAndroidConfig = await LocalStorageService.loadAndroidConfig(
        selectedChild.id,
      );
      loadedSessions = await LocalStorageService.loadUnlockSessions(
        selectedChild.id,
      );
      loadedSessions = loadedSessions.where((e) => e.isActive).toList();
      loadedSetupDone = await LocalStorageService.loadSetupDone(
        selectedChild.id,
      );
      await LocalStorageService.saveUnlockSessions(
        selectedChild.id,
        loadedSessions,
      );
    }

    setState(() {
      children = loadedChildren;
      activeChild = selectedChild;
      stats = loadedStats;
      blockedApps = loadedBlockedApps;
      parentPin = loadedPin;
      androidConfig = loadedAndroidConfig;
      unlockSessions = loadedSessions;
      setupDone = loadedSetupDone;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (children.isEmpty || activeChild == null) {
      return ParentLoginScreen(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      );
    }

    if (!setupDone) {
      return InitialSetupScreen(
        childId: activeChild!.id,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      );
    }

    return ParentDashboardScreen(
      children: children,
      activeChild: activeChild!,
      stats: stats,
      blockedApps: blockedApps,
      parentPin: parentPin,
      androidConfig: androidConfig,
      unlockSessions: unlockSessions,
      language: widget.language,
      onLanguageChanged: widget.onLanguageChanged,
    );
  }
}

class ParentLoginScreen extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ParentLoginScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(language, 'appTitle')),
        actions: [
          LanguageSwitcher(language: language, onChanged: onLanguageChanged),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  PrettyCard(
                    color: const Color(0xFFEAEFFF),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock, size: 46),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr(language, 'appTitle'),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(language, 'tagline'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrettyCard(
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: tr(language, 'email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: tr(language, 'password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChildProfileScreen(
                                    language: language,
                                    onLanguageChanged: onLanguageChanged,
                                  ),
                                ),
                              );
                            },
                            child: Text(tr(language, 'createFirstChild')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChildProfileScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ChildProfile? existingProfile;

  const ChildProfileScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    this.existingProfile,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedAge = 9;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _nameController.text = widget.existingProfile!.name;
      _selectedAge = widget.existingProfile!.age;
    }
  }

  Future<void> _continue() async {
    setState(() => _saving = true);

    final name = _nameController.text.trim().isEmpty
        ? tr(widget.language, 'childDefault')
        : _nameController.text.trim();

    final children = await LocalStorageService.loadChildren();

    ChildProfile profile;
    if (widget.existingProfile != null) {
      profile = widget.existingProfile!.copyWith(name: name, age: _selectedAge);
      final index = children.indexWhere((c) => c.id == profile.id);
      if (index != -1) children[index] = profile;
    } else {
      profile = ChildProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        age: _selectedAge,
        avatarId: 'bear',
      );
      children.add(profile);
      await LocalStorageService.saveStats(profile.id, AppStats());
      await LocalStorageService.saveBlockedApps(profile.id, []);
      await LocalStorageService.saveAndroidConfig(profile.id, AndroidConfig());
      await LocalStorageService.saveUnlockSessions(profile.id, []);
      await LocalStorageService.saveSetupDone(profile.id, false);
    }

    await LocalStorageService.saveChildren(children);
    await LocalStorageService.saveActiveChildId(profile.id);
    await LocalStorageService.saveParentPin('1234');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InitialSetupScreen(
          childId: profile.id,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ages = List.generate(6, (index) => index + 7);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProfile == null
              ? tr(widget.language, 'createProfile')
              : tr(widget.language, 'editProfile'),
        ),
        actions: [
          LanguageSwitcher(
            language: widget.language,
            onChanged: widget.onLanguageChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: PrettyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existingProfile == null
                          ? tr(widget.language, 'createProfile')
                          : tr(widget.language, 'editProfile'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(tr(widget.language, 'enterNameAge')),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr(widget.language, 'name'),
                        prefixIcon: const Icon(Icons.child_care),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr(widget.language, 'age'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ages.map((age) {
                        return ChoiceChip(
                          label: Text('$age ${tr(widget.language, 'years')}'),
                          selected: age == _selectedAge,
                          onSelected: (_) {
                            setState(() => _selectedAge = age);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _continue,
                        child: Text(
                          _saving
                              ? tr(widget.language, 'saving')
                              : tr(widget.language, 'saveContinue'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InitialSetupScreen extends StatelessWidget {
  final String childId;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const InitialSetupScreen({
    super.key,
    required this.childId,
    required this.language,
    required this.onLanguageChanged,
  });

  Future<void> _finishSetup(
    BuildContext context, {
    required bool protectCalculator,
  }) async {
    final existingBlockedApps = await LocalStorageService.loadBlockedApps(
      childId,
    );
    final blockedApps = List<String>.from(existingBlockedApps);

    if (protectCalculator && !blockedApps.contains('calculator')) {
      blockedApps.add('calculator');
      await LocalStorageService.saveBlockedApps(childId, blockedApps);
    }

    await LocalStorageService.saveSetupDone(childId, true);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => StartupScreen(
          language: language,
          onLanguageChanged: onLanguageChanged,
        ),
      ),
      (route) => false,
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculatorLabel = appLabel(language, 'calculator');

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(language, 'initialSetupTitle')),
        actions: [
          LanguageSwitcher(language: language, onChanged: onLanguageChanged),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  PrettyCard(
                    color: const Color(0xFFEAEFFF),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calculate, size: 42),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(language, 'initialSetupTitle'),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(language, 'initialSetupSubtitle'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrettyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(language, 'howItWorks'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildStep(tr(language, 'howItWorks1')),
                        _buildStep(tr(language, 'howItWorks2')),
                        _buildStep(tr(language, 'howItWorks3')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrettyCard(
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(appIcon('calculator')),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '$calculatorLabel · ${tr(language, 'blockedApps')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _finishSetup(context, protectCalculator: true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(tr(language, 'protectCalculator')),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        _finishSetup(context, protectCalculator: false),
                    child: Text(tr(language, 'continueWithoutIt')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ParentDashboardScreen extends StatefulWidget {
  final List<ChildProfile> children;
  final ChildProfile activeChild;
  final AppStats stats;
  final List<String> blockedApps;
  final String parentPin;
  final AndroidConfig androidConfig;
  final List<UnlockSession> unlockSessions;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ParentDashboardScreen({
    super.key,
    required this.children,
    required this.activeChild,
    required this.stats,
    required this.blockedApps,
    required this.parentPin,
    required this.androidConfig,
    required this.unlockSessions,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with WidgetsBindingObserver {
  late List<ChildProfile> children;
  late ChildProfile activeChild;
  late AppStats stats;
  late List<String> blockedApps;
  late String parentPin;
  late AndroidConfig androidConfig;
  late List<UnlockSession> unlockSessions;
  bool protectionEnabled = false;
  bool _pendingProtectionActivation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    children = List<ChildProfile>.from(widget.children);
    activeChild = widget.activeChild;
    stats = widget.stats;
    blockedApps = List<String>.from(widget.blockedApps);
    parentPin = widget.parentPin;
    androidConfig = widget.androidConfig;
    unlockSessions = List<UnlockSession>.from(
      widget.unlockSessions,
    ).where((e) => e.isActive).toList();
    protectionEnabled = androidConfig.foregroundServiceGranted;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pendingProtectionActivation) {
        _resumeProtectionActivation();
      } else {
        _refreshAndroidPermissionStatus();
      }
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _syncBlockedAppsWithAndroid() async {
    if (!_isAndroid) return;

    try {
      await androidChannel.invokeMethod('setBlockedApps', {
        'appIds': blockedApps,
      });
    } catch (e) {
      debugPrint('Error syncing blocked apps: $e');
    }
  }

  Future<void> _refreshAndroidPermissionStatus() async {
    if (!_isAndroid) return;

    try {
      final hasOverlay =
          await androidChannel.invokeMethod<bool>('canDrawOverlays') ?? false;
      final hasUsage =
          await androidChannel.invokeMethod<bool>('hasUsageAccess') ?? false;

      if (!mounted) return;
      setState(() {
        androidConfig.overlayGranted = hasOverlay;
        androidConfig.usageAccessGranted = hasUsage;
      });
    } catch (e) {
      debugPrint('Error refreshing Android permission status: $e');
    }
  }

  Future<void> _resumeProtectionActivation() async {
    if (!_isAndroid) return;

    try {
      final hasOverlay =
          await androidChannel.invokeMethod<bool>('canDrawOverlays') ?? false;
      final hasUsage =
          await androidChannel.invokeMethod<bool>('hasUsageAccess') ?? false;

      if (!mounted) return;

      setState(() {
        androidConfig.overlayGranted = hasOverlay;
        androidConfig.usageAccessGranted = hasUsage;
      });

      if (!hasOverlay) {
        await androidChannel.invokeMethod('openOverlaySettings');
        return;
      }

      if (!hasUsage) {
        await androidChannel.invokeMethod('openUsageAccessSettings');
        return;
      }

      await _syncBlockedAppsWithAndroid();
      await androidChannel.invokeMethod('startMonitorService');

      androidConfig.foregroundServiceGranted = true;
      await LocalStorageService.saveAndroidConfig(
        activeChild.id,
        androidConfig,
      );

      if (!mounted) return;
      setState(() {
        protectionEnabled = true;
        _pendingProtectionActivation = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Protección activada')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        protectionEnabled = false;
        _pendingProtectionActivation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al activar protección: $e')),
      );
    }
  }

  Future<void> _toggleProtection(bool value) async {
    if (!_isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El bloqueo real solo funciona en Android.'),
        ),
      );
      return;
    }

    if (value && blockedApps.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(widget.language, 'noBlockedApps'))),
      );
      return;
    }

    if (value) {
      setState(() {
        protectionEnabled = false;
        _pendingProtectionActivation = true;
      });

      await _resumeProtectionActivation();
      return;
    }

    try {
      await androidChannel.invokeMethod('stopMonitorService');

      androidConfig.foregroundServiceGranted = false;
      await LocalStorageService.saveAndroidConfig(
        activeChild.id,
        androidConfig,
      );

      if (!mounted) return;
      setState(() {
        protectionEnabled = false;
        _pendingProtectionActivation = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Protección desactivada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al desactivar protección: $e')),
      );
    }
  }

  Future<void> _refreshActiveChild() async {
    final refreshedChildren = await LocalStorageService.loadChildren();
    final refreshedStats = await LocalStorageService.loadStats(activeChild.id);
    final refreshedBlockedApps = await LocalStorageService.loadBlockedApps(
      activeChild.id,
    );
    final refreshedAndroidConfig = await LocalStorageService.loadAndroidConfig(
      activeChild.id,
    );
    final refreshedUnlocks = await LocalStorageService.loadUnlockSessions(
      activeChild.id,
    );

    ChildProfile refreshedActiveChild = activeChild;
    try {
      refreshedActiveChild = refreshedChildren.firstWhere(
        (c) => c.id == activeChild.id,
      );
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      children = refreshedChildren;
      activeChild = refreshedActiveChild;
      stats = refreshedStats;
      blockedApps = refreshedBlockedApps;
      androidConfig = refreshedAndroidConfig;
      unlockSessions = refreshedUnlocks.where((e) => e.isActive).toList();
      protectionEnabled = refreshedAndroidConfig.foregroundServiceGranted;
    });
  }

  Future<void> _resetData() async {
    await LocalStorageService.clearAll();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ParentLoginScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
      (route) => false,
    );
  }

  Future<bool> _askForPin() async {
    final controller = TextEditingController();
    bool success = false;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(tr(widget.language, 'parentPin')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr(widget.language, 'enterPin')),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(widget.language, 'cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text == parentPin) {
                  success = true;
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(widget.language, 'wrongPin'))),
                  );
                }
              },
              child: Text(tr(widget.language, 'confirm')),
            ),
          ],
        );
      },
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(widget.language, 'accessAllowed'))),
      );
    }

    return success;
  }

  Future<void> _openBlockedApps() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => BlockedAppsScreen(
          selectedApps: blockedApps,
          language: widget.language,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        blockedApps = result;
      });
      await LocalStorageService.saveBlockedApps(activeChild.id, blockedApps);
      await _syncBlockedAppsWithAndroid();
      await _evaluateDashboardAchievements();
    }
  }

  Future<void> _openMathChallenge() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MathChallengeScreen(
          profile: activeChild,
          stats: stats,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    await LocalStorageService.saveStats(activeChild.id, stats);
    await _refreshActiveChild();
  }

  Future<void> _switchChild() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    final selected = await Navigator.push<ChildProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ChildManagerScreen(
          children: children,
          activeChildId: activeChild.id,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    if (selected != null) {
      await LocalStorageService.saveActiveChildId(selected.id);
      final setupDone = await LocalStorageService.loadSetupDone(selected.id);

      if (!mounted) return;

      if (!setupDone) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InitialSetupScreen(
              childId: selected.id,
              language: widget.language,
              onLanguageChanged: widget.onLanguageChanged,
            ),
          ),
        );
        return;
      }

      await _refreshActiveChild();
    }
  }

  Future<void> _addChild() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildProfileScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    await _refreshActiveChild();
  }

  Future<void> _editActiveChild() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildProfileScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
          existingProfile: activeChild,
        ),
      ),
    );

    await _refreshActiveChild();
  }

  Future<void> _openAndroidSetup() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    final result = await Navigator.push<AndroidSetupResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AndroidSetupScreen(
          config: androidConfig,
          blockedApps: blockedApps,
          unlockSessions: unlockSessions,
          language: widget.language,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        androidConfig = result.config;
        unlockSessions = result.unlockSessions
            .where((e) => e.isActive)
            .toList();
        protectionEnabled = result.config.foregroundServiceGranted;
      });
      await LocalStorageService.saveAndroidConfig(
        activeChild.id,
        androidConfig,
      );
      await LocalStorageService.saveUnlockSessions(
        activeChild.id,
        unlockSessions,
      );
    }
  }

  Future<void> _openProtectedAppsTester() async {
    if (blockedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(widget.language, 'noBlockedApps'))),
      );
      return;
    }

    final result = await Navigator.push<List<UnlockSession>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProtectedAppsTestScreen(
          profile: activeChild,
          blockedApps: blockedApps,
          config: androidConfig,
          unlockSessions: unlockSessions,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        unlockSessions = result.where((e) => e.isActive).toList();
      });
      await LocalStorageService.saveUnlockSessions(
        activeChild.id,
        unlockSessions,
      );
    }
  }

  Future<void> _openAvatarSelector() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    final selectedAvatar = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarSelectorScreen(
          selectedAvatar: activeChild.avatarId,
          unlockedAvatars: stats.unlockedAvatars,
          language: widget.language,
        ),
      ),
    );

    if (selectedAvatar != null) {
      final updatedChild = activeChild.copyWith(avatarId: selectedAvatar);
      final currentChildren = await LocalStorageService.loadChildren();
      final index = currentChildren.indexWhere((c) => c.id == activeChild.id);
      if (index != -1) {
        currentChildren[index] = updatedChild;
      }
      await LocalStorageService.saveChildren(currentChildren);
      setState(() {
        activeChild = updatedChild;
      });
    }
  }

  void _addAchievement(String id) {
    if (!stats.achievements.contains(id)) {
      stats.achievements.add(id);
    }
  }

  Future<void> _evaluateDashboardAchievements() async {
    if (blockedApps.length >= 3) {
      _addAchievement('apps_3');
    }
    await LocalStorageService.saveStats(activeChild.id, stats);
    if (mounted) setState(() {});
  }

  Widget _buildProgressBar() {
    final progress = (stats.successRate / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tr(widget.language, 'progress'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text('${stats.successRate.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.indigo.withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        title: tr(widget.language, 'hits'),
        value: '${stats.successRate.toStringAsFixed(0)}%',
        icon: Icons.check_circle_outline,
      ),
      _StatCard(
        title: tr(widget.language, 'attempts'),
        value: '${stats.totalAttempts}',
        icon: Icons.pin_outlined,
      ),
      _StatCard(
        title: tr(widget.language, 'fails'),
        value: '${stats.wrongAnswers}',
        icon: Icons.close_rounded,
      ),
      _StatCard(
        title: tr(widget.language, 'mostFails'),
        value: stats.mostFailedOperation(widget.language),
        icon: Icons.bar_chart_rounded,
      ),
      _StatCard(
        title: tr(widget.language, 'stars'),
        value: '? ${stats.stars}',
        icon: Icons.star_outline,
      ),
      _StatCard(
        title: tr(widget.language, 'bestStreak'),
        value: '?? ${stats.bestStreak}',
        icon: Icons.local_fire_department_outlined,
      ),
      _StatCard(
        title: tr(widget.language, 'difficulty'),
        value: '${stats.difficultyLevel}/5',
        icon: Icons.speed_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.language, 'parentsPanel')),
        actions: [
          LanguageSwitcher(
            language: widget.language,
            onChanged: widget.onLanguageChanged,
          ),
          IconButton(
            onPressed: _resetData,
            icon: const Icon(Icons.restart_alt),
            tooltip: tr(widget.language, 'resetData'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PrettyCard(
              color: const Color(0xFFEAEFFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(widget.language, 'activeChild'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatarEmoji(activeChild.avatarId),
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeChild.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tr(widget.language, 'age')}: ${activeChild.age} ${tr(widget.language, 'years')}',
                            ),
                            Text(
                              '${tr(widget.language, 'level')}: ${stats.difficultyLevel}/5',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildProgressBar(),
                  const SizedBox(height: 14),
                  Text(tr(widget.language, 'automaticLevel')),
                  const SizedBox(height: 8),
                  Text(
                    '${tr(widget.language, 'selectedApps')}: ${blockedApps.isEmpty ? tr(widget.language, 'noBlockedApps') : blockedApps.map((e) => appLabel(widget.language, e)).join(', ')}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tr(widget.language, 'androidReadiness')}: ${androidConfig.isReady ? tr(widget.language, 'ready') : tr(widget.language, 'notReady')}',
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: protectionEnabled,
                    title: const Text(
                      'Protección activa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      protectionEnabled ? 'Activada' : 'Desactivada',
                    ),
                    onChanged: _toggleProtection,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _switchChild,
                        icon: const Icon(Icons.people),
                        label: Text(tr(widget.language, 'switchChild')),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _addChild,
                        icon: const Icon(Icons.person_add),
                        label: Text(tr(widget.language, 'addChild')),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _editActiveChild,
                        icon: const Icon(Icons.edit),
                        label: Text(tr(widget.language, 'editProfile')),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _openAvatarSelector,
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        label: Text(tr(widget.language, 'chooseAvatar')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'summary'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: cards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (_, index) => cards[index],
            ),
            const SizedBox(height: 18),
            PrettyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(widget.language, 'rewards'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr(widget.language, 'avatars'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: stats.unlockedAvatars.map((avatarId) {
                      final isSelected = activeChild.avatarId == avatarId;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.indigo
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              avatarEmoji(avatarId),
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            Text(avatarLabel(widget.language, avatarId)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(widget.language, 'achievements'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (stats.achievements.isEmpty)
                    Text(tr(widget.language, 'none'))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: stats.achievements.map((achievementId) {
                        return Chip(
                          avatar: const Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                          ),
                          label: Text(
                            achievementLabel(widget.language, achievementId),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openMathChallenge,
              icon: const Icon(Icons.play_arrow),
              label: Text(tr(widget.language, 'testMathChallenge')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openBlockedApps,
              icon: const Icon(Icons.apps),
              label: Text(tr(widget.language, 'blockedApps')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openAndroidSetup,
              icon: const Icon(Icons.android),
              label: Text(tr(widget.language, 'configureAndroid')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openProtectedAppsTester,
              icon: const Icon(Icons.lock_open),
              label: Text(tr(widget.language, 'testProtectedApps')),
            ),
            const SizedBox(height: 12),
            Text(
              tr(widget.language, 'pinHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PrettyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class MathChallengeScreen extends StatefulWidget {
  final ChildProfile profile;
  final AppStats stats;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const MathChallengeScreen({
    super.key,
    required this.profile,
    required this.stats,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<MathChallengeScreen> createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends State<MathChallengeScreen> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();

  int a = 0;
  int b = 0;
  int result = 0;
  String operatorSymbol = '+';
  String message = '';
  String rewardMessage = '';
  bool isCorrect = false;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  void adjustDifficulty() {
    final success = widget.stats.successRate;

    if (success > 85 && widget.stats.difficultyLevel < 5) {
      widget.stats.difficultyLevel++;
    } else if (success < 50 && widget.stats.difficultyLevel > 1) {
      widget.stats.difficultyLevel--;
    }
  }

  void maybeUnlockRewards() {
    if (widget.stats.stars >= 10 &&
        !widget.stats.unlockedAvatars.contains('robot')) {
      widget.stats.unlockedAvatars.add('robot');
      rewardMessage =
          '?? ${tr(widget.language, 'rewardChest')}: ${tr(widget.language, 'robotAvatar')}';
    }

    if (widget.stats.stars >= 20 &&
        !widget.stats.unlockedAvatars.contains('ninja')) {
      widget.stats.unlockedAvatars.add('ninja');
      rewardMessage =
          '?? ${tr(widget.language, 'rewardChest')}: ${tr(widget.language, 'ninjaAvatar')}';
    }

    if (widget.stats.stars >= 35 &&
        !widget.stats.unlockedAvatars.contains('astronaut')) {
      widget.stats.unlockedAvatars.add('astronaut');
      rewardMessage =
          '?? ${tr(widget.language, 'rewardChest')}: ${tr(widget.language, 'astronautAvatar')}';
    }

    if (widget.stats.stars >= 50 &&
        !widget.stats.unlockedAvatars.contains('fox')) {
      widget.stats.unlockedAvatars.add('fox');
      rewardMessage =
          '?? ${tr(widget.language, 'rewardChest')}: ${tr(widget.language, 'foxAvatar')}';
    }

    if (widget.stats.stars >= 75 &&
        !widget.stats.unlockedAvatars.contains('cat')) {
      widget.stats.unlockedAvatars.add('cat');
      rewardMessage =
          '?? ${tr(widget.language, 'rewardChest')}: ${tr(widget.language, 'catAvatar')}';
    }

    void addAchievement(String id) {
      if (!widget.stats.achievements.contains(id)) {
        widget.stats.achievements.add(id);
        rewardMessage =
            '?? ${tr(widget.language, 'achievementUnlocked')}: ${achievementLabel(widget.language, id)}';
      }
    }

    if (widget.stats.bestStreak >= 5) addAchievement('streak_5');
    if (widget.stats.bestStreak >= 10) addAchievement('streak_10');
    if (widget.stats.stars >= 10) addAchievement('stars_10');
    if (widget.stats.stars >= 25) addAchievement('stars_25');
    if (widget.stats.correctAnswers >= 50) addAchievement('correct_50');
    if (widget.stats.difficultyLevel >= 3) addAchievement('level_3');
    if (widget.stats.difficultyLevel >= 5) addAchievement('level_5');
  }

  void generateQuestion() {
    final adjustedAge = widget.profile.age + widget.stats.difficultyLevel;

    if (adjustedAge <= 8) {
      final isSum = _random.nextBool();
      final max = 10 + (widget.stats.difficultyLevel * 2);
      a = _random.nextInt(max) + 1;
      b = _random.nextInt(max) + 1;

      if (isSum) {
        operatorSymbol = '+';
        result = a + b;
      } else {
        if (b > a) {
          final temp = a;
          a = b;
          b = temp;
        }
        operatorSymbol = '-';
        result = a - b;
      }
    } else if (adjustedAge <= 10) {
      final op = _random.nextInt(4);
      if (op == 0) {
        final max = 20 + (widget.stats.difficultyLevel * 3);
        a = _random.nextInt(max) + 1;
        b = _random.nextInt(max) + 1;
        operatorSymbol = '+';
        result = a + b;
      } else if (op == 1) {
        final max = 20 + (widget.stats.difficultyLevel * 3);
        a = _random.nextInt(max) + 1;
        b = _random.nextInt(max) + 1;
        if (b > a) {
          final temp = a;
          a = b;
          b = temp;
        }
        operatorSymbol = '-';
        result = a - b;
      } else if (op == 2) {
        final max = 9 + widget.stats.difficultyLevel;
        a = _random.nextInt(max) + 2;
        b = _random.nextInt(max) + 2;
        operatorSymbol = '×';
        result = a * b;
      } else {
        final max = 9 + widget.stats.difficultyLevel;
        b = _random.nextInt(max) + 2;
        result = _random.nextInt(max) + 2;
        a = b * result;
        operatorSymbol = '÷';
      }
    } else {
      final op = _random.nextInt(4);
      if (op == 0) {
        final max = 50 + (widget.stats.difficultyLevel * 10);
        a = _random.nextInt(max) + 10;
        b = _random.nextInt(max) + 10;
        operatorSymbol = '+';
        result = a + b;
      } else if (op == 1) {
        final maxA = 50 + (widget.stats.difficultyLevel * 10);
        final maxB = 30 + (widget.stats.difficultyLevel * 5);
        a = _random.nextInt(maxA) + 10;
        b = _random.nextInt(maxB) + 1;
        if (b > a) {
          final temp = a;
          a = b;
          b = temp;
        }
        operatorSymbol = '-';
        result = a - b;
      } else if (op == 2) {
        final max = 11 + widget.stats.difficultyLevel;
        a = _random.nextInt(max) + 2;
        b = _random.nextInt(max) + 2;
        operatorSymbol = '×';
        result = a * b;
      } else {
        final max = 11 + widget.stats.difficultyLevel;
        b = _random.nextInt(max) + 2;
        result = _random.nextInt(max) + 2;
        a = b * result;
        operatorSymbol = '÷';
      }
    }

    _controller.clear();
    message = '';
    rewardMessage = '';
    isCorrect = false;
    answered = false;
    setState(() {});
  }

  void registerFailureByOperation() {
    switch (operatorSymbol) {
      case '+':
        widget.stats.wrongAdditions++;
        break;
      case '-':
        widget.stats.wrongSubtractions++;
        break;
      case '×':
        widget.stats.wrongMultiplications++;
        break;
      case '÷':
        widget.stats.wrongDivisions++;
        break;
    }
  }

  void updateRewardMessage() {
    if (rewardMessage.isNotEmpty) return;

    if (widget.stats.streak >= 5) {
      rewardMessage = tr(widget.language, 'amazingStreak');
    } else if (widget.stats.streak >= 3) {
      rewardMessage = tr(widget.language, 'greatJob');
    } else {
      rewardMessage = '';
    }
  }

  void checkAnswer() {
    if (answered) return;

    final value = int.tryParse(_controller.text.trim());
    widget.stats.totalAttempts++;

    if (value == result) {
      widget.stats.correctAnswers++;
      widget.stats.stars++;
      widget.stats.streak++;
      if (widget.stats.streak > widget.stats.bestStreak) {
        widget.stats.bestStreak = widget.stats.streak;
      }
      adjustDifficulty();
      maybeUnlockRewards();
      updateRewardMessage();

      setState(() {
        isCorrect = true;
        answered = true;
        message = tr(widget.language, 'veryGood');
      });
    } else {
      widget.stats.wrongAnswers++;
      registerFailureByOperation();
      widget.stats.streak = 0;
      adjustDifficulty();

      setState(() {
        isCorrect = false;
        message = tr(widget.language, 'tryAgain');
        rewardMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.stats.successRate / 100).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${tr(widget.language, 'mathChallenge')} · ${widget.profile.name}',
        ),
        actions: [
          LanguageSwitcher(
            language: widget.language,
            onChanged: widget.onLanguageChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  PrettyCard(
                    color: const Color(0xFFEAEFFF),
                    child: Column(
                      children: [
                        Text(
                          avatarEmoji(widget.profile.avatarId),
                          style: const TextStyle(fontSize: 56),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tr(widget.language, 'age')}: ${widget.profile.age} ${tr(widget.language, 'years')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${tr(widget.language, 'difficulty')}: ${widget.stats.difficultyLevel}/5',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(widget.language, 'solveToUnlock'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '? ${widget.stats.stars}   ?? ${widget.stats.streak}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              tr(widget.language, 'progress'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.stats.successRate.toStringAsFixed(0)}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.indigo.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrettyCard(
                    child: Column(
                      children: [
                        Text(
                          '$a $operatorSymbol $b = ?',
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: tr(widget.language, 'answer'),
                          ),
                          onSubmitted: (_) => answered ? null : checkAnswer(),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: answered ? null : checkAnswer,
                            child: Text(
                              tr(widget.language, 'check'),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (rewardMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            rewardMessage,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (isCorrect)
                          OutlinedButton(
                            onPressed: generateQuestion,
                            child: Text(tr(widget.language, 'nextOperation')),
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () async {
                            await LocalStorageService.saveStats(
                              widget.profile.id,
                              widget.stats,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: Text(tr(widget.language, 'backToPanel')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AvatarSelectorScreen extends StatelessWidget {
  final String selectedAvatar;
  final List<String> unlockedAvatars;
  final AppLanguage language;

  const AvatarSelectorScreen({
    super.key,
    required this.selectedAvatar,
    required this.unlockedAvatars,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    const allAvatars = ['bear', 'robot', 'ninja', 'astronaut', 'fox', 'cat'];

    return Scaffold(
      appBar: AppBar(title: Text(tr(language, 'chooseAvatar'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PrettyCard(
              color: const Color(0xFFEAEFFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(language, 'avatars'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(tr(language, 'selectedAvatar')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: allAvatars.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, index) {
                final avatarId = allAvatars[index];
                final unlocked = unlockedAvatars.contains(avatarId);
                final selected = selectedAvatar == avatarId;

                return GestureDetector(
                  onTap: unlocked
                      ? () => Navigator.pop(context, avatarId)
                      : null,
                  child: PrettyCard(
                    color: selected
                        ? Colors.indigo.withOpacity(0.12)
                        : Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          avatarEmoji(avatarId),
                          style: const TextStyle(fontSize: 42),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          avatarLabel(language, avatarId),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          unlocked
                              ? (selected ? tr(language, 'selectedAvatar') : '')
                              : tr(language, 'lockedAvatar'),
                          style: TextStyle(
                            color: unlocked ? Colors.indigo : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BlockedAppsScreen extends StatefulWidget {
  final List<String> selectedApps;
  final AppLanguage language;

  const BlockedAppsScreen({
    super.key,
    required this.selectedApps,
    required this.language,
  });

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  late Map<String, bool> apps;

  @override
  void initState() {
    super.initState();
    apps = {
      for (final appId in kAppIds) appId: widget.selectedApps.contains(appId),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(widget.language, 'blockedApps'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PrettyCard(
              color: const Color(0xFFEAEFFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(widget.language, 'blockedAppsSubtitle'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(tr(widget.language, 'simulatedFeature')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...apps.entries.map(
              (entry) => PrettyCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SwitchListTile(
                  secondary: Icon(appIcon(entry.key)),
                  value: entry.value,
                  title: Text(appLabel(widget.language, entry.key)),
                  onChanged: (value) {
                    setState(() {
                      apps[entry.key] = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final selected = apps.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                Navigator.pop(context, selected);
              },
              child: Text(tr(widget.language, 'save')),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(widget.language, 'close')),
            ),
          ],
        ),
      ),
    );
  }
}

class ChildManagerScreen extends StatefulWidget {
  final List<ChildProfile> children;
  final String activeChildId;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ChildManagerScreen({
    super.key,
    required this.children,
    required this.activeChildId,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<ChildManagerScreen> createState() => _ChildManagerScreenState();
}

class _ChildManagerScreenState extends State<ChildManagerScreen> {
  late List<ChildProfile> children;

  @override
  void initState() {
    super.initState();
    children = List<ChildProfile>.from(widget.children);
  }

  Future<void> _deleteChild(ChildProfile child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(widget.language, 'deleteChild')),
        content: Text(tr(widget.language, 'deleteChildConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(widget.language, 'no')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(widget.language, 'yes')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    children.removeWhere((c) => c.id == child.id);
    await LocalStorageService.saveChildren(children);
    await LocalStorageService.deleteStats(child.id);
    await LocalStorageService.deleteBlockedApps(child.id);
    await LocalStorageService.deleteAndroidConfig(child.id);
    await LocalStorageService.deleteUnlockSessions(child.id);
    await LocalStorageService.deleteSetupDone(child.id);

    if (children.isEmpty) {
      await LocalStorageService.clearAll();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ParentLoginScreen(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ),
        (route) => false,
      );
      return;
    }

    if (child.id == widget.activeChildId) {
      await LocalStorageService.saveActiveChildId(children.first.id);
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(widget.language, 'childManager'))),
      body: SafeArea(
        child: children.isEmpty
            ? Center(child: Text(tr(widget.language, 'noChildren')))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final child = children[index];
                  final isActive = child.id == widget.activeChildId;

                  return PrettyCard(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(avatarEmoji(child.avatarId)),
                      ),
                      title: Text(child.name),
                      subtitle: Text(
                        '${child.age} ${tr(widget.language, 'years')}${isActive ? ' · ${tr(widget.language, 'activeChild')}' : ''}',
                      ),
                      onTap: () => Navigator.pop(context, child),
                      trailing: IconButton(
                        onPressed: () => _deleteChild(child),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildProfileScreen(
                language: widget.language,
                onLanguageChanged: widget.onLanguageChanged,
              ),
            ),
          );
          final refreshed = await LocalStorageService.loadChildren();
          if (!mounted) return;
          setState(() {
            children = refreshed;
          });
        },
        icon: const Icon(Icons.person_add),
        label: Text(tr(widget.language, 'addChild')),
      ),
    );
  }
}

class AndroidSetupResult {
  final AndroidConfig config;
  final List<UnlockSession> unlockSessions;

  AndroidSetupResult({required this.config, required this.unlockSessions});
}

class AndroidSetupScreen extends StatefulWidget {
  final AndroidConfig config;
  final List<String> blockedApps;
  final List<UnlockSession> unlockSessions;
  final AppLanguage language;

  const AndroidSetupScreen({
    super.key,
    required this.config,
    required this.blockedApps,
    required this.unlockSessions,
    required this.language,
  });

  @override
  State<AndroidSetupScreen> createState() => _AndroidSetupScreenState();
}

class _AndroidSetupScreenState extends State<AndroidSetupScreen>
    with WidgetsBindingObserver {
  late AndroidConfig config;
  late List<UnlockSession> unlockSessions;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    config = AndroidConfig(
      usageAccessGranted: widget.config.usageAccessGranted,
      overlayGranted: widget.config.overlayGranted,
      foregroundServiceGranted: widget.config.foregroundServiceGranted,
      unlockMinutes: widget.config.unlockMinutes,
    );
    unlockSessions = widget.unlockSessions.where((e) => e.isActive).toList();

    _syncPermissionsFromAndroid();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionsFromAndroid();
    }
  }

  Future<void> _syncPermissionsFromAndroid() async {
    if (!_isAndroid) return;

    try {
      final hasOverlay =
          await androidChannel.invokeMethod<bool>('canDrawOverlays') ?? false;
      final hasUsage =
          await androidChannel.invokeMethod<bool>('hasUsageAccess') ?? false;

      if (!mounted) return;
      setState(() {
        config.overlayGranted = hasOverlay;
        config.usageAccessGranted = hasUsage;
      });
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openUsageAccess() async {
    if (!_isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esto solo funciona en Android.')),
      );
      return;
    }

    await androidChannel.invokeMethod('openUsageAccessSettings');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activa el acceso de uso y vuelve a la app.'),
      ),
    );
  }

  Future<void> _openOverlayPermission() async {
    if (!_isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esto solo funciona en Android.')),
      );
      return;
    }

    await androidChannel.invokeMethod('openOverlaySettings');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activa mostrar sobre otras apps y vuelve.'),
      ),
    );
  }

  Future<void> _toggleForegroundService(bool value) async {
    if (!_isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esto solo funciona en Android.')),
      );
      return;
    }

    if (value && (!config.usageAccessGranted || !config.overlayGranted)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero activa Acceso de uso y Superposición.'),
        ),
      );
      return;
    }

    try {
      if (value) {
        await androidChannel.invokeMethod('startMonitorService');
      } else {
        await androidChannel.invokeMethod('stopMonitorService');
      }

      if (!mounted) return;
      setState(() {
        config.foregroundServiceGranted = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Servicio en primer plano activado' : 'Servicio detenido',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error con el servicio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSessions = unlockSessions.where((e) => e.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: Text(tr(widget.language, 'androidSetup'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PrettyCard(
              color: const Color(0xFFEAEFFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(widget.language, 'androidEngine'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(tr(widget.language, 'nativeBridgePending')),
                  const SizedBox(height: 10),
                  Text(
                    '${tr(widget.language, 'androidReadiness')}: ${config.isReady ? tr(widget.language, 'ready') : tr(widget.language, 'notReady')}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'permissions'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            PrettyCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    value: config.usageAccessGranted,
                    title: Text(tr(widget.language, 'usageAccess')),
                    subtitle: Text(
                      config.usageAccessGranted
                          ? tr(widget.language, 'permissionGranted')
                          : tr(widget.language, 'permissionMissing'),
                    ),
                    onChanged: (value) async {
                      if (value) {
                        await _openUsageAccess();
                      } else {
                        setState(() {
                          config.usageAccessGranted = false;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    value: config.overlayGranted,
                    title: Text(tr(widget.language, 'overlayPermission')),
                    subtitle: Text(
                      config.overlayGranted
                          ? tr(widget.language, 'permissionGranted')
                          : tr(widget.language, 'permissionMissing'),
                    ),
                    onChanged: (value) async {
                      if (value) {
                        await _openOverlayPermission();
                      } else {
                        setState(() {
                          config.overlayGranted = false;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    value: config.foregroundServiceGranted,
                    title: Text(tr(widget.language, 'foregroundService')),
                    subtitle: Text(
                      config.foregroundServiceGranted
                          ? tr(widget.language, 'permissionGranted')
                          : tr(widget.language, 'permissionMissing'),
                    ),
                    onChanged: _toggleForegroundService,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'unlockMinutes'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            PrettyCard(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 5, label: Text('5')),
                  ButtonSegment(value: 10, label: Text('10')),
                  ButtonSegment(value: 15, label: Text('15')),
                ],
                selected: {config.unlockMinutes},
                onSelectionChanged: (values) {
                  setState(() {
                    config.unlockMinutes = values.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'unlockStatus'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            PrettyCard(
              child: activeSessions.isEmpty
                  ? Text(tr(widget.language, 'noBlockedApps'))
                  : Column(
                      children: activeSessions
                          .map(
                            (session) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.lock_open),
                              title: Text(
                                appLabel(widget.language, session.appName),
                              ),
                              subtitle: Text(
                                '${tr(widget.language, 'unlockedUntil')} ${_formatDate(session.expiresAt)}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  AndroidSetupResult(
                    config: config,
                    unlockSessions: unlockSessions,
                  ),
                );
              },
              child: Text(tr(widget.language, 'save')),
            ),
          ],
        ),
      ),
    );
  }
}

class ProtectedAppsTestScreen extends StatefulWidget {
  final ChildProfile profile;
  final List<String> blockedApps;
  final AndroidConfig config;
  final List<UnlockSession> unlockSessions;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ProtectedAppsTestScreen({
    super.key,
    required this.profile,
    required this.blockedApps,
    required this.config,
    required this.unlockSessions,
    required this.language,
    required this.onLanguageChanged,
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

  String _debugPackageForApp(String appId) {
    switch (appId) {
      case 'youtube':
        return 'com.google.android.youtube';
      case 'calculator':
        return 'com.miui.calculator';
      case 'chrome':
        return 'com.android.chrome';
      case 'whatsapp':
        return 'com.whatsapp';
      case 'instagram':
        return 'com.instagram.android';
      case 'tiktok':
        return 'com.zhiliaoapp.musically';
      default:
        return appId;
    }
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

    final stats = AppStats(difficultyLevel: 1);
    final granted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProtectedAppGateScreen(
          profile: widget.profile,
          appName: appName,
          config: widget.config,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
          tempStats: stats,
        ),
      ),
    );

    if (granted == true) {
      final expiresAt = DateTime.now().add(
        Duration(minutes: widget.config.unlockMinutes),
      );

      try {
        await androidChannel.invokeMethod('setTemporaryUnlock', {
          'appId': appName,
          'unlockUntil': expiresAt.millisecondsSinceEpoch,
        });

        final debugPackage = _debugPackageForApp(appName);
        final nativeUnlockUntil = await androidChannel.invokeMethod<int>(
          'getTemporaryUnlockForPackage',
          {'packageName': debugPackage},
        );

        debugPrint('Paquete nativo: $debugPackage');
        debugPrint('unlockUntil guardado en Android: $nativeUnlockUntil');
        debugPrint('unlockUntil esperado: ${expiresAt.millisecondsSinceEpoch}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nativo guardado: $nativeUnlockUntil')),
          );
        }
      } catch (e) {
        debugPrint('Error guardando desbloqueo temporal nativo: $e');
      }

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

    debugPrint('ProtectedAppsTestScreen blockedApps: $blockedApps');
    debugPrint('ProtectedAppsTestScreen sessions: ${cleanedSessions.length}');

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

class ProtectedAppGateScreen extends StatefulWidget {
  final ChildProfile profile;
  final String appName;
  final AndroidConfig config;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppStats tempStats;

  const ProtectedAppGateScreen({
    super.key,
    required this.profile,
    required this.appName,
    required this.config,
    required this.language,
    required this.onLanguageChanged,
    required this.tempStats,
  });

  @override
  State<ProtectedAppGateScreen> createState() => _ProtectedAppGateScreenState();
}

class _ProtectedAppGateScreenState extends State<ProtectedAppGateScreen> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();

  int a = 0;
  int b = 0;
  int result = 0;
  String operatorSymbol = '+';
  String message = '';
  bool isCorrect = false;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final adjustedAge = widget.profile.age + widget.tempStats.difficultyLevel;

    if (adjustedAge <= 8) {
      final isSum = _random.nextBool();
      final max = 10 + (widget.tempStats.difficultyLevel * 2);
      a = _random.nextInt(max) + 1;
      b = _random.nextInt(max) + 1;
      if (isSum) {
        operatorSymbol = '+';
        result = a + b;
      } else {
        if (b > a) {
          final t = a;
          a = b;
          b = t;
        }
        operatorSymbol = '-';
        result = a - b;
      }
    } else if (adjustedAge <= 10) {
      final op = _random.nextInt(4);
      if (op == 0) {
        final max = 20 + (widget.tempStats.difficultyLevel * 3);
        a = _random.nextInt(max) + 1;
        b = _random.nextInt(max) + 1;
        operatorSymbol = '+';
        result = a + b;
      } else if (op == 1) {
        final max = 20 + (widget.tempStats.difficultyLevel * 3);
        a = _random.nextInt(max) + 1;
        b = _random.nextInt(max) + 1;
        if (b > a) {
          final t = a;
          a = b;
          b = t;
        }
        operatorSymbol = '-';
        result = a - b;
      } else if (op == 2) {
        final max = 9 + widget.tempStats.difficultyLevel;
        a = _random.nextInt(max) + 2;
        b = _random.nextInt(max) + 2;
        operatorSymbol = '×';
        result = a * b;
      } else {
        final max = 9 + widget.tempStats.difficultyLevel;
        b = _random.nextInt(max) + 2;
        result = _random.nextInt(max) + 2;
        a = b * result;
        operatorSymbol = '÷';
      }
    } else {
      final op = _random.nextInt(4);
      if (op == 0) {
        final max = 50 + (widget.tempStats.difficultyLevel * 10);
        a = _random.nextInt(max) + 10;
        b = _random.nextInt(max) + 10;
        operatorSymbol = '+';
        result = a + b;
      } else if (op == 1) {
        final maxA = 50 + (widget.tempStats.difficultyLevel * 10);
        final maxB = 30 + (widget.tempStats.difficultyLevel * 5);
        a = _random.nextInt(maxA) + 10;
        b = _random.nextInt(maxB) + 1;
        if (b > a) {
          final t = a;
          a = b;
          b = t;
        }
        operatorSymbol = '-';
        result = a - b;
      } else if (op == 2) {
        final max = 11 + widget.tempStats.difficultyLevel;
        a = _random.nextInt(max) + 2;
        b = _random.nextInt(max) + 2;
        operatorSymbol = '×';
        result = a * b;
      } else {
        final max = 11 + widget.tempStats.difficultyLevel;
        b = _random.nextInt(max) + 2;
        result = _random.nextInt(max) + 2;
        a = b * result;
        operatorSymbol = '÷';
      }
    }

    _controller.clear();
    message = '';
    isCorrect = false;
    answered = false;
    setState(() {});
  }

  void _checkAnswer() {
    if (answered) return;

    final value = int.tryParse(_controller.text.trim());
    if (value == result) {
      setState(() {
        isCorrect = true;
        answered = true;
        message = tr(widget.language, 'veryGood');
      });
    } else {
      setState(() {
        isCorrect = false;
        message = tr(widget.language, 'tryAgain');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${tr(widget.language, 'protectedArea')} · ${appLabel(widget.language, widget.appName)}',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  PrettyCard(
                    color: const Color(0xFFEAEFFF),
                    child: Column(
                      children: [
                        const Icon(Icons.shield, size: 68),
                        const SizedBox(height: 14),
                        Text(
                          tr(widget.language, 'thisAppWouldBeBlocked'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(widget.language, 'requireMathBeforeOpen'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrettyCard(
                    child: Column(
                      children: [
                        Text(
                          '$a $operatorSymbol $b = ?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: tr(widget.language, 'answer'),
                          ),
                          onSubmitted: (_) => answered ? null : _checkAnswer(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: answered ? null : _checkAnswer,
                            child: Text(tr(widget.language, 'check')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 18),
                        if (isCorrect)
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(tr(widget.language, 'unlockNow')),
                          ),
                        if (!isCorrect) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _generateQuestion,
                            child: Text(tr(widget.language, 'nextOperation')),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
