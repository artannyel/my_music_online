import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_music_online/src/app.dart';
import 'package:my_music_online/src/core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização assíncrona do Firebase
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: MyMusicApp(),
    ),
  );
}
