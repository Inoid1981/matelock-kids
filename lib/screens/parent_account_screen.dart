import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class ParentAccountScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ParentAccountScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<ParentAccountScreen> createState() => _ParentAccountScreenState();
}

class _ParentAccountScreenState extends State<ParentAccountScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _hasExistingAccount = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadParentAccount();
  }

  Future<void> _loadParentAccount() async {
    final email = await LocalStorageService.loadParentEmail();
    final password = await LocalStorageService.loadParentPassword();

    if (!mounted) return;

    setState(() {
      _emailController.text = email ?? '';
      _passwordController.text = password ?? '';
      _confirmPasswordController.text = password ?? '';
      _hasExistingAccount =
          email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _saveParentAccount() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Introduce un email válido'
            : 'Enter a valid email';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'La contraseña debe tener al menos 6 caracteres'
            : 'Password must be at least 6 characters';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Las contraseñas no coinciden'
            : 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    await LocalStorageService.saveParentEmail(email);
    await LocalStorageService.saveParentPassword(password);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.language == AppLanguage.spanish;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Cuenta parental' : 'Parent account'),
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
                      _hasExistingAccount
                          ? (isSpanish
                                ? 'Editar cuenta parental'
                                : 'Edit parent account')
                          : (isSpanish
                                ? 'Crear cuenta parental'
                                : 'Create parent account'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSpanish
                          ? 'Guarda aquí el email y la contraseña del padre o la madre'
                          : 'Save here the parent email and password',
                    ),
                    const SizedBox(height: 20),
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
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isSpanish
                            ? 'Confirmar contraseña'
                            : 'Confirm password',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
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
                        onPressed: _saving ? null : _saveParentAccount,
                        child: Text(
                          _saving
                              ? tr(widget.language, 'saving')
                              : (isSpanish
                                    ? 'Guardar cuenta parental'
                                    : 'Save parent account'),
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
