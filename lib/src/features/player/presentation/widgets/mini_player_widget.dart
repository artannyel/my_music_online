import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/player_controller.dart';
import '../views/full_player_screen.dart';

/// MiniPlayerWidget exibe a barra inferior flutuante com a música em reprodução,
/// progresso, play/pause e atalho para abrir o player em tela cheia.
class MiniPlayerWidget extends ConsumerWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    final progressRatio = playerState.duration.inMilliseconds > 0
        ? (playerState.position.inMilliseconds / playerState.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: GestureDetector(
        onTap: () {
          FullPlayerScreen.show(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Capa do Álbum / Música
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
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
                    const SizedBox(width: 12),

                    // Título e Artista
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artistName,
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

                    // Controles Play / Pause / Loading e Next
                    if (playerState.isBuffering)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                        onPressed: () {
                          ref.read(playerControllerProvider.notifier).togglePlayPause();
                        },
                      ),

                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).nextTrack();
                      },
                    ),
                  ],
                ),
              ),

              // Barra fina de progresso na borda inferior do MiniPlayer
              LinearProgressIndicator(
                value: progressRatio,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
                minHeight: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
