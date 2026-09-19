import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/views/full_player_screen.dart';
import '../../domain/models/download_task_model.dart';
import '../../domain/models/offline_track_model.dart';
import '../controllers/download_controller.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
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
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.sd_storage_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Espaço Ocupado: ${_formatBytes(downloadState.totalStorageBytes)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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

                // Card de Downloads em Andamento (se houver)
                _buildActiveDownloadsCard(context, downloadState.activeDownloads, downloadNotifier),

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

  Widget _buildActiveDownloadsCard(
    BuildContext context,
    Map<String, DownloadTaskModel> activeDownloads,
    DownloadController downloadNotifier,
  ) {
    if (activeDownloads.isEmpty) return const SizedBox.shrink();

    final activeTasks = activeDownloads.values.toList();
    final downloadingCount = activeTasks.where((t) => t.status == DownloadStatus.downloading).length;
    final pendingCount = activeTasks.where((t) => t.status == DownloadStatus.pending).length;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Downloads em Andamento (${activeTasks.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => downloadNotifier.cancelAllActiveDownloads(),
                icon: const Icon(Icons.close, color: AppColors.error, size: 16),
                label: const Text(
                  'Cancelar Todos',
                  style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$downloadingCount baixando • $pendingCount na fila aguardando',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: activeTasks.length,
              separatorBuilder: (_, index) => const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final task = activeTasks[index];
                final isDownloading = task.status == DownloadStatus.downloading;
                final progressPercent = (task.progress * 100).toInt();

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: AppColors.cardBackground,
                      child: task.thumbnailUrl != null
                          ? Image.network(task.thumbnailUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note, color: AppColors.primary, size: 20),
                    ),
                  ),
                  title: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isDownloading ? 'Baixando... $progressPercent%' : 'Na fila (Aguardando...)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isDownloading ? FontWeight.bold : FontWeight.normal,
                              color: isDownloading ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                          if (task.playlistName != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                task.playlistName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: isDownloading ? (task.progress > 0 ? task.progress : null) : 0,
                        backgroundColor: AppColors.cardBackground,
                        color: isDownloading ? AppColors.primary : AppColors.divider,
                        minHeight: 3,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.textMuted, size: 18),
                    tooltip: 'Cancelar este download',
                    onPressed: () => downloadNotifier.cancelDownload(task.trackId),
                  ),
                );
              },
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
            onTap: () => _showOfflinePlaylistDetailSheet(context, playlistName),
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

  void _showOfflinePlaylistDetailSheet(BuildContext context, String playlistName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OfflinePlaylistDetailSheet(playlistName: playlistName),
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
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                confirmDismiss: (direction) async {
                  final confirm = await showConfirmDeleteDialog(
                    context: context,
                    title: 'Excluir Download?',
                    message: 'Tem certeza que deseja excluir o download de "${track.title}" do seu dispositivo?',
                    confirmLabel: 'Excluir',
                  );
                  return confirm ?? false;
                },
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

/// Modal Bottom Sheet que exibe a lista completa de faixas contidas em uma playlist/álbum off-line.
class _OfflinePlaylistDetailSheet extends ConsumerWidget {
  final String playlistName;

  const _OfflinePlaylistDetailSheet({required this.playlistName});

  String _formatTrackDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final offlinePlaylists = ref.watch(offlinePlaylistsProvider);
    final tracks = offlinePlaylists[playlistName] ?? [];
    final playerState = ref.watch(playerControllerProvider);
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);

    final totalFolderBytes = tracks.fold<int>(0, (sum, t) => sum + t.fileSizeBytes);

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: SafeArea(
          top: false,
          child: Column(
          children: [
            // Barra de arraste superior
            const SizedBox(height: 12),
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

            // Cabeçalho da Playlist Off-line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tracks.length} músicas • ${_formatBytes(totalFolderBytes)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botões de Ação: Tocar Tudo / Aleatório / Excluir Pasta
            if (tracks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final queue = tracks.map((t) => t.toAudioTrack()).toList();
                          ref.read(playerControllerProvider.notifier).playQueue(queue, initialIndex: 0);
                          Navigator.pop(context);
                          FullPlayerScreen.show(context);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                        label: const Text(
                          'Tocar Tudo',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        final queue = tracks.map((t) => t.toAudioTrack()).toList();
                        final shuffled = List<AudioTrackModel>.from(queue)..shuffle();
                        ref.read(playerControllerProvider.notifier).playQueue(shuffled, initialIndex: 0);
                        Navigator.pop(context);
                        FullPlayerScreen.show(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.shuffle_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                      tooltip: 'Excluir pasta',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Excluir pasta?', style: TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              'Deseja remover todas as ${tracks.length} músicas de "$playlistName"?',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  downloadNotifier.deleteOfflinePlaylist(playlistName);
                                  Navigator.pop(context);
                                },
                                child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),

            // Lista de Músicas da Playlist
            Expanded(
              child: tracks.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma faixa restante nesta pasta.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: tracks.length,
                      separatorBuilder: (_, index) => const Divider(color: AppColors.divider, height: 1),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isPlaying = playerState.currentTrack?.videoId == track.videoId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: SizedBox(
                            width: 32,
                            child: Center(
                              child: isPlaying
                                  ? const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20)
                                  : Text(
                                      '${index + 1}'.padLeft(2, '0'),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                              color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${track.artistName} • ${track.audioFormat.name.toUpperCase()} • ${_formatBytes(track.fileSizeBytes)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTrackDuration(track.duration),
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                                tooltip: 'Remover dos downloads',
                                onPressed: () {
                                  downloadNotifier.deleteOfflineTrack(track.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            final queue = tracks.map((t) => t.toAudioTrack()).toList();
                            ref.read(playerControllerProvider.notifier).playQueue(queue, initialIndex: index);
                            Navigator.pop(context);
                            FullPlayerScreen.show(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
