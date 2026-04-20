import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';
import 'forgot_password_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final String parentPin;
  final WidgetBuilder createFirstProfileBuilder;

  const ParentLoginScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.parentPin,
    required this.createFirstProfileBuilder,
  });

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  bool _hasParentAccount = false;
  bool _showPassword = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadAccountStatus();
  }

  Future<void> _loadAccountStatus() async {
    final hasAccount = await LocalStorageService.hasParentAccount();

    if (!mounted) return;

    setState(() {
      _hasParentAccount = hasAccount;
      _loading = false;
    });
  }

  Future<void> _continue() async {
    if (!_hasParentAccount) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: widget.createFirstProfileBuilder),
      );
      return;
    }

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
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: widget.createFirstProfileBuilder),
    );
  }

  Future<void> _openForgotPasswordScreen() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          language: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
          knownParentPin: widget.parentPin,
        ),
      ),
    );

    if (updated == true && mounted) {
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == AppLanguage.spanish
                ? 'Contraseña actualizada correctamente'
                : 'Password updated successfully',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.language == AppLanguage.spanish;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(widget.language, 'appTitle')),
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
        title: Text(tr(widget.language, 'appTitle')),
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
                          tr(widget.language, 'appTitle'),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(widget.language, 'tagline'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrettyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasParentAccount
                              ? (isSpanish
                                    ? 'Inicia sesión con tu cuenta parental'
                                    : 'Sign in with your parent account')
                              : (isSpanish
                                    ? 'Primero crea el perfil infantil. Después podrás configurar la cuenta parental desde el panel.'
                                    : 'First create the child profile. Then you can configure the parent account from the dashboard.'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_hasParentAccount) ...[
                          const SizedBox(height: 18),
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
                            decoration: InputDecoration(
                              labelText: tr(widget.language, 'email'),
                              prefixIcon: const Icon(Icons.email_outlined),
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
                              labelText: tr(widget.language, 'password'),
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _openForgotPasswordScreen,
                              child: Text(
                                isSpanish
                                    ? 'He olvidado mi contraseña'
                                    : 'I forgot my password',
                              ),
                            ),
                          ),
                        ],
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
                              border: Border.all(
                                color: const Color(0xFFE57373),
                              ),
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
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _continue,
                            child: Text(
                              _hasParentAccount
                                  ? (isSpanish ? 'Entrar' : 'Sign in')
                                  : tr(widget.language, 'createFirstChild'),
                            ),
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
