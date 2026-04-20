import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class InternalPinCheckScreen extends StatefulWidget {
  final String parentPin;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const InternalPinCheckScreen({
    super.key,
    required this.parentPin,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<InternalPinCheckScreen> createState() => _InternalPinCheckScreenState();
}

class _InternalPinCheckScreenState extends State<InternalPinCheckScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _confirm() {
    final pin = _pinController.text.trim();

    if (pin == widget.parentPin) {
      Navigator.pop(context, true);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSpanish ? 'Verificación parental' : 'Parent verification',
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
                      isSpanish
                          ? 'Introduce tu PIN para continuar'
                          : 'Enter your PIN to continue',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                      onSubmitted: (_) => _confirm(),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirm,
                            child: Text(isSpanish ? 'Confirmar' : 'Confirm'),
                          ),
                        ),
                      ],
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
