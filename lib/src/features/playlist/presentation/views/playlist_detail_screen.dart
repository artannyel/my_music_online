import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/views/full_player_screen.dart';
import '../../domain/models/playlist_model.dart';
import '../controllers/playlist_controller.dart';

/// PlaylistDetailScreen exibe o cabeçalho expandido da playlist, suas músicas ao vivo (YTMusic)
/// ou armazenadas (Firestore), permitindo salvar na biblioteca ou criar uma cópia customizada.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  late final ScrollController _scrollController;
  bool _showFloatingPlayButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 320;
    if (shouldShow != _showFloatingPlayButton) {
      setState(() {
        _showFloatingPlayButton = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<AudioTrackModel> _mapTracksToAudioQueue(List<PlaylistTrackModel> tracks) {
    return tracks.map((t) {
      return AudioTrackModel(
        id: t.id,
        videoId: t.videoId ?? t.id,
        title: t.title,
        artistName: t.artistName,
        albumName: t.albumName,
        thumbnailUrl: t.thumbnailUrl,
        duration: t.duration,
      );
    }).toList();
  }

  String _formatTotalDuration(List<PlaylistTrackModel> tracks) {
    final totalSeconds = tracks.fold<int>(0, (sum, t) => sum + (t.duration?.inSeconds ?? 0));
    if (totalSeconds == 0) return '';
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistDetailsProvider(widget.playlistId));
    final currentUser = ref.watch(currentUserProvider);
    final playerState = ref.watch(playerControllerProvider);

    final playlist = playlistAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: (_showFloatingPlayButton && playlist != null && playlist.tracks.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () {
                final queue = _mapTracksToAudioQueue(playlist.tracks);
                ref.read(playerControllerProvider.notifier).playQueue(queue);
                FullPlayerScreen.show(context);
              },
              backgroundColor: AppColors.primary,
              elevation: 8,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.play_arrow,
                color: AppColors.textPrimary,
              ),
            )
          : null,
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: Text(
                  'Playlist não encontrada ou indisponível.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final isCustom = playlist.type == PlaylistType.custom;
          final isOwner = currentUser != null && isCustom && playlist.userId == currentUser.uid;

          final isSavedAsync = currentUser != null
              ? ref.watch(isPlaylistSavedProvider((userId: currentUser.uid, playlistId: playlist.id)))
              : const AsyncValue.data(false);
          final isSaved = isSavedAsync.value ?? false;

          final totalDurationStr = _formatTotalDuration(playlist.tracks);

          return CustomScrollView(
            controller: _scrollController,
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
                actions: [
                  if (currentUser != null) ...[
                    if (!isCustom)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        onPressed: () async {
                          final notifier = ref.read(playlistMutationsProvider.notifier);
                          if (isSaved) {
                            await notifier.unsaveYtPlaylistFromLibrary(
                              userId: currentUser.uid,
                              playlistId: playlist.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Playlist removida da sua biblioteca.'),
                                  backgroundColor: AppColors.surface,
                                ),
                              );
                            }
                          } else {
                            await notifier.saveYtPlaylistToLibrary(
                              userId: currentUser.uid,
                              ytPlaylist: playlist,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Playlist salva na sua biblioteca!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                          ref.invalidate(isPlaylistSavedProvider);
                          ref.invalidate(userPlaylistsStreamProvider(currentUser.uid));
                        },
                      ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.copy, color: AppColors.textPrimary),
                      ),
                      tooltip: 'Criar cópia editável',
                      onPressed: () async {
                        final customCopy = await ref
                            .read(playlistMutationsProvider.notifier)
                            .duplicatePlaylistAsCustom(
                              userId: currentUser.uid,
                              sourcePlaylist: playlist,
                            );

                        if (context.mounted && customCopy != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cópia editável "${customCopy.title}" criada!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          context.push('/playlist/${customCopy.id}');
                        }
                      },
                    ),
                  ],
                ],
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCustom ? AppColors.primary : AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCustom ? 'Sua Playlist' : 'YouTube Music',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                        totalDurationStr.isNotEmpty
                            ? '${playlist.tracks.length} músicas • $totalDurationStr'
                            : '${playlist.tracks.length} músicas',
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
                              onPressed: playlist.tracks.isEmpty
                                  ? null
                                  : () {
                                      final queue = _mapTracksToAudioQueue(playlist.tracks);
                                      ref.read(playerControllerProvider.notifier).playQueue(queue);
                                      FullPlayerScreen.show(context);
                                    },
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
                            onPressed: playlist.tracks.isEmpty
                                ? null
                                : () {
                                    final queue = _mapTracksToAudioQueue(playlist.tracks);
                                    final random = Random();
                                    final randomIndex = random.nextInt(queue.length);
                                    final notifier = ref.read(playerControllerProvider.notifier);
                                    if (!playerState.isShuffleEnabled) {
                                      notifier.toggleShuffle();
                                    }
                                    notifier.playQueue(queue, initialIndex: randomIndex);
                                    FullPlayerScreen.show(context);
                                  },
                            icon: Icon(
                              Icons.shuffle,
                              color: playerState.isShuffleEnabled ? AppColors.primary : AppColors.textPrimary,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: playerState.isShuffleEnabled
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surface,
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
                      final currentTrack = playerState.currentTrack;
                      final isPlayingThisTrack = currentTrack != null &&
                          (currentTrack.videoId == (track.videoId ?? track.id) || currentTrack.id == track.id);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                        child: Material(
                          color: isPlayingThisTrack
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPlayingThisTrack ? AppColors.primary : AppColors.divider,
                                width: isPlayingThisTrack ? 1.5 : 0.5,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isPlayingThisTrack ? FontWeight.bold : FontWeight.w600,
                                  color: isPlayingThisTrack ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                track.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPlayingThisTrack
                                      ? AppColors.primary.withValues(alpha: 0.8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPlayingThisTrack)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6.0),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                                      onPressed: () async {
                                        await ref
                                            .read(playlistMutationsProvider.notifier)
                                            .removeTrackFromPlaylist(
                                              playlistId: playlist.id,
                                              trackId: track.id,
                                            );
                                        ref.invalidate(playlistDetailsProvider(widget.playlistId));
                                      },
                                    ),
                                ],
                              ),
                              onTap: () {
                                if (isPlayingThisTrack) {
                                  FullPlayerScreen.show(context);
                                } else {
                                  final queue = _mapTracksToAudioQueue(playlist.tracks);
                                  ref.read(playerControllerProvider.notifier).playQueue(queue, initialIndex: index);
                                  FullPlayerScreen.show(context);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: playlist.tracks.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
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
