import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MateLockKidsApp());
}

enum AppLanguage { spanish, english }

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F8EF7)),
        useMaterial3: true,
      ),
      home: StartupScreen(
        language: language,
        onLanguageChanged: changeLanguage,
      ),
    );
  }
}

String tr(AppLanguage lang, String key) {
  const es = {
    'appTitle': 'MateLock Kids',
    'tagline': 'Aprender para desbloquear',
    'email': 'Email',
    'password': 'Contraseña',
    'login': 'Entrar',
    'childProfile': 'Perfil del niño',
    'createProfile': 'Crear perfil',
    'editProfile': 'Editar perfil',
    'name': 'Nombre',
    'age': 'Edad',
    'saveContinue': 'Guardar y continuar',
    'saving': 'Guardando...',
    'parentsPanel': 'Panel de padres',
    'summary': 'Resumen',
    'hits': 'Aciertos',
    'attempts': 'Intentos',
    'fails': 'Fallos',
    'mostFails': 'Más fallos',
    'none': 'Ninguna',
    'automaticLevel': 'Nivel automático activado',
    'mathChallenge': 'Reto matemático',
    'solveToUnlock': 'Resuelve para desbloquear',
    'answer': 'Respuesta',
    'check': 'Comprobar',
    'nextOperation': 'Siguiente operación',
    'backToPanel': 'Volver al panel',
    'veryGood': '¡Muy bien! Acceso concedido',
    'tryAgain': 'Incorrecto. Inténtalo otra vez',
    'additions': 'Sumas',
    'subtractions': 'Restas',
    'multiplications': 'Multiplicaciones',
    'divisions': 'Divisiones',
    'resetData': 'Reiniciar datos',
    'enterNameAge': 'Introduce el nombre y selecciona la edad.',
    'years': 'años',
    'childDefault': 'Niño',
    'profileOfChild': 'Perfil del niño',
    'testMathChallenge': 'Probar reto matemático',
    'stars': 'Estrellas',
    'streak': 'Racha',
    'amazingStreak': '🔥 ¡Increíble racha!',
    'greatJob': '👏 ¡Muy bien!',
    'blockedApps': 'Apps protegidas',
    'blockedAppsSubtitle': 'Selección de apps a proteger',
    'save': 'Guardar',
    'parentPin': 'PIN parental',
    'enterPin': 'Introduce el PIN',
    'wrongPin': 'PIN incorrecto',
    'accessAllowed': 'Acceso permitido',
    'cancel': 'Cancelar',
    'confirm': 'Confirmar',
    'selectedApps': 'Apps seleccionadas',
    'noBlockedApps': 'No hay apps protegidas',
    'simulatedFeature': 'Función simulada',
    'close': 'Cerrar',
    'rewardMessage': '¡Vas genial!',
    'pinHint': 'PIN actual: 1234',
    'protectedArea': 'Zona protegida',
    'children': 'Niños',
    'selectChild': 'Seleccionar niño',
    'addChild': 'Añadir niño',
    'switchChild': 'Cambiar niño',
    'noChildren': 'No hay perfiles creados',
    'childManager': 'Gestión de perfiles',
    'activeChild': 'Niño activo',
    'deleteChild': 'Eliminar niño',
    'deleteChildConfirm': '¿Seguro que quieres eliminar este perfil?',
    'yes': 'Sí',
    'no': 'No',
    'createFirstChild': 'Crear primer perfil',
    'androidReady': 'Android Ready',
    'androidSetup': 'Configuración Android',
    'permissions': 'Permisos',
    'usageAccess': 'Acceso a uso',
    'overlayPermission': 'Mostrar sobre otras apps',
    'foregroundService': 'Servicio en primer plano',
    'permissionGranted': 'Concedido',
    'permissionMissing': 'Pendiente',
    'androidReadiness': 'Estado Android',
    'ready': 'Listo',
    'notReady': 'Pendiente',
    'unlockMinutes': 'Minutos de desbloqueo',
    'unlockNow': 'Desbloquear ahora',
    'unlockStatus': 'Desbloqueo temporal',
    'locked': 'Protegida',
    'unlockedUntil': 'Desbloqueada hasta',
    'expired': 'Caducado',
    'testProtectedApps': 'Probar apps protegidas',
    'openProtectedApp': 'Abrir app protegida',
    'thisAppWouldBeBlocked': 'Esta app quedaría protegida en Android real',
    'requireMathBeforeOpen':
        'Aquí pediríamos la operación antes de abrir la app',
    'androidEngine': 'Motor Android',
    'nativeBridgePending': 'Puente nativo pendiente',
    'configureAndroid': 'Configurar Android',
    'bestStreak': 'Mejor racha',
    'difficulty': 'Dificultad',
  };

  const en = {
    'appTitle': 'MateLock Kids',
    'tagline': 'Learn to unlock',
    'email': 'Email',
    'password': 'Password',
    'login': 'Log in',
    'childProfile': 'Child profile',
    'createProfile': 'Create profile',
    'editProfile': 'Edit profile',
    'name': 'Name',
    'age': 'Age',
    'saveContinue': 'Save and continue',
    'saving': 'Saving...',
    'parentsPanel': 'Parents dashboard',
    'summary': 'Summary',
    'hits': 'Correct',
    'attempts': 'Attempts',
    'fails': 'Wrong',
    'mostFails': 'Most failed',
    'none': 'None',
    'automaticLevel': 'Automatic level enabled',
    'mathChallenge': 'Math challenge',
    'solveToUnlock': 'Solve to unlock',
    'answer': 'Answer',
    'check': 'Check',
    'nextOperation': 'Next operation',
    'backToPanel': 'Back to dashboard',
    'veryGood': 'Great! Access granted',
    'tryAgain': 'Incorrect. Try again',
    'additions': 'Additions',
    'subtractions': 'Subtractions',
    'multiplications': 'Multiplications',
    'divisions': 'Divisions',
    'resetData': 'Reset data',
    'enterNameAge': 'Enter the name and select the age.',
    'years': 'years',
    'childDefault': 'Child',
    'profileOfChild': 'Child profile',
    'testMathChallenge': 'Try math challenge',
    'stars': 'Stars',
    'streak': 'Streak',
    'amazingStreak': '🔥 Amazing streak!',
    'greatJob': '👏 Great job!',
    'blockedApps': 'Protected apps',
    'blockedAppsSubtitle': 'Select apps to protect',
    'save': 'Save',
    'parentPin': 'Parent PIN',
    'enterPin': 'Enter PIN',
    'wrongPin': 'Wrong PIN',
    'accessAllowed': 'Access granted',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'selectedApps': 'Selected apps',
    'noBlockedApps': 'No protected apps',
    'simulatedFeature': 'Simulated feature',
    'close': 'Close',
    'rewardMessage': 'You are doing great!',
    'pinHint': 'Current PIN: 1234',
    'protectedArea': 'Protected area',
    'children': 'Children',
    'selectChild': 'Select child',
    'addChild': 'Add child',
    'switchChild': 'Switch child',
    'noChildren': 'No profiles created',
    'childManager': 'Profile manager',
    'activeChild': 'Active child',
    'deleteChild': 'Delete child',
    'deleteChildConfirm': 'Are you sure you want to delete this profile?',
    'yes': 'Yes',
    'no': 'No',
    'createFirstChild': 'Create first profile',
    'androidReady': 'Android Ready',
    'androidSetup': 'Android setup',
    'permissions': 'Permissions',
    'usageAccess': 'Usage access',
    'overlayPermission': 'Draw over other apps',
    'foregroundService': 'Foreground service',
    'permissionGranted': 'Granted',
    'permissionMissing': 'Pending',
    'androidReadiness': 'Android status',
    'ready': 'Ready',
    'notReady': 'Pending',
    'unlockMinutes': 'Unlock minutes',
    'unlockNow': 'Unlock now',
    'unlockStatus': 'Temporary unlock',
    'locked': 'Protected',
    'unlockedUntil': 'Unlocked until',
    'expired': 'Expired',
    'testProtectedApps': 'Test protected apps',
    'openProtectedApp': 'Open protected app',
    'thisAppWouldBeBlocked': 'This app would be protected on real Android',
    'requireMathBeforeOpen':
        'Here we would require the math challenge before opening the app',
    'androidEngine': 'Android engine',
    'nativeBridgePending': 'Native bridge pending',
    'configureAndroid': 'Configure Android',
    'bestStreak': 'Best streak',
    'difficulty': 'Difficulty',
  };

  return (lang == AppLanguage.spanish ? es : en)[key] ?? key;
}

class ChildProfile {
  final String id;
  final String name;
  final int age;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? 'Niño',
      age: map['age'] ?? 9,
    );
  }
}

class AppStats {
  int totalAttempts;
  int correctAnswers;
  int wrongAnswers;
  int wrongAdditions;
  int wrongSubtractions;
  int wrongMultiplications;
  int wrongDivisions;
  int stars;
  int streak;
  int bestStreak;
  int difficultyLevel;

  AppStats({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.wrongAdditions = 0,
    this.wrongSubtractions = 0,
    this.wrongMultiplications = 0,
    this.wrongDivisions = 0,
    this.stars = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.difficultyLevel = 1,
  });

  double get successRate {
    if (totalAttempts == 0) return 0;
    return (correctAnswers / totalAttempts) * 100;
  }

  String mostFailedOperation(AppLanguage language) {
    final failures = {
      tr(language, 'additions'): wrongAdditions,
      tr(language, 'subtractions'): wrongSubtractions,
      tr(language, 'multiplications'): wrongMultiplications,
      tr(language, 'divisions'): wrongDivisions,
    };

    String result = tr(language, 'none');
    int maxValue = 0;

    failures.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
        result = key;
      }
    });

    if (maxValue == 0) return tr(language, 'none');
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAttempts': totalAttempts,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'wrongAdditions': wrongAdditions,
      'wrongSubtractions': wrongSubtractions,
      'wrongMultiplications': wrongMultiplications,
      'wrongDivisions': wrongDivisions,
      'stars': stars,
      'streak': streak,
      'bestStreak': bestStreak,
      'difficultyLevel': difficultyLevel,
    };
  }

  factory AppStats.fromMap(Map<String, dynamic> map) {
    return AppStats(
      totalAttempts: map['totalAttempts'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      wrongAdditions: map['wrongAdditions'] ?? 0,
      wrongSubtractions: map['wrongSubtractions'] ?? 0,
      wrongMultiplications: map['wrongMultiplications'] ?? 0,
      wrongDivisions: map['wrongDivisions'] ?? 0,
      stars: map['stars'] ?? 0,
      streak: map['streak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      difficultyLevel: map['difficultyLevel'] ?? 1,
    );
  }
}

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

class LocalStorageService {
  static const String childrenKey = 'children_profiles';
  static const String activeChildIdKey = 'active_child_id';
  static const String blockedAppsPrefix = 'blocked_apps_';
  static const String statsPrefix = 'app_stats_';
  static const String androidConfigPrefix = 'android_config_';
  static const String unlockSessionsPrefix = 'unlock_sessions_';
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
      String childId, AndroidConfig config) async {
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
      String childId, List<UnlockSession> sessions) async {
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

  static Future<void> saveParentPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(parentPinKey, pin);
  }

  static Future<String> loadParentPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(parentPinKey) ?? '1234';
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
          key.startsWith(unlockSessionsPrefix)) {
        await prefs.remove(key);
      }
    }
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

    if (selectedChild != null) {
      loadedStats = await LocalStorageService.loadStats(selectedChild.id);
      loadedBlockedApps =
          await LocalStorageService.loadBlockedApps(selectedChild.id);
      loadedAndroidConfig =
          await LocalStorageService.loadAndroidConfig(selectedChild.id);
      loadedSessions =
          await LocalStorageService.loadUnlockSessions(selectedChild.id);
      loadedSessions = loadedSessions.where((e) => e.isActive).toList();
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
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (children.isEmpty || activeChild == null) {
      return ParentLoginScreen(
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

class LanguageSwitcher extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  const LanguageSwitcher({
    super.key,
    required this.language,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AppLanguage>(
      value: language,
      underline: const SizedBox(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      items: const [
        DropdownMenuItem(
          value: AppLanguage.spanish,
          child: Text('ES'),
        ),
        DropdownMenuItem(
          value: AppLanguage.english,
          child: Text('EN'),
        ),
      ],
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
          LanguageSwitcher(
            language: language,
            onChanged: onLanguageChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr(language, 'appTitle'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(language, 'tagline'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    decoration: InputDecoration(
                      labelText: tr(language, 'email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: tr(language, 'password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
      profile = ChildProfile(
        id: widget.existingProfile!.id,
        name: name,
        age: _selectedAge,
      );
      final index = children.indexWhere((c) => c.id == profile.id);
      if (index != -1) {
        children[index] = profile;
      }
    } else {
      profile = ChildProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        age: _selectedAge,
      );
      children.add(profile);
      await LocalStorageService.saveStats(profile.id, AppStats());
      await LocalStorageService.saveBlockedApps(profile.id, []);
      await LocalStorageService.saveAndroidConfig(profile.id, AndroidConfig());
      await LocalStorageService.saveUnlockSessions(profile.id, []);
    }

    await LocalStorageService.saveChildren(children);
    await LocalStorageService.saveActiveChildId(profile.id);
    await LocalStorageService.saveParentPin('1234');

    final stats = await LocalStorageService.loadStats(profile.id);
    final blockedApps = await LocalStorageService.loadBlockedApps(profile.id);
    final androidConfig =
        await LocalStorageService.loadAndroidConfig(profile.id);
    final unlockSessions =
        await LocalStorageService.loadUnlockSessions(profile.id);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ParentDashboardScreen(
          children: children,
          activeChild: profile,
          stats: stats,
          blockedApps: blockedApps,
          parentPin: '1234',
          androidConfig: androidConfig,
          unlockSessions: unlockSessions,
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existingProfile == null
                        ? tr(widget.language, 'createProfile')
                        : tr(widget.language, 'editProfile'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr(widget.language, 'age'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                    height: 52,
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

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late List<ChildProfile> children;
  late ChildProfile activeChild;
  late AppStats stats;
  late List<String> blockedApps;
  late String parentPin;
  late AndroidConfig androidConfig;
  late List<UnlockSession> unlockSessions;

  @override
  void initState() {
    super.initState();
    children = List<ChildProfile>.from(widget.children);
    activeChild = widget.activeChild;
    stats = widget.stats;
    blockedApps = List<String>.from(widget.blockedApps);
    parentPin = widget.parentPin;
    androidConfig = widget.androidConfig;
    unlockSessions = List<UnlockSession>.from(widget.unlockSessions)
        .where((e) => e.isActive)
        .toList();
  }

  Future<void> _refreshActiveChild() async {
    final refreshedChildren = await LocalStorageService.loadChildren();
    final refreshedStats = await LocalStorageService.loadStats(activeChild.id);
    final refreshedBlockedApps =
        await LocalStorageService.loadBlockedApps(activeChild.id);
    final refreshedAndroidConfig =
        await LocalStorageService.loadAndroidConfig(activeChild.id);
    final refreshedUnlocks =
        await LocalStorageService.loadUnlockSessions(activeChild.id);
    ChildProfile refreshedActiveChild = activeChild;
    try {
      refreshedActiveChild =
          refreshedChildren.firstWhere((c) => c.id == activeChild.id);
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      children = refreshedChildren;
      activeChild = refreshedActiveChild;
      stats = refreshedStats;
      blockedApps = refreshedBlockedApps;
      androidConfig = refreshedAndroidConfig;
      unlockSessions = refreshedUnlocks.where((e) => e.isActive).toList();
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
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
    if (mounted) {
      setState(() {});
    }
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
      final newStats = await LocalStorageService.loadStats(selected.id);
      final newBlockedApps =
          await LocalStorageService.loadBlockedApps(selected.id);
      final newAndroidConfig =
          await LocalStorageService.loadAndroidConfig(selected.id);
      final newUnlocks =
          await LocalStorageService.loadUnlockSessions(selected.id);

      if (!mounted) return;

      setState(() {
        activeChild = selected;
        stats = newStats;
        blockedApps = newBlockedApps;
        androidConfig = newAndroidConfig;
        unlockSessions = newUnlocks.where((e) => e.isActive).toList();
      });

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
        unlockSessions =
            result.unlockSessions.where((e) => e.isActive).toList();
      });
      await LocalStorageService.saveAndroidConfig(activeChild.id, androidConfig);
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

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        title: tr(widget.language, 'hits'),
        value: '${stats.successRate.toStringAsFixed(0)}%',
      ),
      _StatCard(
        title: tr(widget.language, 'attempts'),
        value: '${stats.totalAttempts}',
      ),
      _StatCard(
        title: tr(widget.language, 'fails'),
        value: '${stats.wrongAnswers}',
      ),
      _StatCard(
        title: tr(widget.language, 'mostFails'),
        value: stats.mostFailedOperation(widget.language),
      ),
      _StatCard(
        title: tr(widget.language, 'stars'),
        value: '⭐ ${stats.stars}',
      ),
      _StatCard(
        title: tr(widget.language, 'bestStreak'),
        value: '🔥 ${stats.bestStreak}',
      ),
      _StatCard(
        title: tr(widget.language, 'difficulty'),
        value: '${stats.difficultyLevel}/5',
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(widget.language, 'activeChild')),
                  const SizedBox(height: 6),
                  Text(
                    '${activeChild.name} · ${activeChild.age} ${tr(widget.language, 'years')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(tr(widget.language, 'automaticLevel')),
                  const SizedBox(height: 8),
                  Text(
                    '${tr(widget.language, 'selectedApps')}: ${blockedApps.isEmpty ? tr(widget.language, 'noBlockedApps') : blockedApps.join(', ')}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tr(widget.language, 'androidReadiness')}: ${androidConfig.isReady ? tr(widget.language, 'ready') : tr(widget.language, 'notReady')}',
                  ),
                  const SizedBox(height: 12),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'summary'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                childAspectRatio: 1.35,
              ),
              itemBuilder: (_, index) => cards[index],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _openMathChallenge,
                icon: const Icon(Icons.play_arrow),
                label: Text(tr(widget.language, 'testMathChallenge')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _openBlockedApps,
                icon: const Icon(Icons.apps),
                label: Text(tr(widget.language, 'blockedApps')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _openAndroidSetup,
                icon: const Icon(Icons.android),
                label: Text(tr(widget.language, 'configureAndroid')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _openProtectedAppsTester,
                icon: const Icon(Icons.lock_open),
                label: Text(tr(widget.language, 'testProtectedApps')),
              ),
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

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate, size: 72),
                  const SizedBox(height: 22),
                  Text(
                    '${tr(widget.language, 'age')}: ${widget.profile.age} ${tr(widget.language, 'years')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tr(widget.language, 'difficulty')}: ${widget.stats.difficultyLevel}/5',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(widget.language, 'solveToUnlock'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '⭐ ${widget.stats.stars}   🔥 ${widget.stats.streak}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '$a $operatorSymbol $b = ?',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    decoration: InputDecoration(
                      hintText: tr(widget.language, 'answer'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onSubmitted: (_) => answered ? null : checkAnswer(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: answered ? null : checkAnswer,
                      child: Text(tr(widget.language, 'check')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 18),
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
          ),
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

    const appNames = [
      'YouTube',
      'TikTok',
      'Roblox',
      'WhatsApp',
      'Chrome',
      'Juegos',
    ];

    apps = {
      for (final app in appNames) app: widget.selectedApps.contains(app),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.language, 'blockedApps')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(widget.language, 'blockedAppsSubtitle'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(tr(widget.language, 'simulatedFeature')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...apps.entries.map(
              (entry) => SwitchListTile(
                value: entry.value,
                title: Text(entry.key),
                onChanged: (value) {
                  setState(() {
                    apps[entry.key] = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final selected = apps.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();
                  Navigator.pop(context, selected);
                },
                child: Text(tr(widget.language, 'save')),
              ),
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
      appBar: AppBar(
        title: Text(tr(widget.language, 'childManager')),
      ),
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

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(child.name.isNotEmpty ? child.name[0] : '?'),
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

  AndroidSetupResult({
    required this.config,
    required this.unlockSessions,
  });
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

class _AndroidSetupScreenState extends State<AndroidSetupScreen> {
  late AndroidConfig config;
  late List<UnlockSession> unlockSessions;

  @override
  void initState() {
    super.initState();
    config = AndroidConfig(
      usageAccessGranted: widget.config.usageAccessGranted,
      overlayGranted: widget.config.overlayGranted,
      foregroundServiceGranted: widget.config.foregroundServiceGranted,
      unlockMinutes: widget.config.unlockMinutes,
    );
    unlockSessions = widget.unlockSessions.where((e) => e.isActive).toList();
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final activeSessions = unlockSessions.where((e) => e.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.language, 'androidSetup')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: config.usageAccessGranted,
              title: Text(tr(widget.language, 'usageAccess')),
              subtitle: Text(config.usageAccessGranted
                  ? tr(widget.language, 'permissionGranted')
                  : tr(widget.language, 'permissionMissing')),
              onChanged: (value) {
                setState(() {
                  config.usageAccessGranted = value;
                });
              },
            ),
            SwitchListTile(
              value: config.overlayGranted,
              title: Text(tr(widget.language, 'overlayPermission')),
              subtitle: Text(config.overlayGranted
                  ? tr(widget.language, 'permissionGranted')
                  : tr(widget.language, 'permissionMissing')),
              onChanged: (value) {
                setState(() {
                  config.overlayGranted = value;
                });
              },
            ),
            SwitchListTile(
              value: config.foregroundServiceGranted,
              title: Text(tr(widget.language, 'foregroundService')),
              subtitle: Text(config.foregroundServiceGranted
                  ? tr(widget.language, 'permissionGranted')
                  : tr(widget.language, 'permissionMissing')),
              onChanged: (value) {
                setState(() {
                  config.foregroundServiceGranted = value;
                });
              },
            ),
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'unlockMinutes'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
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
            const SizedBox(height: 18),
            Text(
              tr(widget.language, 'unlockStatus'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (activeSessions.isEmpty)
              Text(tr(widget.language, 'noBlockedApps'))
            else
              ...activeSessions.map(
                (session) => ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: Text(session.appName),
                  subtitle: Text(
                    '${tr(widget.language, 'unlockedUntil')} ${_formatDate(session.expiresAt)}',
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
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
          content: Text('$appName ${tr(widget.language, 'accessAllowed')}'),
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
      final expiresAt =
          DateTime.now().add(Duration(minutes: widget.config.unlockMinutes));
      unlockSessions.removeWhere((e) => e.appName == appName);
      unlockSessions.add(UnlockSession(appName: appName, expiresAt: expiresAt));
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanedSessions = unlockSessions.where((e) => e.isActive).toList();

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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!widget.config.isReady)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${tr(widget.language, 'androidReadiness')}: ${tr(widget.language, 'notReady')}',
                ),
              ),
            if (!widget.config.isReady) const SizedBox(height: 16),
            ...widget.blockedApps.map(
              (app) {
                final unlocked = _isUnlocked(app);
                final expiry = _getExpiry(app);

                return Card(
                  child: ListTile(
                    leading: Icon(unlocked ? Icons.lock_open : Icons.lock),
                    title: Text(app),
                    subtitle: Text(
                      unlocked && expiry != null
                          ? '${tr(widget.language, 'unlockedUntil')} ${_formatDate(expiry)}'
                          : tr(widget.language, 'locked'),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _openApp(app),
                      child: Text(tr(widget.language, 'openProtectedApp')),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            if (cleanedSessions.isNotEmpty)
              Text(
                tr(widget.language, 'unlockStatus'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ...cleanedSessions.map(
              (session) => ListTile(
                leading: const Icon(Icons.timer),
                title: Text(session.appName),
                subtitle: Text(
                  '${tr(widget.language, 'unlockedUntil')} ${_formatDate(session.expiresAt)}',
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, cleanedSessions),
              child: Text(tr(widget.language, 'backToPanel')),
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
        title:
            Text('${tr(widget.language, 'protectedArea')} · ${widget.appName}'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, size: 72),
                  const SizedBox(height: 18),
                  Text(
                    tr(widget.language, 'thisAppWouldBeBlocked'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(widget.language, 'requireMathBeforeOpen'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$a $operatorSymbol $b = ?',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    decoration: InputDecoration(
                      hintText: tr(widget.language, 'answer'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onSubmitted: (_) => answered ? null : _checkAnswer(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
          ),
        ),
      ),
    );
  }
}