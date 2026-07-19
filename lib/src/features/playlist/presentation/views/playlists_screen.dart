import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/playlist_model.dart';
import '../controllers/playlist_controller.dart';
import '../widgets/create_playlist_dialog.dart';

/// PlaylistsScreen exibe a biblioteca de playlists salvas do usuário ou uma tela convidativa para Login.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Minhas Playlists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
              onPressed: () => CreatePlaylistDialog.show(context, userId: user.uid),
            ),
        ],
      ),
      body: user == null
          ? _buildGuestView(context)
          : _buildUserPlaylistsView(context, ref, user.uid),
    );
  }

  /// Visão exibida para visitantes não logados
  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.queue_music,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Suas Playlists em um só lugar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Crie listas personalizadas com suas faixas favoritas e sincronize entre todos os seus dispositivos com sua conta do Firebase.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(RouteNames.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fazer Login ou Cadastrar-se',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visão exibida para usuários autenticados com suas playlists do Firestore
  Widget _buildUserPlaylistsView(BuildContext context, WidgetRef ref, String userId) {
    final playlistsAsync = ref.watch(userPlaylistsStreamProvider(userId));

    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.playlist_add_check,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Você ainda não criou ou salvou nenhuma playlist.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => CreatePlaylistDialog.show(context, userId: userId),
                  icon: const Icon(Icons.add, color: AppColors.textPrimary),
                  label: const Text('Criar Primeira Playlist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            final isCustom = playlist.type == PlaylistType.custom;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: playlist.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: playlist.coverUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.cardBackground,
                                  child: const Icon(Icons.queue_music, color: AppColors.primary),
                                ),
                              )
                            : Container(
                                color: AppColors.cardBackground,
                                child: const Icon(Icons.queue_music, color: AppColors.primary),
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            playlist.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCustom ? AppColors.primary : AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCustom ? 'Sua' : 'YT',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${isCustom ? '${playlist.tracks.length} faixas' : 'Salva do YouTube'} ${playlist.description != null ? '• ${playlist.description}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Remover Playlist', style: TextStyle(color: AppColors.textPrimary)),
                            content: Text('Tem certeza que deseja remover "${playlist.title}" da sua biblioteca?', style: const TextStyle(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remover', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          ref.read(playlistMutationsProvider.notifier).deletePlaylist(playlist.id);
                        }
                      },
                    ),
                    onTap: () {
                      final targetId = playlist.originalYtPlaylistId ?? playlist.id;
                      context.push('/playlist/$targetId');
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => const Center(
        child: Text(
          'Erro ao carregar playlists.',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
