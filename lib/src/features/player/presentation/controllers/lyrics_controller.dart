import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lyrics_model.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../data/repositories/ytmusic_lyrics_repository.dart';
import 'player_controller.dart';

/// Provider do repositório de letras.
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  return YtmusicLyricsRepository();
});

/// Notifier responsável por buscar e gerenciar o estado das letras da música em reprodução.
class LyricsNotifier extends StateNotifier<AsyncValue<LyricsModel?>> {
  final LyricsRepository _repository;
  final Ref _ref;
  String? _currentVideoId;

  LyricsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null)) {
    _listenToCurrentTrack();
  }

  void _listenToCurrentTrack() {
    _ref.listen(playerControllerProvider.select((s) => s.currentTrack?.videoId), (previous, next) {
      if (next != _currentVideoId) {
        _currentVideoId = next;
        fetchLyrics(next);
      }
    });

    final initialTrack = _ref.read(playerControllerProvider).currentTrack;
    if (initialTrack != null && initialTrack.videoId.isNotEmpty) {
      _currentVideoId = initialTrack.videoId;
      fetchLyrics(initialTrack.videoId);
    }
  }

  /// Busca as letras para o [videoId] fornecido.
  Future<void> fetchLyrics(String? videoId) async {
    if (videoId == null || videoId.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final lyrics = await _repository.getLyrics(videoId);
      // Evita atualizar caso a faixa tenha mudado durante o await
      if (_currentVideoId == videoId) {
        state = AsyncValue.data(lyrics);
      }
    } catch (e, st) {
      if (_currentVideoId == videoId) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  String? get currentVideoId => _currentVideoId;

  /// Recarrega as letras da faixa atual (por exemplo, após falha de conexão).
  Future<void> retryCurrentTrack() async {
    final trackId = _currentVideoId ?? _ref.read(playerControllerProvider).currentTrack?.videoId;
    if (trackId != null && trackId.isNotEmpty) {
      await fetchLyrics(trackId);
    }
  }

  /// Pula a reprodução para o início de uma linha sincronizada específica.
  void seekToLine(LyricLineModel line) {
    _ref.read(playerControllerProvider.notifier).seek(line.startTime);
  }
}

/// Provider do gerenciador de estado de letras.
final lyricsProvider =
    StateNotifierProvider<LyricsNotifier, AsyncValue<LyricsModel?>>((ref) {
  final repo = ref.watch(lyricsRepositoryProvider);
  return LyricsNotifier(repo, ref);
});

/// Provider que calcula o índice da linha de letra atualmente ativa com base na posição da música.
/// Retorna `-1` se nenhuma linha coincidir ou se não houver letras sincronizadas.
final currentLyricIndexProvider = Provider<int>((ref) {
  final lyricsAsync = ref.watch(lyricsProvider);
  final position = ref.watch(playerControllerProvider.select((s) => s.position));

  final lyrics = lyricsAsync.valueOrNull;
  if (lyrics == null || !lyrics.hasTimedLyrics || lyrics.timedLines.isEmpty) {
    return -1;
  }

  final lines = lyrics.timedLines;

  // Busca binária ou linear pela linha correspondente ao tempo atual
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].isActiveAt(position)) {
      return i;
    }
  }

  // Se o tempo estiver entre versos, retorna o último verso que já começou
  int lastStartedIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (position >= lines[i].startTime) {
      lastStartedIndex = i;
    } else {
      break;
    }
  }

  return lastStartedIndex;
});
