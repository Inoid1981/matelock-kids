import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import '../utils/translations.dart';
import '../widgets/pretty_card.dart';

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
    apps = {
      for (final appId in kAppIds) appId: widget.selectedApps.contains(appId),
    };
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
            ...apps.entries.map(
              (entry) => PrettyCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SwitchListTile(
                  secondary: Icon(appIcon(entry.key)),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final selected = apps.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                Navigator.pop(context, selected);
              },
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
