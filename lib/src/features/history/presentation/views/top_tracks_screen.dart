import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_fallback_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/top_track_model.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../controllers/history_controller.dart';

/// Tela de Top Tracks (Geral e Mensal).
class TopTracksScreen extends ConsumerStatefulWidget {
  const TopTracksScreen({super.key});

  @override
  ConsumerState<TopTracksScreen> createState() => _TopTracksScreenState();
}

class _TopTracksScreenState extends ConsumerState<TopTracksScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final historyController = ref.read(historyControllerProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    final Future<List<TopTrackModel>> topTracksFuture =
        historyController.getTopTracks(userId);
    final Future<List<TopTrackModel>> monthlyTopTracksFuture = () {
      final now = DateTime.now();
      return historyController.getMonthlyTopTracks(userId, now.month, now.year);
    }();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Top 20 Mais Tocadas'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Geral',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedTabIndex == 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Deste Mês',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedTabIndex == 1
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo da aba
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildTopTracksFutureBuilder(context, topTracksFuture, false)
                : _buildTopTracksFutureBuilder(context, monthlyTopTracksFuture, true),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracksFutureBuilder(
      BuildContext context, Future<List<TopTrackModel>> future, bool monthly) {
    return FutureBuilder<List<TopTrackModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return OfflineFallbackWidget(
            onRetry: () => setState(() {}),
          );
        }
        final tracks = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final rankNumber = (index + 1).toString().padLeft(2, '0');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        rankNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.thumbnailUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.cardBackground, child: const CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (context, url, error) => Container(color: AppColors.cardBackground, child: const Icon(Icons.music_note, color: AppColors.primary, size: 16)),
                              )
                            : Container(color: AppColors.cardBackground, child: const Icon(Icons.music_note, color: AppColors.primary, size: 16)),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Text(
                  '${track.playCount ?? 0} execuções',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  final queue = tracks.map((t) => AudioTrackModel(
                    id: t.id,
                    videoId: t.id,
                    title: t.title,
                    artistName: t.artistName,
                    thumbnailUrl: t.thumbnailUrl,
                    duration: t.duration,
                  )).toList();
                  ref.read(playerControllerProvider.notifier).playQueue(queue, initialIndex: index);
                },
              ),
            ),
          );
          },
        );
      },
    );
  }
}
