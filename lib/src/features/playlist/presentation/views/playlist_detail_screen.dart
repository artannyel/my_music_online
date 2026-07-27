import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/views/full_player_screen.dart';
import '../../../player/presentation/widgets/song_context_menu_bottom_sheet.dart';
import '../../domain/models/playlist_model.dart';
import '../controllers/playlist_controller.dart';

/// PlaylistDetailScreen exibe o cabeçalho expandido da playlist, suas músicas ao vivo (YTMusic)
/// ou armazenadas (Firestore), permitindo salvar na biblioteca ou criar uma cópia customizada.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final String? url;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.url,
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
    final playlistAsync = ref.watch(playlistDetailsProvider((id: widget.playlistId, url: widget.url)));
    final currentUser = ref.watch(currentUserProvider);
    final playerState = ref.watch(playerControllerProvider);

    final playlist = playlistAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: (_showFloatingPlayButton && playlist != null && playlist.tracks.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () {
                final queue = _mapTracksToAudioQueue(playlist.tracks);
                ref.read(playerControllerProvider.notifier).playQueue(
                  queue, 
                  isRadioMode: playlist.isMix,
                  mixUrl: playlist.isMix ? widget.url : null,
                  mixNextPageToken: playlist.isMix ? playlist.nextPageUrl : null,
                );
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
          final isOwner = currentUser != null && isCustom && playlist.userId == currentUser.id;

          final isSavedAsync = currentUser != null
              ? ref.watch(isPlaylistSavedProvider((userId: currentUser.id, playlistId: playlist.id)))
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
                              userId: currentUser.id,
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
                              userId: currentUser.id,
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
                          ref.invalidate(userPlaylistsStreamProvider(currentUser.id));
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
                      onPressed: () => _showCopyPlaylistDialog(context, playlist, currentUser.id),
                    ),
                    if (isOwner) ...[
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: AppColors.textPrimary),
                        ),
                        tooltip: 'Editar playlist',
                        onPressed: () => _showEditPlaylistDialog(context, playlist, currentUser.id),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.error),
                        ),
                        tooltip: 'Excluir playlist',
                        onPressed: () => _confirmDeletePlaylist(context, playlist, ref),
                      ),
                    ],
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
                      if (playlist.isMix)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.all_inclusive, color: AppColors.primary, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Mix Infinito',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!playlist.isMix)
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
                                      ref.read(playerControllerProvider.notifier).playQueue(
                                        queue, 
                                        initialIndex: 0, 
                                        isRadioMode: playlist.isMix,
                                        mixUrl: playlist.isMix ? widget.url : null,
                                        mixNextPageToken: playlist.isMix ? playlist.nextPageUrl : null,
                                      );
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
                            onPressed: playlist.tracks.isEmpty
                                ? null
                                : () {
                                    final queue = _mapTracksToAudioQueue(playlist.tracks);
                                    final shuffledTracks = List<AudioTrackModel>.from(queue)..shuffle();
                                    ref.read(playerControllerProvider.notifier).playQueue(
                                      shuffledTracks, 
                                      initialIndex: 0, 
                                      isRadioMode: playlist.isMix,
                                      mixUrl: playlist.isMix ? widget.url : null,
                                      mixNextPageToken: playlist.isMix ? playlist.nextPageUrl : null,
                                    );
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
              else if (isOwner)
                SliverToBoxAdapter(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: playlist.tracks.length,
                    onReorderItem: (oldIndex, newIndex) {
                      final tracks = List<PlaylistTrackModel>.from(playlist.tracks);
                      final track = tracks.removeAt(oldIndex);
                      tracks.insert(newIndex, track);
                      ref.read(playlistDetailsProvider((id: widget.playlistId, url: widget.url)).notifier).updateTracks(tracks);
                      ref.read(playlistMutationsProvider.notifier).reorderPlaylistTracks(
                        playlistId: playlist.id,
                        tracks: tracks,
                      );
                    },
                    itemBuilder: (context, index) {
                      final track = playlist.tracks[index];
                      final currentTrack = playerState.currentTrack;
                      final isPlayingThisTrack = currentTrack != null &&
                          (currentTrack.videoId == (track.videoId ?? track.id) || currentTrack.id == track.id);
                      return Dismissible(
                        key: ValueKey('playlist_track_${track.id}_$index'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.error),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.error),
                        ),
                        confirmDismiss: (direction) async {
                          final updated = List<PlaylistTrackModel>.from(playlist.tracks)..removeAt(index);
                          ref.read(playlistDetailsProvider((id: widget.playlistId, url: widget.url)).notifier).updateTracks(updated);
                          await ref.read(playlistMutationsProvider.notifier).removeTrackFromPlaylist(
                            playlistId: playlist.id,
                            trackId: track.id,
                          );
                          return false;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Material(
                            color: isPlayingThisTrack
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPlayingThisTrack ? AppColors.primary : AppColors.divider,
                                  width: isPlayingThisTrack ? 1.5 : 0.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48, height: 48,
                                    child: track.thumbnailUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: track.thumbnailUrl!, fit: BoxFit.cover,
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
                                title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isPlayingThisTrack ? FontWeight.bold : FontWeight.w600,
                                    color: isPlayingThisTrack ? AppColors.primary : AppColors.textPrimary,
                                  )),
                                subtitle: Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPlayingThisTrack ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                                  )),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlayingThisTrack)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 18),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                                      onPressed: () => showSongContextMenuBottomSheet(
                                        context, ref,
                                        track: AudioTrackModel(
                                          id: track.id, videoId: track.videoId ?? track.id,
                                          title: track.title, artistName: track.artistName,
                                          albumName: track.albumName, thumbnailUrl: track.thumbnailUrl,
                                          duration: track.duration,
                                        ),
                                      ),
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 22),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (isPlayingThisTrack) {
                                    FullPlayerScreen.show(context);
                                  } else {
                                    final queue = _mapTracksToAudioQueue(playlist.tracks);
                                    ref.read(playerControllerProvider.notifier).playQueue(
                                      queue, initialIndex: index,
                                      isRadioMode: playlist.isMix,
                                      mixUrl: playlist.isMix ? widget.url : null,
                                      mixNextPageToken: playlist.isMix ? playlist.nextPageUrl : null,
                                    );
                                    FullPlayerScreen.show(context);
                                  }
                                },
                                onLongPress: () => showSongContextMenuBottomSheet(
                                  context, ref,
                                  track: AudioTrackModel(
                                    id: track.id, videoId: track.videoId ?? track.id,
                                    title: track.title, artistName: track.artistName,
                                    albumName: track.albumName, thumbnailUrl: track.thumbnailUrl,
                                    duration: track.duration,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                                      child: Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                                    ),
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                                      onPressed: () async {
                                        final result = await ref
                                            .read(playlistMutationsProvider.notifier)
                                            .removeTrackFromPlaylist(
                                              playlistId: playlist.id,
                                              trackId: track.id,
                                            );
                                        if (result == true) {
                                          ref.invalidate(playlistDetailsProvider((id: widget.playlistId, url: widget.url)));
                                        }
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                                    onPressed: () => showSongContextMenuBottomSheet(
                                      context,
                                      ref,
                                      track: AudioTrackModel(
                                        id: track.id,
                                        videoId: track.videoId ?? track.id,
                                        title: track.title,
                                        artistName: track.artistName,
                                        albumName: track.albumName,
                                        thumbnailUrl: track.thumbnailUrl,
                                        duration: track.duration,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (isPlayingThisTrack) {
                                  FullPlayerScreen.show(context);
                                } else {
                                  final queue = _mapTracksToAudioQueue(playlist.tracks);
                                  ref.read(playerControllerProvider.notifier).playQueue(
                                    queue, 
                                    initialIndex: index, 
                                    isRadioMode: playlist.isMix,
                                    mixUrl: playlist.isMix ? widget.url : null,
                                    mixNextPageToken: playlist.isMix ? playlist.nextPageUrl : null,
                                  );
                                  FullPlayerScreen.show(context);
                                }
                              },
                              onLongPress: () => showSongContextMenuBottomSheet(
                                context,
                                ref,
                                track: AudioTrackModel(
                                  id: track.id,
                                  videoId: track.videoId ?? track.id,
                                  title: track.title,
                                  artistName: track.artistName,
                                  albumName: track.albumName,
                                  thumbnailUrl: track.thumbnailUrl,
                                  duration: track.duration,
                                ),
                              ),
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

  void _showCopyPlaylistDialog(BuildContext context, PlaylistModel playlist, String userId) {
    final titleController = TextEditingController(text: '${playlist.title} (Cópia)');
    final descriptionController = TextEditingController(text: playlist.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.copy, color: AppColors.primary, size: 24),
            SizedBox(width: 12),
            Text('Copiar Playlist', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Título da cópia *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe um título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final customCopy = await ref.read(playlistMutationsProvider.notifier).duplicatePlaylistAsCustom(
                userId: userId,
                sourcePlaylist: playlist,
                customTitle: titleController.text.trim(),
                customDescription: descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
              );
              if (context.mounted && customCopy != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cópia "${customCopy.title}" criada!'), backgroundColor: AppColors.success),
                );
                context.push('/playlist/${customCopy.id}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Copiar', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showEditPlaylistDialog(BuildContext context, PlaylistModel playlist, String userId) {
    final titleController = TextEditingController(text: playlist.title);
    final descriptionController = TextEditingController(text: playlist.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary, size: 24),
            SizedBox(width: 12),
            Text('Editar Playlist', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe um título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await ref.read(playlistMutationsProvider.notifier).updatePlaylist(
                playlistId: playlist.id,
                title: titleController.text.trim(),
                description: descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ref.invalidate(playlistDetailsProvider((id: widget.playlistId, url: widget.url)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist atualizada!'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Salvar', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylist(BuildContext context, PlaylistModel playlist, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir playlist?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Tem certeza que deseja excluir "${playlist.title}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(playlistMutationsProvider.notifier).deletePlaylist(playlist.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success && context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${playlist.title}" excluída'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
