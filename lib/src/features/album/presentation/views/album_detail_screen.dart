import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/views/full_player_screen.dart';
import '../controllers/album_controller.dart';

/// AlbumDetailScreen exibe os detalhes do Álbum no padrão visual do Stitch Design
class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 320 && !_showFab) {
      setState(() => _showFab = true);
    } else if (_scrollController.offset <= 320 && _showFab) {
      setState(() => _showFab = false);
    }
  }

  String _formatTotalDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  String _formatTrackDuration(Duration? duration) {
    if (duration == null || duration == Duration.zero) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final albumAsync = ref.watch(albumDetailProvider(widget.albumId));
    final playerState = ref.watch(playerControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _showFab && (albumAsync.value?.tracks.isNotEmpty ?? false)
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              onPressed: () {
                final album = albumAsync.value!;
                ref.read(playerControllerProvider.notifier).playQueue(album.tracks, initialIndex: 0);
                FullPlayerScreen.show(context);
              },
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            )
          : null,
      body: albumAsync.when(
        data: (album) {
          if (album == null) {
            return Scaffold(
              appBar: AppBar(backgroundColor: AppColors.surface),
              body: const Center(
                child: Text('Álbum não encontrado.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }

          final totalDuration = album.tracks.fold<Duration>(
            Duration.zero,
            (prev, element) => prev + (element.duration ?? Duration.zero),
          );

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header dinâmico com Capa em destaque
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (album.coverUrl != null && album.coverUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: album.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: AppColors.surface),
                        )
                      else
                        Container(
                          color: AppColors.cardBackground,
                          child: const Icon(Icons.album, size: 100, color: AppColors.primary),
                        ),
                      // Overlay com degradê escuro
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              AppColors.background.withValues(alpha: 0.7),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Informações do topo
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              album.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: album.artistId != null && album.artistId!.isNotEmpty
                                  ? () => context.push('/artist/${album.artistId}')
                                  : null,
                              child: Text(
                                album.artistName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${album.year != null ? '${album.year} • ' : ''}${album.trackCount} músicas • ${_formatTotalDuration(totalDuration)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botões de Ação Principais (Tocar / Aleatório)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(playerControllerProvider.notifier).playQueue(album.tracks, initialIndex: 0);
                            FullPlayerScreen.show(context);
                          },
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                          label: const Text('Tocar Tudo', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          final shuffledTracks = List<AudioTrackModel>.from(album.tracks)..shuffle();
                          ref.read(playerControllerProvider.notifier).playQueue(shuffledTracks, initialIndex: 0);
                          FullPlayerScreen.show(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.all(14),
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(Icons.shuffle_rounded, color: AppColors.textPrimary, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de Faixas do Álbum
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = album.tracks[index];
                    final isCurrentPlaying = playerState.currentTrack?.videoId == track.videoId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: SizedBox(
                        width: 32,
                        child: Center(
                          child: isCurrentPlaying
                              ? const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.w500,
                          color: isCurrentPlaying ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      trailing: Text(
                        _formatTrackDuration(track.duration),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      onTap: () {
                        ref.read(playerControllerProvider.notifier).playQueue(album.tracks, initialIndex: index);
                        FullPlayerScreen.show(context);
                      },
                    );
                  },
                  childCount: album.tracks.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(backgroundColor: AppColors.surface),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(backgroundColor: AppColors.surface),
          body: const Center(
            child: Text('Erro ao carregar detalhes do álbum.', style: TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}
