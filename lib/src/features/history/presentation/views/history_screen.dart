import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/offline_fallback_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../controllers/history_controller.dart';

/// Tela principal do histórico do usuário.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Histórico de Reprodução'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: userId.isEmpty
          ? const Center(
              child: Text(
                'Faça login para ver seu histórico.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                ref.invalidate(recentHistoryProvider(userId));
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ref
                          .watch(recentHistoryProvider(userId))
                          .when(
                            data: (logs) {
                              if (logs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Nenhum histórico ainda.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: logs.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(color: AppColors.divider),
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  final thumbUrl = log.thumbnailUrl;
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child:
                                            thumbUrl != null &&
                                                thumbUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: thumbUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                      color: AppColors
                                                          .cardBackground,
                                                      child:
                                                          const CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                          color: AppColors
                                                              .cardBackground,
                                                          child: const Icon(
                                                            Icons.music_note,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                        ),
                                              )
                                            : Container(
                                                color: AppColors.cardBackground,
                                                child: const Icon(
                                                  Icons.music_note,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      log.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      log.artistName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () {
                                            final queue = logs
                                                .map(
                                                  (l) => AudioTrackModel(
                                                    id: l.id,
                                                    videoId: l.videoId,
                                                    title: l.title,
                                                    artistName: l.artistName,
                                                    albumName: l.albumName,
                                                    thumbnailUrl:
                                                        l.thumbnailUrl,
                                                    duration: l.duration,
                                                  ),
                                                )
                                                .toList();
                                            ref
                                                .read(
                                                  playerControllerProvider
                                                      .notifier,
                                                )
                                                .playQueue(
                                                  queue,
                                                  initialIndex: index,
                                                );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () async {
                                            final confirm =
                                                await showConfirmDeleteDialog(
                                                  context: context,
                                                  title:
                                                      'Remover do Histórico?',
                                                  message:
                                                      'Tem certeza que deseja remover "${log.title}" do histórico?',
                                                  confirmLabel: 'Remover',
                                                );
                                            if (confirm == true) {
                                              try {
                                                await ref
                                                    .read(
                                                      historyRepositoryProvider,
                                                    )
                                                    .deletePlayLog(
                                                      userId,
                                                      log.id,
                                                    );
                                                ref.invalidate(
                                                  recentHistoryProvider(userId),
                                                );
                                                ref.invalidate(
                                                  topTracksProvider(userId),
                                                );
                                                if (mounted) setState(() {});
                                              } catch (_) {}
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, _) => OfflineFallbackWidget(
                              onRetry: () =>
                                  ref.invalidate(recentHistoryProvider(userId)),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
