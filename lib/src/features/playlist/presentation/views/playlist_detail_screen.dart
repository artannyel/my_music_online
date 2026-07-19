import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/playlist_controller.dart';

/// PlaylistDetailScreen exibe o cabeçalho expandido da playlist e suas músicas.
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailsProvider(playlistId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: Text('Playlist não encontrada.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }

          final isOwner = currentUser != null && playlist.userId == currentUser.uid;

          return CustomScrollView(
            slivers: [
              // Sliver AppBar com Capa da Playlist
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: playlist.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.cardBackground,
                            child: const Icon(Icons.queue_music, size: 80, color: AppColors.primary),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.cardBackground,
                          child: const Icon(Icons.queue_music, size: 80, color: AppColors.primary),
                        ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Metadados da Playlist
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (playlist.description != null && playlist.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          playlist.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${playlist.tracks.length} músicas',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: playlist.tracks.isEmpty ? null : () {},
                              icon: const Icon(Icons.play_arrow, color: AppColors.textPrimary),
                              label: const Text('Tocar Tudo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: playlist.tracks.isEmpty ? null : () {},
                            icon: const Icon(Icons.shuffle, color: AppColors.textPrimary),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de Músicas
              if (playlist.tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Esta playlist ainda não tem faixas.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = playlist.tracks[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: track.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: track.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.cardBackground,
                                        child: const Icon(Icons.music_note, color: AppColors.primary),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.cardBackground,
                                      child: const Icon(Icons.music_note, color: AppColors.primary),
                                    ),
                            ),
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            track.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isOwner
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                                  onPressed: () {
                                    ref
                                        .read(playlistMutationsProvider.notifier)
                                        .removeTrackFromPlaylist(
                                          playlistId: playlist.id,
                                          trackId: track.id,
                                        );
                                  },
                                )
                              : null,
                          onTap: () {},
                        ),
                      );
                    },
                    childCount: playlist.tracks.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('Erro ao carregar detalhes da playlist.', style: TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}
