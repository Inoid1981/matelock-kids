import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/android_config.dart';
import 'models/app_stats.dart';
import 'models/child_profile.dart';
import 'models/unlock_session.dart';
import 'screens/avatar_selector_screen.dart';
import 'screens/blocked_apps_screen.dart';
import 'screens/change_parent_pin_screen.dart';
import 'screens/create_parent_pin_screen.dart';
import 'screens/child_manager_screen.dart';
import 'screens/child_profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/internal_pin_check_screen.dart';
import 'screens/parent_account_screen.dart';
import 'screens/parent_login_screen.dart';
import 'screens/parent_pin_gate_screen.dart';
import 'screens/protected_apps_test_screen.dart';
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
  String parentPin = '';
  AndroidConfig androidConfig = AndroidConfig();
  List<UnlockSession> unlockSessions = [];
  bool setupDone = false;
  String? _pendingBlockedAppId;

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
      // ⚡ Capturar app pendiente (intercepción)
      if (selectedChild != null &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        try {
          final pendingApp = await androidChannel.invokeMethod<String>(
            'peekPendingBlockedApp',
          );
          if (pendingApp != null && pendingApp.isNotEmpty) {
            _pendingBlockedAppId = pendingApp;
          }
        } catch (_) {}
      }
    }
    if (selectedChild != null &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        final pendingApp = await androidChannel.invokeMethod<String>(
          'peekPendingBlockedApp',
        );
        print('🔍 Pending app: $pendingApp'); // <-- AÑADE ESTO
        if (pendingApp != null && pendingApp.isNotEmpty) {
          _pendingBlockedAppId = pendingApp;
        }
      } catch (e) {
        print('❌ Error peek: $e'); // <-- Y ESTO
      }
    }
    setState(() {
      children = loadedChildren;
      activeChild = selectedChild;
      stats = loadedStats;
      blockedApps = loadedBlockedApps;
      parentPin = loadedPin ?? '';
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
    // 🔥 Si venimos de una intercepción, mostrar el reto matemático directamente
    if (_pendingBlockedAppId != null && activeChild != null) {
      return InterceptedAppGateScreen(
        childId: activeChild!.id,
        appName: _pendingBlockedAppId!,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      );
    }
    if (children.isEmpty || activeChild == null) {
      return ParentLoginScreen(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
        parentPin: parentPin,
        createFirstProfileBuilder: (_) => ChildProfileScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
          afterCreateBuilder: (_) => CreateParentPinScreen(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
            nextScreenBuilder: (_) => StartupScreen(
              language: widget.language,
              onLanguageChanged: widget.onLanguageChanged,
            ),
          ),
        ),
      );
    }

    if (parentPin.isEmpty || parentPin == '1234') {
      return CreateParentPinScreen(
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
        nextScreenBuilder: (_) => StartupScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      );
    }

    if (!setupDone) {
      return InitialSetupScreen(
        childId: activeChild!.id,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      );
    }

    return ParentPinGateScreen(
      parentPin: parentPin,
      language: widget.language,
      onLanguageChanged: widget.onLanguageChanged,
      dashboardBuilder: (_) => ParentDashboardScreen(
        children: children,
        activeChild: activeChild!,
        stats: stats,
        blockedApps: blockedApps,
        parentPin: parentPin,
        androidConfig: androidConfig,
        unlockSessions: unlockSessions,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
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
  bool _handlingPendingBlockedApp = false;
  bool _pendingProtectionActivation = false;
  bool _openingPendingBlockedApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handlePendingBlockedAppIfAny();
      }
    });
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingBlockedAppAndOpenGate();
    });
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _checkPendingBlockedAppAndOpenGate() async {
    if (!_isAndroid) return;
    if (_openingPendingBlockedApp) return;
    if (!mounted) return;

    try {
      final pendingApp = await androidChannel.invokeMethod<String>(
        'consumePendingBlockedApp',
      );

      if (!mounted) return;
      if (pendingApp == null || pendingApp.isEmpty) return;
      if (!blockedApps.contains(pendingApp)) return;

      _openingPendingBlockedApp = true;

      final granted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ProtectedAppGateScreen(
            profile: activeChild,
            appName: pendingApp,
            config: androidConfig,
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
            tempStats: AppStats(difficultyLevel: 1),
          ),
        ),
      );

      if (granted == true) {
        final expiresAt = DateTime.now().add(
          Duration(minutes: androidConfig.unlockMinutes),
        );

        try {
          await androidChannel.invokeMethod('setTemporaryUnlock', {
            'appId': pendingApp,
            'unlockUntil': expiresAt.millisecondsSinceEpoch,
          });
        } catch (e) {
          debugPrint(
            'Error guardando desbloqueo temporal desde bloqueo real: $e',
          );
        }

        unlockSessions.removeWhere((e) => e.appName == pendingApp);
        unlockSessions.add(
          UnlockSession(appName: pendingApp, expiresAt: expiresAt),
        );

        await LocalStorageService.saveUnlockSessions(
          activeChild.id,
          unlockSessions,
        );

        try {
          await Future.delayed(const Duration(milliseconds: 300));
          await androidChannel.invokeMethod<bool>('openAppById', {
            'appId': pendingApp,
          });
        } catch (e) {
          debugPrint('Error abriendo app real: $e');
        }

        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error leyendo app bloqueada pendiente: $e');
    } finally {
      _openingPendingBlockedApp = false;
    }
  }

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

      if (!hasOverlay) {
        await androidChannel.invokeMethod('openOverlaySettings');
        return;
      }

      final hasUsageAccess =
          await androidChannel.invokeMethod<bool>('hasUsageAccess') ?? false;

      if (!hasUsageAccess) {
        await androidChannel.invokeMethod('openUsageAccessSettings');
        return;
      }

      final isDeviceAdminActive =
          await androidChannel.invokeMethod<bool>('isDeviceAdminActive') ??
          false;

      if (!isDeviceAdminActive) {
        await androidChannel.invokeMethod('requestDeviceAdmin');
        return;
      }

      await androidChannel.invokeMethod('startMonitorService');

      androidConfig.overlayGranted = true;
      androidConfig.usageAccessGranted = true;
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (!mounted) return;

        await _refreshAndroidPermissionStatus();

        if (_pendingProtectionActivation) {
          await _resumeProtectionActivation();
          return;
        }

        await _handlePendingBlockedAppIfAny();
      });
    }
  }

  Future<void> _handlePendingBlockedAppIfAny() async {
    if (_handlingPendingBlockedApp) return;
    _handlingPendingBlockedApp = true;

    try {
      // Usamos peek para ver el ID sin consumirlo aún
      final appId = await androidChannel.invokeMethod<String>(
        'peekPendingBlockedApp',
      );

      if (appId == null || appId.isEmpty) {
        return;
      }

      // Apps que requieren PIN parental en lugar de reto matemático
      const appsConPinParental = {
        'settings',
        'play_store',
        'package_installer',
      };

      if (appsConPinParental.contains(appId)) {
        // 1. Consumimos el evento
        await androidChannel.invokeMethod('consumePendingBlockedApp');

        // 2. Pedimos el PIN
        final allowed = await _askForPin();
        if (!mounted || !allowed) return;

        // 3. Desbloqueamos temporalmente y abrimos la app
        final unlockUntil = DateTime.now()
            .add(const Duration(minutes: 3))
            .millisecondsSinceEpoch;

        await androidChannel.invokeMethod('setTemporaryUnlock', {
          'appId': appId,
          'unlockUntil': unlockUntil,
        });

        await androidChannel.invokeMethod('openAppById', {'appId': appId});
      } else {
        // 🔥 App normal bloqueada: mostramos el reto matemático
        // No consumimos aquí; lo hará _checkPendingBlockedAppAndOpenGate()
        // De hecho, podemos invocar directamente el método que ya existe.
        // Como alternativa, copiamos y adaptamos la lógica para evitar
        // interferencias con el flag _openingPendingBlockedApp.

        // Aseguramos que no se esté abriendo otro gate al mismo tiempo
        if (_openingPendingBlockedApp) return;

        _openingPendingBlockedApp = true;

        // Consumimos la app pendiente
        final pendingApp = await androidChannel.invokeMethod<String>(
          'consumePendingBlockedApp',
        );

        if (!mounted || pendingApp == null || pendingApp.isEmpty) {
          _openingPendingBlockedApp = false;
          return;
        }

        // Verificamos que esté en la lista de bloqueadas
        if (!blockedApps.contains(pendingApp)) {
          _openingPendingBlockedApp = false;
          return;
        }

        // Mostramos el reto matemático
        final granted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ProtectedAppGateScreen(
              profile: activeChild,
              appName: pendingApp,
              config: androidConfig,
              language: widget.language,
              onLanguageChanged: widget.onLanguageChanged,
              tempStats: AppStats(difficultyLevel: 1),
            ),
          ),
        );

        if (granted == true) {
          final expiresAt = DateTime.now().add(
            Duration(minutes: androidConfig.unlockMinutes),
          );

          await androidChannel.invokeMethod('setTemporaryUnlock', {
            'appId': pendingApp,
            'unlockUntil': expiresAt.millisecondsSinceEpoch,
          });

          unlockSessions.removeWhere((e) => e.appName == pendingApp);
          unlockSessions.add(
            UnlockSession(appName: pendingApp, expiresAt: expiresAt),
          );

          await LocalStorageService.saveUnlockSessions(
            activeChild.id,
            unlockSessions,
          );

          await Future.delayed(const Duration(milliseconds: 300));
          await androidChannel.invokeMethod<bool>('openAppById', {
            'appId': pendingApp,
          });
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error handling pending blocked app: $e');
    } finally {
      _handlingPendingBlockedApp = false;
      _openingPendingBlockedApp = false;
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
          parentPin: '',
          createFirstProfileBuilder: (_) => ChildProfileScreen(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
            afterCreateBuilder: (_) => CreateParentPinScreen(
              language: widget.language,
              onLanguageChanged: widget.onLanguageChanged,
              nextScreenBuilder: (_) => StartupScreen(
                language: widget.language,
                onLanguageChanged: widget.onLanguageChanged,
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  Future<bool> _askForPin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InternalPinCheckScreen(
          parentPin: parentPin,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    return result ?? false;
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
          loginBuilder: (_) => ParentLoginScreen(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
            parentPin: '',
            createFirstProfileBuilder: (_) => ChildProfileScreen(
              language: widget.language,
              onLanguageChanged: widget.onLanguageChanged,
              afterCreateBuilder: (_) => CreateParentPinScreen(
                language: widget.language,
                onLanguageChanged: widget.onLanguageChanged,
                nextScreenBuilder: (_) => StartupScreen(
                  language: widget.language,
                  onLanguageChanged: widget.onLanguageChanged,
                ),
              ),
            ),
          ),
          addChildBuilder: (_) => ChildProfileScreen(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ),
      ),
    );

    if (selected == null) return;

    await LocalStorageService.saveActiveChildId(selected.id);
    final selectedSetupDone = await LocalStorageService.loadSetupDone(
      selected.id,
    );

    if (!mounted) return;

    if (!selectedSetupDone) {
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

    final refreshedChildren = await LocalStorageService.loadChildren();
    final refreshedStats = await LocalStorageService.loadStats(selected.id);
    final refreshedBlockedApps = await LocalStorageService.loadBlockedApps(
      selected.id,
    );
    final refreshedAndroidConfig = await LocalStorageService.loadAndroidConfig(
      selected.id,
    );
    final refreshedUnlocks = await LocalStorageService.loadUnlockSessions(
      selected.id,
    );

    ChildProfile refreshedActiveChild = selected;
    try {
      refreshedActiveChild = refreshedChildren.firstWhere(
        (c) => c.id == selected.id,
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
          onRequestOpenApp: (appName) async {
            final stats = AppStats(difficultyLevel: 1);

            final granted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ProtectedAppGateScreen(
                  profile: activeChild,
                  appName: appName,
                  config: androidConfig,
                  language: widget.language,
                  onLanguageChanged: widget.onLanguageChanged,
                  tempStats: stats,
                ),
              ),
            );

            if (granted == true) {
              await androidChannel.invokeMethod<bool>('openAppById', {
                'appId': appName,
              });
            }

            return granted;
          },
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

  Future<void> _openChangePinScreen() async {
    final updatedPin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeParentPinScreen(
          currentPin: parentPin,
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    if (updatedPin != null && mounted) {
      setState(() {
        parentPin = updatedPin;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == AppLanguage.spanish
                ? 'PIN parental actualizado'
                : 'Parent PIN updated',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final isSpanish = widget.language == AppLanguage.spanish;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSpanish ? 'Cerrar sesión' : 'Sign out'),
        content: Text(
          isSpanish
              ? '¿Quieres cerrar la sesión parental?'
              : 'Do you want to sign out of the parent session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isSpanish ? 'Cerrar sesión' : 'Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ParentLoginScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
          parentPin: widget.parentPin,
          createFirstProfileBuilder: (_) => ChildProfileScreen(
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
            afterCreateBuilder: (_) => CreateParentPinScreen(
              language: widget.language,
              onLanguageChanged: widget.onLanguageChanged,
              nextScreenBuilder: (_) => StartupScreen(
                language: widget.language,
                onLanguageChanged: widget.onLanguageChanged,
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _openParentAccountScreen() async {
    final allowed = await _askForPin();
    if (!allowed || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ParentAccountScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == AppLanguage.spanish
                ? 'Cuenta parental guardada'
                : 'Parent account saved',
          ),
        ),
      );
    }
  }

  Future<void> _evaluateDashboardAchievements() async {
    if (blockedApps.length >= 3) {
      _addAchievement('apps_3');
    }
    await LocalStorageService.saveStats(activeChild.id, stats);
    if (mounted) {
      setState(() {});
    }
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
        value: '★ ${stats.stars}',
        icon: Icons.star_outline,
      ),
      _StatCard(
        title: tr(widget.language, 'bestStreak'),
        value: 'Racha ${stats.bestStreak}',
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
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: widget.language == AppLanguage.spanish
                ? 'Cerrar sesión'
                : 'Sign out',
          ),
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
              onPressed: _openChangePinScreen,
              icon: const Icon(Icons.password),
              label: Text(
                widget.language == AppLanguage.spanish
                    ? 'Cambiar PIN parental'
                    : 'Change parent PIN',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openParentAccountScreen,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text(
                widget.language == AppLanguage.spanish
                    ? 'Cuenta parental'
                    : 'Parent account',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openProtectedAppsTester,
              icon: const Icon(Icons.lock_open),
              label: Text(tr(widget.language, 'testProtectedApps')),
            ),
            const SizedBox(height: 12),
            Text(
              widget.language == AppLanguage.spanish
                  ? 'PIN parental configurado'
                  : 'Parent PIN configured',
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
      rewardMessage = 'Recompensa: ${tr(widget.language, 'robotAvatar')}';
    }

    if (widget.stats.stars >= 20 &&
        !widget.stats.unlockedAvatars.contains('ninja')) {
      widget.stats.unlockedAvatars.add('ninja');
      rewardMessage = 'Recompensa: ${tr(widget.language, 'ninjaAvatar')}';
    }

    if (widget.stats.stars >= 35 &&
        !widget.stats.unlockedAvatars.contains('astronaut')) {
      widget.stats.unlockedAvatars.add('astronaut');
      rewardMessage = 'Recompensa: ${tr(widget.language, 'astronautAvatar')}';
    }

    if (widget.stats.stars >= 50 &&
        !widget.stats.unlockedAvatars.contains('fox')) {
      widget.stats.unlockedAvatars.add('fox');
      rewardMessage = 'Recompensa: ${tr(widget.language, 'foxAvatar')}';
    }

    if (widget.stats.stars >= 75 &&
        !widget.stats.unlockedAvatars.contains('cat')) {
      widget.stats.unlockedAvatars.add('cat');
      rewardMessage = 'Recompensa: ${tr(widget.language, 'catAvatar')}';
    }

    void addAchievement(String id) {
      if (!widget.stats.achievements.contains(id)) {
        widget.stats.achievements.add(id);
        rewardMessage = 'Logro: ${achievementLabel(widget.language, id)}';
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
                          '★ ${widget.stats.stars}   Racha ${widget.stats.streak}',
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

  Future<void> _checkAnswer() async {
    if (answered) return;

    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;

    if (value == result) {
      HapticFeedback.lightImpact();
      setState(() {
        isCorrect = true;
        answered = true;
        message = tr(widget.language, 'veryGood');
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      _controller.clear();

      setState(() {
        HapticFeedback.heavyImpact();
        isCorrect = false;
        message = tr(widget.language, 'tryAgain');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appNameLabel = appLabel(widget.language, widget.appName);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(appNameLabel),
        centerTitle: true,
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
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(appIcon(widget.appName), size: 42),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appNameLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(widget.language, 'requireMathBeforeOpen'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrettyCard(
                    child: Column(
                      children: [
                        Text(
                          tr(widget.language, 'solveToUnlock'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$a $operatorSymbol $b = ?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: tr(widget.language, 'answer'),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => answered ? null : _checkAnswer(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                answered || _controller.text.trim().isEmpty
                                ? null
                                : _checkAnswer,
                            child: Text(
                              tr(widget.language, 'check'),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.withOpacity(0.10)
                                  : Colors.red.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (!isCorrect) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _generateQuestion,
                              icon: const Icon(Icons.refresh),
                              label: Text(tr(widget.language, 'nextOperation')),
                            ),
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

class InterceptedAppGateScreen extends StatefulWidget {
  final String childId;
  final String appName;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const InterceptedAppGateScreen({
    super.key,
    required this.childId,
    required this.appName,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<InterceptedAppGateScreen> createState() =>
      _InterceptedAppGateScreenState();
}

class _InterceptedAppGateScreenState extends State<InterceptedAppGateScreen> {
  bool _loading = true;
  late ChildProfile _child;
  late AppStats _stats;
  late AndroidConfig _config;

  @override
  void initState() {
    super.initState();
    _loadMinimalData();
  }

  Future<void> _loadMinimalData() async {
    try {
      final children = await LocalStorageService.loadChildren();
      final child = children.firstWhere((c) => c.id == widget.childId);
      final stats = await LocalStorageService.loadStats(widget.childId);
      final config = await LocalStorageService.loadAndroidConfig(
        widget.childId,
      );

      // Consumir la app pendiente para que no se vuelva a interceptar
      await androidChannel.invokeMethod('consumePendingBlockedApp');

      if (!mounted) return;
      setState(() {
        _child = child;
        _stats = stats;
        _config = config;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ProtectedAppGateScreen(
      profile: _child,
      appName: widget.appName,
      config: _config,
      language: widget.language,
      onLanguageChanged: widget.onLanguageChanged,
      tempStats: _stats,
    );
  }
}
