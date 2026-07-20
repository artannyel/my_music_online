import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_music_online/src/core/router/app_router.dart';
import 'package:my_music_online/src/core/theme/app_theme.dart';

/// MyMusicApp é o widget raiz da aplicação configurado com MaterialApp.router.
class MyMusicApp extends ConsumerWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'My Music Online',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return child!;
      },
    );
  }
}
