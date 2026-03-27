import 'package:flutter/material.dart';
import '../utils/translations.dart';

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
      borderRadius: BorderRadius.circular(16),
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