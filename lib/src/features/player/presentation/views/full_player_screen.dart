import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../playlist/domain/models/playlist_model.dart';
import '../../../playlist/presentation/controllers/playlist_controller.dart';
import '../../../playlist/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import '../../../playlist/presentation/widgets/create_playlist_dialog.dart';
import '../../domain/models/player_state_model.dart';
import '../controllers/player_controller.dart';
import '../widgets/song_context_menu_bottom_sheet.dart';

/// FullPlayerScreen exibe o player de áudio em tela cheia (estilo YouTube Music)
/// com iluminação Neon Magenta/Violet, barra de progresso scrubber, fila e controle de repetição.
class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FullPlayerScreen(),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;

    if (track == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(
          child: Text('Nenhuma música em reprodução.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final double maxDurationMs = playerState.duration.inMilliseconds > 0
        ? playerState.duration.inMilliseconds.toDouble()
        : 1.0;
    final double currentPositionMs = playerState.position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary, size: 36),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'TOCANDO AGORA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_play_rounded, color: AppColors.textPrimary, size: 28),
              onPressed: () => _showQueueBottomSheet(context, ref, playerState),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Arte da Capa com Brilho Neon Magenta/Violet e Suporte a Gesto de Arraste (Swipe)
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -200) {
                        // Arrastar para a esquerda: Próxima música
                        ref.read(playerControllerProvider.notifier).nextTrack();
                      } else if (details.primaryVelocity! > 200) {
                        // Arrastar para a direita: Música anterior
                        ref.read(playerControllerProvider.notifier).previousTrack();
                      }
                    }
                  },
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.accentGlow,
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.cardBackground,
                                  child: const Icon(Icons.music_note, size: 100, color: AppColors.primary),
                                ),
                              )
                            : Container(
                                color: AppColors.cardBackground,
                                child: const Icon(Icons.music_note, size: 100, color: AppColors.primary),
                              ),
                      ),
                    ),
                  ),
                ),

                // Título da Música, Artista e Ações Rápidas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 28),
                      onPressed: () {
                        AddToPlaylistBottomSheet.show(
                          context,
                          track: PlaylistTrackModel(
                            id: track.id,
                            title: track.title,
                            artistName: track.artistName,
                            albumName: track.albumName,
                            thumbnailUrl: track.thumbnailUrl,
                            videoId: track.videoId,
                            duration: track.duration,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Scrubber Slider (Barra de Progresso com Tempo Decorrido/Total)
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: AppColors.textPrimary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: currentPositionMs,
                        min: 0.0,
                        max: maxDurationMs,
                        onChanged: (value) {
                          ref
                              .read(playerControllerProvider.notifier)
                              .seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerState.position),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            _formatDuration(playerState.duration),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Botões Principais de Controle (Shuffle, Prev, Play/Pause, Next, Repeat)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerState.isShuffleEnabled ? AppColors.primary : AppColors.textMuted,
                        size: 24,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).toggleShuffle();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 38),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).previousTrack();
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(playerControllerProvider.notifier).togglePlayPause();
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGlow,
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: playerState.isBuffering
                              ? const CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 3)
                              : Icon(
                                  playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: AppColors.textPrimary,
                                  size: 40,
                                ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 38),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).nextTrack();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        playerState.repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: playerState.repeatMode != RepeatMode.off ? AppColors.primary : AppColors.textMuted,
                        size: 24,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).toggleRepeatMode();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context, WidgetRef ref, PlayerStateModel state) {
    const double itemHeight = 60.0;
    final double initialOffset = state.currentIndex > 0
        ? (state.currentIndex * itemHeight)
        : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _QueueBottomSheetContent(initialScrollOffset: initialOffset),
    );
  }
}

class _QueueBottomSheetContent extends ConsumerStatefulWidget {
  final double initialScrollOffset;

  const _QueueBottomSheetContent({required this.initialScrollOffset});

  @override
  ConsumerState<_QueueBottomSheetContent> createState() => _QueueBottomSheetContentState();
}

class _QueueBottomSheetContentState extends ConsumerState<_QueueBottomSheetContent> {
  final Set<int> _selectedIndices = {};
  late final ScrollController _scrollController;

  bool get _isSelectionMode => _selectedIndices.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (widget.initialScrollOffset > maxScroll) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.jumpTo(widget.initialScrollOffset);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIndices.clear());
  }

  Future<void> _saveSelectedAsPlaylist() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para criar playlists'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentState = ref.read(playerControllerProvider);
    final selectedTracks = _selectedIndices
        .map((i) => currentState.queue[i])
        .toList();

    if (selectedTracks.isEmpty) return;

    final playlist = await CreatePlaylistDialog.show(
      context,
      userId: user.id,
    );

    if (playlist == null || !context.mounted) return;

    final notifier = ref.read(playlistMutationsProvider.notifier);
    int addedCount = 0;

    for (final track in selectedTracks) {
      final success = await notifier.addTrackToPlaylist(
        playlistId: playlist.id,
        track: PlaylistTrackModel(
          id: track.id,
          title: track.title,
          artistName: track.artistName,
          albumName: track.albumName,
          thumbnailUrl: track.thumbnailUrl,
          videoId: track.videoId,
          duration: track.duration,
        ),
      );
      if (success) addedCount++;
    }

    if (mounted) {
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount faixas adicionadas a "${playlist.title}"'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _saveQueueAsPlaylist() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para criar playlists'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentState = ref.read(playerControllerProvider);
    if (currentState.queue.isEmpty) return;

    final playlist = await CreatePlaylistDialog.show(context, userId: user.id);
    if (playlist == null || !context.mounted) return;

    final notifier = ref.read(playlistMutationsProvider.notifier);
    int addedCount = 0;

    for (final track in currentState.queue) {
      final success = await notifier.addTrackToPlaylist(
        playlistId: playlist.id,
        track: PlaylistTrackModel(
          id: track.id,
          title: track.title,
          artistName: track.artistName,
          albumName: track.albumName,
          thumbnailUrl: track.thumbnailUrl,
          videoId: track.videoId,
          duration: track.duration,
        ),
      );
      if (success) addedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount faixas salvas em "${playlist.title}"'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentState = ref.watch(playerControllerProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final queue = currentState.queue;
    final currentIndex = currentState.currentIndex;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isSelectionMode)
            _buildSelectionBar()
          else
            _buildHeader(currentState),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
            child: queue.isEmpty
                ? const Center(
                    child: Text('Nenhuma faixa na fila.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    scrollController: _scrollController,
                    shrinkWrap: true,
                    itemCount: queue.length,
                    onReorderItem: (oldIndex, newIndex) {
                      ref.read(playerControllerProvider.notifier).reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = index == currentIndex;
                      final isSelected = _selectedIndices.contains(index);

                      return Dismissible(
                        key: ValueKey('queue_${item.id}_$index'),
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
                          if (index == currentIndex) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Não é possível remover a faixa atual'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return false;
                          }
                          ref.read(playerControllerProvider.notifier).removeFromQueue(index);
                          return false;
                        },
                        child: _buildQueueItem(
                          item: item,
                          index: index,
                          isCurrent: isCurrent,
                          isSelected: isSelected,
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(index);
                            } else if (!isCurrent) {
                              ref.read(playerControllerProvider.notifier).playTrackFromQueueIndex(index);
                              Navigator.pop(context);
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _toggleSelection(index);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PlayerStateModel currentState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Fila de Reprodução',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (currentState.mixUrl != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Mix Infinito',
                  style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (currentState.isRadioMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Rádio',
                  style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentState.queue.length} faixas',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (currentState.queue.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.playlist_add, color: AppColors.textSecondary, size: 20),
                tooltip: 'Salvar fila como playlist',
                onPressed: _saveQueueAsPlaylist,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.clear_all, color: AppColors.textSecondary, size: 20),
                tooltip: 'Limpar fila',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Limpar fila?', style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text('Todas as faixas serão removidas.', style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(playerControllerProvider.notifier).clearQueue();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Limpar', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _clearSelection,
          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
          label: Text(
            '${_selectedIndices.length} selecionada(s)',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _saveSelectedAsPlaylist,
          icon: const Icon(Icons.playlist_add, size: 20),
          label: const Text('Salvar como Playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem({
    required AudioTrackModel item,
    required int index,
    required bool isCurrent,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Padding(
      key: ValueKey('queue_item_${item.id}_$index'),
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : isCurrent
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.thumbnailUrl!,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent && !_isSelectionMode)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 18),
                  ),
                if (!_isSelectionMode)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => showSongContextMenuBottomSheet(
                      context,
                      ref,
                      track: item,
                      isFromQueue: true,
                      queueIndex: index,
                    ),
                  ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
