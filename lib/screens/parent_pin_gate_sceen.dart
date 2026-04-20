import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class ParentPinGateScreen extends StatefulWidget {
  final String parentPin;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final WidgetBuilder dashboardBuilder;

  const ParentPinGateScreen({
    super.key,
    required this.parentPin,
    required this.language,
    required this.onLanguageChanged,
    required this.dashboardBuilder,
  });

  @override
  State<ParentPinGateScreen> createState() => _ParentPinGateScreenState();
}

class _ParentPinGateScreenState extends State<ParentPinGateScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? _errorText;
  bool _unlocked = false;
  bool _loading = true;
  bool _hasParentAccount = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadParentAccountStatus();
  }

  Future<void> _loadParentAccountStatus() async {
    final hasAccount = await LocalStorageService.hasParentAccount();

    if (!mounted) return;

    setState(() {
      _hasParentAccount = hasAccount;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _continue() async {
    final pin = _pinController.text.trim();

    if (_hasParentAccount) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorText = widget.language == AppLanguage.spanish
              ? 'Introduce el email y la contraseña'
              : 'Enter email and password';
        });
        return;
      }

      final savedEmail = await LocalStorageService.loadParentEmail();
      final savedPassword = await LocalStorageService.loadParentPassword();

      if (!mounted) return;

      if (email != savedEmail || password != savedPassword) {
        setState(() {
          _errorText = widget.language == AppLanguage.spanish
              ? 'Email o contraseña incorrectos'
              : 'Incorrect email or password';
        });
        _passwordController.clear();
        return;
      }
    }

    if (pin == widget.parentPin) {
      setState(() {
        _unlocked = true;
        _errorText = null;
      });
      return;
    }

    setState(() {
      _errorText = widget.language == AppLanguage.spanish
          ? 'PIN incorrecto. Inténtalo de nuevo.'
          : 'Incorrect PIN. Please try again.';
    });

    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.language == AppLanguage.spanish;

    if (_unlocked) {
      return widget.dashboardBuilder(context);
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isSpanish ? 'Acceso parental' : 'Parent access'),
          actions: [
            LanguageSwitcher(
              language: widget.language,
              onChanged: widget.onLanguageChanged,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Acceso parental' : 'Parent access'),
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
                      _hasParentAccount
                          ? (isSpanish
                                ? 'Introduce tu email, tu contraseña y tu PIN para entrar al panel de padres'
                                : 'Enter your email, password and PIN to access the parents panel')
                          : (isSpanish
                                ? 'Introduce tu PIN para entrar al panel de padres'
                                : 'Enter your PIN to access the parents panel'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_hasParentAccount) ...[
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() {
                              _errorText = null;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() {
                              _errorText = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: isSpanish ? 'Contraseña' : 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                      onSubmitted: (_) => _continue(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: isSpanish ? 'PIN parental' : 'Parent PIN',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE57373)),
                        ),
                        child: Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB71C1C),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continue,
                        child: Text(isSpanish ? 'Entrar' : 'Enter'),
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
