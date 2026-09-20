import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/lyrics_controller.dart';

/// Widget de exibição de letras de música, com suporte a letras sincronizadas (com scroll automático e seek)
/// e fallback para letras estáticas ou estado indisponível.
class LyricsViewWidget extends ConsumerStatefulWidget {
  const LyricsViewWidget({super.key});

  @override
  ConsumerState<LyricsViewWidget> createState() => _LyricsViewWidgetState();
}

class _LyricsViewWidgetState extends ConsumerState<LyricsViewWidget> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;
  bool _userIsScrolling = false;

  // 1. GlobalKey por linha (no State do widget):
  List<GlobalKey> _lineKeys = [];
  String? _lastLoadedVideoId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (_userIsScrolling || !_scrollController.hasClients || index < 0) return;
    if (index >= _lineKeys.length) return;

    final context = _lineKeys[index].currentContext;
    if (context == null) return;

    // Centraliza de fato (leva em conta a linha REAL de 1..n)
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.5, // 0.5 = centro do viewport
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsProvider);
    final activeIndex = ref.watch(currentLyricIndexProvider);

    // Quando o verso ativo muda, aciona rolagem automática se for sincronizado
    if (activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;
      final lyrics = lyricsAsync.valueOrNull;
      if (lyrics != null && lyrics.hasTimedLyrics) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveLine(activeIndex);
        });
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: lyricsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
              SizedBox(height: 12),
              Text(
                'Buscando letra...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lyrics_outlined,
                color: AppColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 8),
              const Text(
                'Letra indisponível para esta música',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  ref.read(lyricsProvider.notifier).retryCurrentTrack();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (lyrics) {
          if (lyrics == null || !lyrics.hasContent) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lyrics_outlined,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nenhuma letra encontrada para esta música',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Caso 1: Letras Sincronizadas
          if (lyrics.hasTimedLyrics && lyrics.timedLines.isNotEmpty) {
            if (_lastLoadedVideoId != lyrics.videoId ||
                _lineKeys.length < lyrics.timedLines.length) {
              _lastLoadedVideoId = lyrics.videoId;
              _lineKeys = List.generate(
                lyrics.timedLines.length,
                (_) => GlobalKey(debugLabel: 'line'),
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _userIsScrolling = true;
                } else if (notification is ScrollEndNotification) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      _userIsScrolling = false;
                    }
                  });
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount:
                    lyrics.timedLines.length +
                    (lyrics.sourceMessage != null ? 1 : 0),
                scrollCacheExtent: ScrollCacheExtent.viewport(20),
                itemBuilder: (context, index) {
                  if (index == lyrics.timedLines.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          lyrics.sourceMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    );
                  }

                  final line = lyrics.timedLines[index];
                  final isActive = index == activeIndex;
                  final isPast = index < activeIndex;

                  return KeyedSubtree(
                    key: _lineKeys.length > index ? _lineKeys[index] : null,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(lyricsProvider.notifier).seekToLine(line);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isActive ? 20 : 16,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.primary
                                : (isPast
                                      ? AppColors.textMuted.withValues(
                                          alpha: 0.6,
                                        )
                                      : AppColors.textSecondary),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          // Caso 2: Letras Estáticas (Plain Lyrics)
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    lyrics.plainLyrics ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (lyrics.sourceMessage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      lyrics.sourceMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
