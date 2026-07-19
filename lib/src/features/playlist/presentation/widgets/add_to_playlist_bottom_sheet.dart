import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/playlist_model.dart';
import '../controllers/playlist_controller.dart';
import 'create_playlist_dialog.dart';

/// Bottom Sheet modal para adicionar uma música a uma playlist existente do usuário.
/// Se o usuário for um visitante/convidado, solicita login de forma amigável.
class AddToPlaylistBottomSheet extends ConsumerWidget {
  final PlaylistTrackModel track;

  const AddToPlaylistBottomSheet({
    super.key,
    required this.track,
  });

  static Future<void> show(BuildContext context, {required PlaylistTrackModel track}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddToPlaylistBottomSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Se o usuário não estiver logado (Modo Convidado)
    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Faça login para salvar playlists',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Você precisa estar conectado à sua conta para criar e adicionar faixas às suas playlists salvas.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(RouteNames.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entrar ou Criar Conta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    // Se o usuário estiver autenticado
    final playlistsAsync = ref.watch(userPlaylistsStreamProvider(user.uid));

    return Padding(
      padding: const EdgeInsets.all(24.0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Adicionar à Playlist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final newPlaylist = await CreatePlaylistDialog.show(context, userId: user.uid);
                  if (newPlaylist != null && context.mounted) {
                    final success = await ref
                        .read(playlistMutationsProvider.notifier)
                        .addTrackToPlaylist(playlistId: newPlaylist.id, track: track);

                    if (context.mounted && success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Adicionada à playlist "${newPlaylist.title}"'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                label: const Text(
                  'Criar Nova',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Nenhuma playlist criada ainda.\nClique em "Criar Nova" acima.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final containsTrack = playlist.tracks.any((t) => t.id == track.id);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          image: playlist.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(playlist.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: playlist.coverUrl == null
                            ? const Icon(Icons.queue_music, color: AppColors.primary)
                            : null,
                      ),
                      title: Text(
                        playlist.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.tracks.length} músicas',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: containsTrack
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                      onTap: containsTrack
                          ? null
                          : () async {
                              final success = await ref
                                  .read(playlistMutationsProvider.notifier)
                                  .addTrackToPlaylist(playlistId: playlist.id, track: track);

                              if (context.mounted && success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Música adicionada a "${playlist.title}"!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => const Center(
                child: Text(
                  'Erro ao carregar suas playlists.',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
