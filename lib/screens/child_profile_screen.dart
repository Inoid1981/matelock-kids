import 'package:flutter/material.dart';

import '../models/android_config.dart';
import '../models/app_stats.dart';
import '../models/child_profile.dart';
import '../services/local_storage_service.dart';
import '../utils/translations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/pretty_card.dart';

class ChildProfileScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ChildProfile? existingProfile;
  final WidgetBuilder? afterCreateBuilder;

  const ChildProfileScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    this.existingProfile,
    this.afterCreateBuilder,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedAge = 9;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _nameController.text = widget.existingProfile!.name;
      _selectedAge = widget.existingProfile!.age;
    }
  }

  Future<void> _continue() async {
    setState(() => _saving = true);

    final name = _nameController.text.trim().isEmpty
        ? tr(widget.language, 'childDefault')
        : _nameController.text.trim();

    final children = await LocalStorageService.loadChildren();

    ChildProfile profile;
    if (widget.existingProfile != null) {
      profile = widget.existingProfile!.copyWith(name: name, age: _selectedAge);
      final index = children.indexWhere((c) => c.id == profile.id);
      if (index != -1) children[index] = profile;
    } else {
      profile = ChildProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        age: _selectedAge,
        avatarId: 'bear',
      );
      children.add(profile);
      await LocalStorageService.saveStats(profile.id, AppStats());
      await LocalStorageService.saveBlockedApps(profile.id, []);
      await LocalStorageService.saveAndroidConfig(profile.id, AndroidConfig());
      await LocalStorageService.saveUnlockSessions(profile.id, []);
      await LocalStorageService.saveSetupDone(profile.id, false);
    }

    await LocalStorageService.saveChildren(children);
    await LocalStorageService.saveActiveChildId(profile.id);

    if (!mounted) return;

    if (widget.existingProfile != null) {
      Navigator.pop(context);
      return;
    }

    if (widget.afterCreateBuilder != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: widget.afterCreateBuilder!),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ages = List.generate(6, (index) => index + 7);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProfile == null
              ? tr(widget.language, 'createProfile')
              : tr(widget.language, 'editProfile'),
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
                      widget.existingProfile == null
                          ? tr(widget.language, 'createProfile')
                          : tr(widget.language, 'editProfile'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(tr(widget.language, 'enterNameAge')),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr(widget.language, 'name'),
                        prefixIcon: const Icon(Icons.child_care),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr(widget.language, 'age'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ages.map((age) {
                        return ChoiceChip(
                          label: Text('$age ${tr(widget.language, 'years')}'),
                          selected: age == _selectedAge,
                          onSelected: (_) {
                            setState(() => _selectedAge = age);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _continue,
                        child: Text(
                          _saving
                              ? tr(widget.language, 'saving')
                              : tr(widget.language, 'saveContinue'),
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
