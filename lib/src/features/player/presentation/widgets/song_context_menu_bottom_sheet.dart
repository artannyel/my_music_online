import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../playlist/domain/models/playlist_model.dart';
import '../../../playlist/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import '../../domain/models/player_state_model.dart';
import '../controllers/player_controller.dart';

void showSongContextMenuBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  required AudioTrackModel track,
  String? artistId,
  String? albumId,
  bool isFromQueue = false,
  int queueIndex = -1,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SongContextMenuContent(
      track: track,
      artistId: artistId,
      albumId: albumId,
      isFromQueue: isFromQueue,
      queueIndex: queueIndex,
    ),
  );
}

class _SongContextMenuContent extends ConsumerWidget {
  final AudioTrackModel track;
  final String? artistId;
  final String? albumId;
  final bool isFromQueue;
  final int queueIndex;

  const _SongContextMenuContent({
    required this.track,
    this.artistId,
    this.albumId,
    this.isFromQueue = false,
    this.queueIndex = -1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    image: track.thumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(track.thumbnailUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: track.thumbnailUrl == null
                      ? const Icon(Icons.music_note, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
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
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MenuOption(
            icon: Icons.play_arrow_rounded,
            label: 'Tocar',
            subtitle: 'Substitui a fila e toca esta música',
            onTap: () {
              Navigator.of(context).pop();
              ref.read(playerControllerProvider.notifier).playTrackWithRadio(track);
            },
          ),
          const SizedBox(height: 4),
          _MenuOption(
            icon: Icons.queue_music,
            label: 'Adicionar à fila',
            subtitle: 'Coloca no final da fila de reprodução',
            onTap: () {
              ref.read(playerControllerProvider.notifier).addToQueue(track);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adicionada à fila'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          _MenuOption(
            icon: Icons.skip_next,
            label: 'Tocar a seguir',
            subtitle: 'Toca logo após a música atual',
            onTap: () {
              final playerState = state;
              if (playerState.currentTrack == null) {
                ref.read(playerControllerProvider.notifier).playTrack(track);
              } else {
                ref.read(playerControllerProvider.notifier).insertNext(track);
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adicionada para tocar a seguir'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          _MenuOption(
            icon: Icons.playlist_add,
            label: 'Salvar na Playlist',
            subtitle: 'Adiciona a uma das suas playlists',
            onTap: () {
              Navigator.of(context).pop();
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
          if (artistId != null) ...[
            const SizedBox(height: 4),
            _MenuOption(
              icon: Icons.person,
              label: 'Ir para o Artista',
              subtitle: track.artistName,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/artist/$artistId');
              },
            ),
          ],
          if (albumId != null) ...[
            const SizedBox(height: 4),
            _MenuOption(
              icon: Icons.album,
              label: 'Ir para o Álbum',
              subtitle: track.albumName ?? 'Ver álbum',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/album/$albumId');
              },
            ),
          ],
          if (isFromQueue && queueIndex >= 0) ...[
            const SizedBox(height: 4),
            _MenuOption(
              icon: Icons.remove_circle_outline,
              label: 'Remover da fila',
              subtitle: 'Remove esta faixa da fila de reprodução',
              iconColor: AppColors.error,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(playerControllerProvider.notifier).removeFromQueue(queueIndex);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: iconColor ?? AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
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
    );
  }
}
