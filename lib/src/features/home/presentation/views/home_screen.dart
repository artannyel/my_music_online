import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_section_model.dart';
import '../controllers/home_controller.dart';

/// HomeScreen exibe as seções reais retornadas do YTMusic (sugestões, playlists, álbuns, artistas)
/// com fallback visual limpo (inicial do título / ícone por tipo) quando não há imagem.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _onItemTap(BuildContext context, HomeItemModel item) {
    switch (item.type) {
      case HomeItemType.playlist:
        final targetId = item.playlistId ?? item.id;
        context.push('/playlist/$targetId');
        break;
      case HomeItemType.album:
        final targetId = item.playlistId ?? item.albumId ?? item.id;
        context.push('/album/$targetId');
        break;
      case HomeItemType.artist:
        final targetId = item.artistId ?? item.id;
        context.push('/artist/$targetId');
        break;
      case HomeItemType.song:
        // TODO: Iniciar reprodução da música no PlayerController
        break;
    }
  }

  Widget _getBadgeIcon(HomeItemType type) {
    switch (type) {
      case HomeItemType.playlist:
        return const Icon(Icons.playlist_play, color: Colors.white, size: 14);
      case HomeItemType.album:
        return const Icon(Icons.album, color: Colors.white, size: 14);
      case HomeItemType.artist:
        return const Icon(Icons.person, color: Colors.white, size: 14);
      case HomeItemType.song:
        return const Icon(Icons.music_note, color: Colors.white, size: 14);
    }
  }

  Color _getBadgeColor(HomeItemType type) {
    switch (type) {
      case HomeItemType.playlist:
        return AppColors.secondary;
      case HomeItemType.album:
        return Colors.amber.shade800;
      case HomeItemType.artist:
        return Colors.teal;
      case HomeItemType.song:
        return AppColors.primary;
    }
  }

  /// Constrói a capa da mídia ou um fallback elegante com a inicial do título e ícone por tipo
  Widget _buildImageOrFallback(HomeItemModel item, {double? width, double? height, bool isCircle = false}) {
    final hasUrl = item.thumbnailUrl != null && item.thumbnailUrl!.trim().isNotEmpty;

    if (hasUrl) {
      return CachedNetworkImage(
        imageUrl: item.thumbnailUrl!,
        fit: BoxFit.cover,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        placeholder: (context, url) => _buildPlaceholderFallback(item, isCircle: isCircle),
        errorWidget: (context, url, error) => _buildFallbackWidget(item, isCircle: isCircle),
      );
    }

    return _buildFallbackWidget(item, isCircle: isCircle);
  }

  Widget _buildPlaceholderFallback(HomeItemModel item, {bool isCircle = false}) {
    return Container(
      color: AppColors.cardBackground,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      ),
    );
  }

  Widget _buildFallbackWidget(HomeItemModel item, {bool isCircle = false}) {
    final initialLetter = item.title.trim().isNotEmpty
        ? item.title.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.surface,
            _getBadgeColor(item.type).withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getBadgeIcon(item.type),
            const SizedBox(height: 4),
            Text(
              initialLetter,
              style: TextStyle(
                fontSize: isCircle ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeSectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(homeSectionsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header da Home
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'My Music',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => context.push(RouteNames.settings),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo Dinâmico
              homeState.when(
                data: (sections) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final section = sections[index];
                        if (index == 0 || section.items.length > 5) {
                          return _buildHorizontalSection(context, section);
                        }
                        return _buildVerticalSection(context, section);
                      },
                      childCount: sections.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (error, stack) => const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Erro ao carregar seções.\nPuxe para atualizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói carrossel horizontal com badges de identificação por tipo
  Widget _buildHorizontalSection(BuildContext context, HomeSectionModel section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 225,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _buildHorizontalCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCard(BuildContext context, HomeItemModel item) {
    final isArtist = item.type == HomeItemType.artist;

    return GestureDetector(
      onTap: () => _onItemTap(context, item),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isArtist ? null : BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.accentGlow,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: isArtist
                        ? BorderRadius.circular(75)
                        : BorderRadius.circular(16),
                    child: _buildImageOrFallback(item, isCircle: isArtist),
                  ),
                ),
                // Badge de tipo (Playlist, Álbum, Artista)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(item.type).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: _getBadgeIcon(item.type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói lista vertical de seções adicionais
  Widget _buildVerticalSection(BuildContext context, HomeSectionModel section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          itemCount: section.items.length,
          itemBuilder: (context, index) {
            final item = section.items[index];
            final rankNumber = (index + 1).toString().padLeft(2, '0');

            return InkWell(
              onTap: () => _onItemTap(context, item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    Text(
                      rankNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(item.type == HomeItemType.artist ? 25 : 8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: _buildImageOrFallback(item, width: 50, height: 50, isCircle: item.type == HomeItemType.artist),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _getBadgeColor(item.type),
                              shape: BoxShape.circle,
                            ),
                            child: _getBadgeIcon(item.type),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
