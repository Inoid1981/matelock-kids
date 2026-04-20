import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class ChangeParentPinScreen extends StatefulWidget {
  final String currentPin;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ChangeParentPinScreen({
    super.key,
    required this.currentPin,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<ChangeParentPinScreen> createState() => _ChangeParentPinScreenState();
}

class _ChangeParentPinScreenState extends State<ChangeParentPinScreen> {
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  String? _errorText;
  bool _saving = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _saveNewPin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin != widget.currentPin) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'El PIN actual no es correcto'
            : 'Current PIN is incorrect';
      });
      return;
    }

    if (newPin.length != 4) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'El nuevo PIN debe tener 4 números'
            : 'New PIN must have 4 digits';
      });
      return;
    }

    if (newPin != confirmPin) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'Los PIN no coinciden'
            : 'PINs do not match';
      });
      return;
    }

    if (newPin == widget.currentPin) {
      setState(() {
        _errorText = widget.language == AppLanguage.spanish
            ? 'El nuevo PIN no puede ser igual al anterior'
            : 'New PIN cannot be the same as the previous one';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    await LocalStorageService.saveParentPin(newPin);

    if (!mounted) return;

    Navigator.pop(context, newPin);
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.language == AppLanguage.spanish;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Cambiar PIN parental' : 'Change parent PIN'),
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
                          ? 'Actualiza tu PIN parental'
                          : 'Update your parent PIN',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSpanish
                          ? 'Introduce el PIN actual y después el nuevo PIN'
                          : 'Enter your current PIN and then the new PIN',
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: isSpanish ? 'PIN actual' : 'Current PIN',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _newPinController,
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
                        labelText: isSpanish
                            ? 'Confirmar nuevo PIN'
                            : 'Confirm new PIN',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
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
                        onPressed: _saving ? null : _saveNewPin,
                        child: Text(
                          _saving
                              ? tr(widget.language, 'saving')
                              : (isSpanish
                                    ? 'Guardar nuevo PIN'
                                    : 'Save new PIN'),
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
