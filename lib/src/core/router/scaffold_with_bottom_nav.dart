import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_online/src/core/theme/app_colors.dart';
import 'route_names.dart';

/// ScaffoldWithBottomNav envolve o conteúdo principal das páginas (Home, Search, Playlists, Settings)
/// mantendo a barra de navegação inferior e o MiniPlayer fixos.
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RouteNames.search)) return 1;
    if (location.startsWith(RouteNames.playlists)) return 2;
    if (location.startsWith(RouteNames.settings)) return 3;
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.search);
        break;
      case 2:
        context.go(RouteNames.playlists);
        break;
      case 3:
        context.go(RouteNames.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          // TODO: O MiniPlayerWidget será renderizado aqui acima da BottomNavigationBar
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music_outlined),
            activeIcon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
