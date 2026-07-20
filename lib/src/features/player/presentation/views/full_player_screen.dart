import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../playlist/domain/models/playlist_model.dart';
import '../../../playlist/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import '../../domain/models/player_state_model.dart';
import '../controllers/player_controller.dart';

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
    const double itemHeight = 64.0;
    final double initialOffset = state.currentIndex > 0
        ? (state.currentIndex * itemHeight)
        : 0.0;
    final scrollController = ScrollController(initialScrollOffset: initialOffset);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fila de Reprodução',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
                child: ListView.builder(
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: state.queue.length,
                  itemBuilder: (context, index) {
                    final item = state.queue[index];
                    final isCurrent = index == state.currentIndex;

                    return SizedBox(
                      height: itemHeight,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
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
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          item.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.primary,
                                size: 22,
                              )
                            : null,
                        onTap: isCurrent
                            ? null
                            : () {
                                ref.read(playerControllerProvider.notifier).playQueue(state.queue, initialIndex: index);
                                Navigator.pop(context);
                              },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
