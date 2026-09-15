import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/views/full_player_screen.dart';
import '../../domain/models/offline_track_model.dart';
import '../controllers/download_controller.dart';

/// DownloadsScreen exibe as músicas e playlists salvas off-line divididas por pastas e faixas.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1000) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadControllerProvider);
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);
    final offlinePlaylists = ref.watch(offlinePlaylistsProvider);
    final offlineTracks = downloadState.offlineTracks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Downloads & Off-line',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (offlineTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              tooltip: 'Limpar todos os downloads',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Limpar todos os downloads?', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text(
                      'Todas as faixas e pastas salvas off-line serão removidas do dispositivo.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () {
                          downloadNotifier.clearAllDownloads();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Limpar Tudo', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Playlists (${offlinePlaylists.length})'),
            Tab(text: 'Todas as Músicas (${offlineTracks.length})'),
          ],
        ),
      ),
      body: downloadState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Banner de Espaço Ocupado no Disco
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppColors.surface.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sd_storage_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Espaço Ocupado: ${_formatBytes(downloadState.totalStorageBytes)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Formato: ${downloadState.preferredFormat.name.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Aba 1: Playlists Baixadas (Pastas)
                      _buildPlaylistsTab(context, ref, offlinePlaylists, downloadNotifier),

                      // Aba 2: Todas as Músicas Off-line
                      _buildTracksTab(context, ref, offlineTracks, downloadNotifier),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlaylistsTab(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<OfflineTrackModel>> offlinePlaylists,
    DownloadController downloadNotifier,
  ) {
    if (offlinePlaylists.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma playlist salva off-line ainda.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final playlistEntries = offlinePlaylists.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: playlistEntries.length,
      itemBuilder: (context, index) {
        final entry = playlistEntries[index];
        final playlistName = entry.key;
        final tracks = entry.value;

        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider, width: 0.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 26),
            ),
            title: Text(
              playlistName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '${tracks.length} músicas salvas na pasta',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                  onPressed: () {
                    final audioQueue = tracks.map((t) => t.toAudioTrack()).toList();
                    ref.read(playerControllerProvider.notifier).playQueue(audioQueue, initialIndex: 0);
                    FullPlayerScreen.show(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                  onPressed: () {
                    downloadNotifier.deleteOfflinePlaylist(playlistName);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTracksTab(
    BuildContext context,
    WidgetRef ref,
    List<OfflineTrackModel> offlineTracks,
    DownloadController downloadNotifier,
  ) {
    if (offlineTracks.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma música baixada off-line.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final queue = offlineTracks.map((t) => t.toAudioTrack()).toList();
                    ref.read(playerControllerProvider.notifier).playQueue(queue, initialIndex: 0);
                    FullPlayerScreen.show(context);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Tocar Tudo Off-line', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: offlineTracks.length,
            itemBuilder: (context, index) {
              final track = offlineTracks[index];

              return Dismissible(
                key: ValueKey('offline_${track.id}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.error.withValues(alpha: 0.2),
                  child: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                onDismissed: (_) {
                  downloadNotifier.deleteOfflineTrack(track.id);
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppColors.cardBackground,
                      child: track.thumbnailUrl != null
                          ? Image.network(track.thumbnailUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note, color: AppColors.primary),
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${track.artistName} • ${track.audioFormat.name.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
                    onPressed: () {
                      final queue = offlineTracks.map((t) => t.toAudioTrack()).toList();
                      ref.read(playerControllerProvider.notifier).playQueue(queue, initialIndex: index);
                      FullPlayerScreen.show(context);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
