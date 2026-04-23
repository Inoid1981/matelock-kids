import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import '../utils/translations.dart';
import '../widgets/pretty_card.dart';

class AvatarSelectorScreen extends StatelessWidget {
  final String selectedAvatar;
  final List<String> unlockedAvatars;
  final AppLanguage language;

  const AvatarSelectorScreen({
    super.key,
    required this.selectedAvatar,
    required this.unlockedAvatars,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    const allAvatars = ['bear', 'robot', 'ninja', 'astronaut', 'fox', 'cat'];

    return Scaffold(
      appBar: AppBar(title: Text(tr(language, 'chooseAvatar'))),
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
                    tr(language, 'avatars'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(tr(language, 'selectedAvatar')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: allAvatars.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, index) {
                final avatarId = allAvatars[index];
                final unlocked = unlockedAvatars.contains(avatarId);
                final selected = selectedAvatar == avatarId;

                return GestureDetector(
                  onTap: unlocked
                      ? () => Navigator.pop(context, avatarId)
                      : null,
                  child: PrettyCard(
                    color: selected
                        ? Colors.indigo.withOpacity(0.12)
                        : Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          avatarEmoji(avatarId),
                          style: const TextStyle(fontSize: 42),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          avatarLabel(language, avatarId),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          unlocked
                              ? (selected ? tr(language, 'selectedAvatar') : '')
                              : tr(language, 'lockedAvatar'),
                          style: TextStyle(
                            color: unlocked ? Colors.indigo : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
