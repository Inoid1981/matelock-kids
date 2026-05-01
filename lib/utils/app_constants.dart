import 'package:flutter/material.dart';
import 'translations.dart';

const List<String> kAppIds = [
  'calculator',
  'youtube',
  'tiktok',
  'roblox',
  'whatsapp',
  'chrome',
  'games',
];

String appLabel(AppLanguage lang, String appId) {
  switch (appId) {
    case 'calculator':
      return tr(lang, 'calculatorApp');
    case 'youtube':
      return 'YouTube';
    case 'tiktok':
      return 'TikTok';
    case 'roblox':
      return 'Roblox';
    case 'whatsapp':
      return 'WhatsApp';
    case 'chrome':
      return 'Chrome';
    case 'games':
      return tr(lang, 'gamesApp');
    default:
      return appId;
  }
}

IconData appIcon(String appId) {
  switch (appId) {
    case 'calculator':
      return Icons.calculate_outlined;
    case 'youtube':
      return Icons.play_circle_outline;
    case 'tiktok':
      return Icons.music_note_outlined;
    case 'roblox':
      return Icons.videogame_asset_outlined;
    case 'whatsapp':
      return Icons.chat_bubble_outline;
    case 'chrome':
      return Icons.public;
    case 'games':
      return Icons.sports_esports_outlined;
    default:
      return Icons.apps_outlined;
  }
}

// ✅ NUEVA FUNCIÓN QUE USA LOS ICONOS REALES
Widget appIconWidget(String appId, {double size = 42}) {
  const iconPaths = <String, String>{
    'calculator': 'assets/app_icons/calculator.png',
    'youtube': 'assets/app_icons/youtube.png',
    'tiktok': 'assets/app_icons/tiktok.png',
    'roblox': 'assets/app_icons/roblox.png',
    'whatsapp': 'assets/app_icons/whatsapp.png',
    'chrome': 'assets/app_icons/chrome.png',
    'games': 'assets/app_icons/games.png',
    'settings': 'assets/app_icons/settings.png',
    'play_store': 'assets/app_icons/play_store.png',
  };

  final path = iconPaths[appId];
  if (path != null) {
    return Image.asset(path, width: size, height: size);
  }
  // Si no hay imagen, usamos el icono de Material por defecto
  return Icon(appIcon(appId), size: size);
}

String avatarEmoji(String avatarId) {
  switch (avatarId) {
    case 'robot':
      return String.fromCharCode(0x1F916); // ??
    case 'ninja':
      return String.fromCharCodes([0x1F977]); // ??
    case 'astronaut':
      return String.fromCharCodes([0x1F468, 0x200D, 0x1F680]); // ?????
    case 'fox':
      return String.fromCharCode(0x1F98A); // ??
    case 'cat':
      return String.fromCharCode(0x1F431); // ??
    case 'bear':
    default:
      return String.fromCharCode(0x1F9F8); // ??
  }
}

String avatarLabel(AppLanguage lang, String avatarId) {
  switch (avatarId) {
    case 'robot':
      return tr(lang, 'robotAvatar');
    case 'ninja':
      return tr(lang, 'ninjaAvatar');
    case 'astronaut':
      return tr(lang, 'astronautAvatar');
    case 'fox':
      return tr(lang, 'foxAvatar');
    case 'cat':
      return tr(lang, 'catAvatar');
    case 'bear':
    default:
      return tr(lang, 'bearAvatar');
  }
}

String achievementLabel(AppLanguage lang, String achievementId) {
  switch (achievementId) {
    case 'streak_5':
      return tr(lang, 'achievement_streak_5');
    case 'streak_10':
      return tr(lang, 'achievement_streak_10');
    case 'stars_10':
      return tr(lang, 'achievement_10_stars');
    case 'stars_25':
      return tr(lang, 'achievement_25_stars');
    case 'correct_50':
      return tr(lang, 'achievement_50_correct');
    case 'level_3':
      return tr(lang, 'achievement_level_3');
    case 'level_5':
      return tr(lang, 'achievement_level_5');
    case 'apps_3':
      return tr(lang, 'achievement_apps_3');
    default:
      return achievementId;
  }
}
