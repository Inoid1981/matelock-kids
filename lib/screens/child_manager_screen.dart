import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/local_storage_service.dart';
import '../utils/app_constants.dart';
import '../utils/translations.dart';
import '../widgets/pretty_card.dart';

class ChildManagerScreen extends StatefulWidget {
  final List<ChildProfile> children;
  final String activeChildId;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final WidgetBuilder loginBuilder;
  final WidgetBuilder addChildBuilder;

  const ChildManagerScreen({
    super.key,
    required this.children,
    required this.activeChildId,
    required this.language,
    required this.onLanguageChanged,
    required this.loginBuilder,
    required this.addChildBuilder,
  });

  @override
  State<ChildManagerScreen> createState() => _ChildManagerScreenState();
}

class _ChildManagerScreenState extends State<ChildManagerScreen> {
  late List<ChildProfile> children;

  @override
  void initState() {
    super.initState();
    children = List<ChildProfile>.from(widget.children);
  }

  Future<void> _deleteChild(ChildProfile child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(widget.language, 'deleteChild')),
        content: Text(tr(widget.language, 'deleteChildConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(widget.language, 'no')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(widget.language, 'yes')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    children.removeWhere((c) => c.id == child.id);
    await LocalStorageService.saveChildren(children);
    await LocalStorageService.deleteStats(child.id);
    await LocalStorageService.deleteBlockedApps(child.id);
    await LocalStorageService.deleteAndroidConfig(child.id);
    await LocalStorageService.deleteUnlockSessions(child.id);
    await LocalStorageService.deleteSetupDone(child.id);

    if (children.isEmpty) {
      await LocalStorageService.clearAll();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: widget.loginBuilder),
        (route) => false,
      );
      return;
    }

    if (child.id == widget.activeChildId) {
      await LocalStorageService.saveActiveChildId(children.first.id);
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(widget.language, 'childManager'))),
      body: SafeArea(
        child: children.isEmpty
            ? Center(child: Text(tr(widget.language, 'noChildren')))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final child = children[index];
                  final isActive = child.id == widget.activeChildId;

                  return PrettyCard(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(avatarEmoji(child.avatarId)),
                      ),
                      title: Text(child.name),
                      subtitle: Text(
                        '${child.age} ${tr(widget.language, 'years')}${isActive ? ' · ${tr(widget.language, 'activeChild')}' : ''}',
                      ),
                      onTap: () => Navigator.pop(context, child),
                      trailing: IconButton(
                        onPressed: () => _deleteChild(child),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: widget.addChildBuilder),
          );
          final refreshed = await LocalStorageService.loadChildren();
          if (!mounted) return;
          setState(() {
            children = refreshed;
          });
        },
        icon: const Icon(Icons.person_add),
        label: Text(tr(widget.language, 'addChild')),
      ),
    );
  }
}
