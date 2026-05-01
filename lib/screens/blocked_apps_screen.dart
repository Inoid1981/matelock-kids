import 'package:flutter/material.dart';

import '../models/android_config.dart';
import '../services/local_storage_service.dart';
import '../utils/app_constants.dart';
import '../utils/translations.dart';
import '../widgets/pretty_card.dart';

class BlockedAppsScreen extends StatefulWidget {
  final List<String> selectedApps;
  final AppLanguage language;
  final String childId;
  final int currentUnlockMinutes;

  const BlockedAppsScreen({
    super.key,
    required this.selectedApps,
    required this.language,
    required this.childId,
    required this.currentUnlockMinutes,
  });

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  late Map<String, bool> apps;
  int? selectedUnlockMinutes;
  final TextEditingController _customMinutesController =
      TextEditingController();
  bool _useCustomMinutes = false;

  @override
  void initState() {
    super.initState();
    apps = {
      for (final appId in kAppIds) appId: widget.selectedApps.contains(appId),
    };
    selectedUnlockMinutes = widget.currentUnlockMinutes;
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selected = apps.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // Guardar el tiempo de desbloqueo elegido
    int unlockMinutes = widget.currentUnlockMinutes;
    if (_useCustomMinutes) {
      final custom = int.tryParse(_customMinutesController.text.trim());
      if (custom != null && custom > 0) {
        unlockMinutes = custom;
      }
    } else if (selectedUnlockMinutes != null) {
      unlockMinutes = selectedUnlockMinutes!;
    }

    // Actualizar la configuración de Android
    final currentConfig = await LocalStorageService.loadAndroidConfig(
      widget.childId,
    );
    if (currentConfig != null) {
      currentConfig.unlockMinutes = unlockMinutes;
      await LocalStorageService.saveAndroidConfig(
        widget.childId,
        currentConfig,
      );
    }

    if (!mounted) return;
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(widget.language, 'blockedApps'))),
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
                    tr(widget.language, 'blockedAppsSubtitle'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(tr(widget.language, 'simulatedFeature')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de apps
            ...apps.entries.map(
              (entry) => PrettyCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SwitchListTile(
                  secondary: appIconWidget(entry.key, size: 32),
                  value: entry.value,
                  title: Text(appLabel(widget.language, entry.key)),
                  onChanged: (value) {
                    setState(() {
                      apps[entry.key] = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sección de tiempo de desbloqueo
            PrettyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.language == AppLanguage.spanish
                        ? 'Tiempo de desbloqueo'
                        : 'Unlock time',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Minutos predeterminados:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [1, 5, 10, 30].map((minutes) {
                      final selected =
                          selectedUnlockMinutes == minutes &&
                          !_useCustomMinutes;
                      return ChoiceChip(
                        label: Text('$minutes'),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            selectedUnlockMinutes = minutes;
                            _useCustomMinutes = false;
                            _customMinutesController.clear();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customMinutesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: widget.language == AppLanguage.spanish
                                ? 'Minutos personalizados'
                                : 'Custom minutes',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _useCustomMinutes = value.isNotEmpty;
                              if (_useCustomMinutes) {
                                selectedUnlockMinutes = null;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botones de guardar / cancelar
            ElevatedButton(
              onPressed: _save,
              child: Text(tr(widget.language, 'save')),
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
