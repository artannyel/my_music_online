import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_online/src/core/router/route_names.dart';
import 'package:my_music_online/src/core/router/scaffold_with_bottom_nav.dart';
import 'package:my_music_online/src/features/home/presentation/views/home_screen.dart';
import 'package:my_music_online/src/features/search/presentation/views/search_screen.dart';
import 'package:my_music_online/src/features/playlist/presentation/views/playlists_screen.dart';
import 'package:my_music_online/src/features/playlist/presentation/views/playlist_detail_screen.dart';
import 'package:my_music_online/src/features/settings/presentation/views/cookies_settings_screen.dart';
import 'package:my_music_online/src/features/auth/presentation/views/login_screen.dart';
import 'package:my_music_online/src/features/auth/presentation/views/register_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// AppRouter centraliza a configuração do GoRouter do aplicativo.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.home,
    routes: <RouteBase>[
      // Rota de Login (Sem BottomNav / ShellRoute)
      GoRoute(
        path: RouteNames.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      // Rota de Cadastro
      GoRoute(
        path: RouteNames.register,
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      // Rota de Detalhes da Playlist
      GoRoute(
        path: RouteNames.playlistDetail,
        builder: (BuildContext context, GoRouterState state) {
          final playlistId = state.pathParameters['id'] ?? '';
          return PlaylistDetailScreen(playlistId: playlistId);
        },
      ),

      // ShellRoute para páginas principais com BottomNav & MiniPlayer persistente
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: RouteNames.home,
            builder: (BuildContext context, GoRouterState state) {
              return const HomeScreen();
            },
          ),
          GoRoute(
            path: RouteNames.search,
            builder: (BuildContext context, GoRouterState state) {
              return const SearchScreen();
            },
          ),
          GoRoute(
            path: RouteNames.playlists,
            builder: (BuildContext context, GoRouterState state) {
              return const PlaylistsScreen();
            },
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (BuildContext context, GoRouterState state) {
              return const CookiesSettingsScreen();
            },
          ),
        ],
      ),
    ],
  );
}
