import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final String knownParentPin;

  const ForgotPasswordScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.knownParentPin,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _saving = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Introduce un email válido'
            : 'Enter a valid email';
      });
      return;
    }

    if (pin.length != 4) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Introduce tu PIN parental de 4 números'
            : 'Enter your 4-digit parent PIN';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'La nueva contraseña debe tener al menos 6 caracteres'
            : 'New password must be at least 6 characters';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Las contraseñas no coinciden'
            : 'Passwords do not match';
      });
      return;
    }

    final savedEmailRaw = await LocalStorageService.loadParentEmail();

    final savedEmail = (savedEmailRaw ?? '').trim().toLowerCase();
    final savedPin = widget.knownParentPin.trim();

    if (!mounted) return;

    if (savedEmail.isEmpty) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'No hay una cuenta parental guardada todavía'
            : 'There is no saved parent account yet';
      });
      return;
    }

    if (savedPin.isEmpty) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'No hay un PIN parental disponible'
            : 'There is no parent PIN available';
      });
      return;
    }

    if (email != savedEmail) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'El correo no coincide con la cuenta parental guardada'
            : 'The email does not match the saved parent account';
      });
      return;
    }

    if (pin != savedPin) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'El PIN parental no es correcto'
            : 'The parent PIN is incorrect';
      });
      _pinController.clear();
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    await LocalStorageService.saveParentPassword(newPassword);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.language == AppLanguage.spanish;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Recuperar contraseña' : 'Recover password'),
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
                      isSpanish
                          ? 'Recupera tu contraseña con tu email y tu PIN parental'
                          : 'Recover your password with your email and parent PIN',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: isSpanish ? 'PIN parental' : 'Parent PIN',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isSpanish
                            ? 'Nueva contraseña'
                            : 'New password',
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                          icon: Icon(
                            _showNewPassword
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
                            ? 'Confirmar nueva contraseña'
                            : 'Confirm new password',
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
                        onPressed: _saving ? null : _resetPassword,
                        child: Text(
                          _saving
                              ? tr(widget.language, 'saving')
                              : (isSpanish
                                    ? 'Guardar nueva contraseña'
                                    : 'Save new password'),
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
