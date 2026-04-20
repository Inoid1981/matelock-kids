import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class CreateParentPinScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final WidgetBuilder nextScreenBuilder;

  const CreateParentPinScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.nextScreenBuilder,
  });

  @override
  State<CreateParentPinScreen> createState() => _CreateParentPinScreenState();
}

class _CreateParentPinScreenState extends State<CreateParentPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  String? _errorText;
  bool _saving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'El PIN debe tener 4 números'
            : 'PIN must have 4 digits';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Los PIN no coinciden'
            : 'PINs do not match';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    await LocalStorageService.saveParentPin(pin);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: widget.nextScreenBuilder),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.language == AppLanguage.spanish;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Crear PIN parental' : 'Create parent PIN'),
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
                          ? 'Crea un PIN de 4 números para entrar al panel de padres'
                          : 'Create a 4-digit PIN to enter the parents panel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: isSpanish ? 'Nuevo PIN' : 'New PIN',
                        prefixIcon: const Icon(Icons.pin_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: isSpanish ? 'Confirmar PIN' : 'Confirm PIN',
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
                        onPressed: _saving ? null : _savePin,
                        child: Text(
                          _saving
                              ? tr(widget.language, 'saving')
                              : tr(widget.language, 'save'),
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
