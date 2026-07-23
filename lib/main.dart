import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:my_music_online/src/app.dart';
import 'package:my_music_online/src/core/services/firebase_service.dart';
import 'package:my_music_online/src/features/player/data/services/audio_player_service.dart';
import 'package:my_music_online/src/features/player/data/services/app_audio_handler.dart';
import 'package:my_music_online/src/features/player/data/services/audio_handler_provider.dart';
import 'package:my_music_online/src/features/player/presentation/controllers/player_controller.dart';
import 'package:my_music_online/src/features/settings/data/services/yt_cookies_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização assíncrona do Firebase
  await FirebaseService.initialize();

  // Carrega cookies do Firestore e inicializa YTMusic + CookieExtractor
  await initializeLibrariesWithCookies();

  final audioService = AudioPlayerService();

  // Inicializa o AudioService nativo (Background e Lockscreen)
  final audioHandler = await AudioService.init<AppAudioHandler>(
    builder: () => AppAudioHandler(audioService),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mymusiconline.channel.audio',
      androidNotificationChannelName: 'Música',
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audioService),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyMusicApp(),
    ),
  );
}
