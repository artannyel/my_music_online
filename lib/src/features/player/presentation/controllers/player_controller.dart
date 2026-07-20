import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/app_audio_handler.dart';
import '../../data/services/audio_handler_provider.dart';
import '../../domain/models/player_state_model.dart';

/// Provider singleton para a instância do AudioPlayerService.
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Controller StateNotifier do Player de Áudio reativo em tempo real com Rádio Automix.
class PlayerController extends StateNotifier<PlayerStateModel> {
  final AudioPlayerService _service;
  final AppAudioHandler _audioHandler;
  final YTMusic _ytMusic = YTMusic();
  bool _isYtMusicInitialized = false;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  PlayerController(this._service, this._audioHandler) : super(const PlayerStateModel()) {
    _initSubscriptions();
  }

  void _updateNotification(AudioTrackModel track) {
    _audioHandler.updateMediaItem(MediaItem(
      id: track.videoId,
      title: track.title,
      artist: track.artistName,
      artUri: track.thumbnailUrl != null ? Uri.tryParse(track.thumbnailUrl!) : null,
      duration: state.duration,
    ));
  }

  void _initSubscriptions() {
    final player = _service.player;

    _playerStateSubscription = player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
      );

      if (processingState == ProcessingState.completed) {
        nextTrack(isAutoCompletion: true);
      }
    });

    _positionSubscription = player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durationSubscription = player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  final Set<String> _fetchedRadioVideoIds = {};

  /// Toca uma faixa específica com o modo Rádio Automix ativado (filas infinitas)
  Future<void> playTrackWithRadio(AudioTrackModel track) async {
    _fetchedRadioVideoIds.clear();

    state = state.copyWith(
      currentTrack: track,
      queue: [track],
      currentIndex: 0,
      isBuffering: true,
      position: Duration.zero,
      isRadioMode: true,
    );

    try {
      _updateNotification(track);
      // Dispara a busca das sugestões do Rádio em paralelo no segundo 0
      _fetchAndAppendUpNexts(track.videoId);
      await _service.playTrack(track);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playTrackWithRadio: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Toca uma faixa específica e limpa a fila atual (modo estático)
  Future<void> playTrack(AudioTrackModel track) async {
    state = state.copyWith(
      currentTrack: track,
      queue: [track],
      currentIndex: 0,
      isBuffering: true,
      position: Duration.zero,
      isRadioMode: false,
    );

    try {
      _updateNotification(track);
      await _service.playTrack(track);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playTrack: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Inicia a reprodução de uma lista/fila completa de faixas a partir de um índice
  Future<void> playQueue(List<AudioTrackModel> queue, {int initialIndex = 0}) async {
    if (queue.isEmpty) return;

    final targetIndex = initialIndex.clamp(0, queue.length - 1);
    final targetTrack = queue[targetIndex];

    state = state.copyWith(
      queue: queue,
      currentIndex: targetIndex,
      currentTrack: targetTrack,
      isBuffering: true,
      position: Duration.zero,
      isRadioMode: false,
    );

    try {
      _updateNotification(targetTrack);
      await _service.playTrack(targetTrack);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playQueue: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  Future<void>? _activeRadioFetch;

  /// Toca uma faixa selecionada da fila de reprodução mantendo o modo atual (ex: Rádio Automix)
  Future<void> playTrackFromQueueIndex(int index) async {
    if (state.queue.isEmpty) return;

    final targetIndex = index.clamp(0, state.queue.length - 1);
    final targetTrack = state.queue[targetIndex];

    state = state.copyWith(
      currentIndex: targetIndex,
      currentTrack: targetTrack,
      isBuffering: true,
      position: Duration.zero,
    );

    // Se estiver no modo Rádio e estiver nos últimos 3 elementos, busca mais faixas
    if (state.isRadioMode && targetIndex >= state.queue.length - 3) {
      _fetchAndAppendUpNexts(targetTrack.videoId);
    }

    try {
      _updateNotification(targetTrack);
      await _service.playTrack(targetTrack);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playTrackFromQueueIndex: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Busca em segundo plano o Rádio Automix (getUpNexts) e anexa à fila de reprodução
  Future<void> _fetchAndAppendUpNexts(String videoId) async {
    if (videoId.isEmpty || _fetchedRadioVideoIds.contains(videoId)) return;
    _fetchedRadioVideoIds.add(videoId);

    if (_activeRadioFetch != null) {
      await _activeRadioFetch;
    }

    final completer = Completer<void>();
    _activeRadioFetch = completer.future;

    try {
      if (!_isYtMusicInitialized) {
        await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
        _isYtMusicInitialized = true;
      }

      final upNexts = await _ytMusic.getUpNexts(videoId);

      final newTracks = upNexts.map((item) {
        return AudioTrackModel(
          id: item.videoId,
          videoId: item.videoId,
          title: item.title,
          artistName: item.artists.name,
          albumName: item.album?.name,
          thumbnailUrl: item.thumbnails.isNotEmpty ? item.thumbnails.last.url : null,
          duration: Duration(seconds: item.duration),
        );
      }).where((t) => !state.queue.any((qTrack) => qTrack.videoId == t.videoId)).toList();

      if (newTracks.isNotEmpty) {
        final updatedQueue = List<AudioTrackModel>.from(state.queue)..addAll(newTracks);
        state = state.copyWith(queue: updatedQueue);
      }
    } catch (e, st) {
      debugPrint('[PlayerController] Erro ao buscar Rádio Automix (getUpNexts): $e\n$st');
      _fetchedRadioVideoIds.remove(videoId);
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _activeRadioFetch = null;
    }
  }

  /// Alterna entre reproduzir e pausar a faixa atual
  Future<void> togglePlayPause() async {
    if (state.currentTrack == null) return;

    if (state.isPlaying) {
      await _service.pause();
    } else {
      await _service.play();
    }
  }

  /// Ajusta a posição de reprodução da faixa (Seek)
  Future<void> seek(Duration position) async {
    await _service.seek(position);
  }

  /// Avança para a próxima música da fila
  Future<void> nextTrack({bool isAutoCompletion = false}) async {
    if (state.queue.isEmpty) return;

    if (isAutoCompletion && state.repeatMode == RepeatMode.one && state.currentTrack != null) {
      await seek(Duration.zero);
      await _service.play();
      return;
    }

    int nextIndex = state.currentIndex + 1;

    // Se estiver no modo Rádio Automix
    if (state.isRadioMode) {
      // Se chegarmos perto ou no final da fila, busca mais faixas imediatamente!
      if (nextIndex >= state.queue.length - 2) {
        final lastVideoId = state.queue.last.videoId;
        if (nextIndex >= state.queue.length) {
          // Se o usuário clicou Próximo e já estava na ÚLTIMA música da fila:
          // Aguarda o término da busca para expandir a fila antes de prosseguir!
          state = state.copyWith(isBuffering: true);
          await _fetchAndAppendUpNexts(lastVideoId);
        } else {
          // Se ainda restam 1 ou 2 faixas, busca assincronamente em segundo plano
          _fetchAndAppendUpNexts(lastVideoId);
        }
      }
    }

    if (state.isShuffleEnabled && state.queue.length > 1) {
      final random = Random();
      do {
        nextIndex = random.nextInt(state.queue.length);
      } while (nextIndex == state.currentIndex);
    } else {
      if (nextIndex >= state.queue.length) {
        if (state.repeatMode == RepeatMode.all) {
          nextIndex = 0;
        } else {
          await _service.pause();
          return;
        }
      }
    }

    final nextTrackItem = state.queue[nextIndex];
    state = state.copyWith(
      currentIndex: nextIndex,
      currentTrack: nextTrackItem,
      isBuffering: true,
      position: Duration.zero,
    );

    try {
      _updateNotification(nextTrackItem);
      await _service.playTrack(nextTrackItem);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro em nextTrack: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Volta para a música anterior da fila ou reinicia a atual
  Future<void> previousTrack() async {
    if (state.queue.isEmpty) return;

    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex;
    if (state.isShuffleEnabled && state.queue.length > 1) {
      final random = Random();
      do {
        prevIndex = random.nextInt(state.queue.length);
      } while (prevIndex == state.currentIndex);
    } else {
      prevIndex = state.currentIndex - 1;
      if (prevIndex < 0) {
        prevIndex = state.queue.length - 1;
      }
    }

    final prevTrackItem = state.queue[prevIndex];
    state = state.copyWith(
      currentIndex: prevIndex,
      currentTrack: prevTrackItem,
      isBuffering: true,
      position: Duration.zero,
    );

    try {
      _updateNotification(prevTrackItem);
      await _service.playTrack(prevTrackItem);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro em previousTrack: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Alterna entre os modos de repetição (desligado -> faixa atual -> lista inteira)
  Future<void> toggleRepeatMode() async {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };

    await _service.setRepeatMode(nextMode);
    state = state.copyWith(repeatMode: nextMode);
  }

  /// Alterna o modo aleatório (Shuffle)
  Future<void> toggleShuffle() async {
    final nextShuffle = !state.isShuffleEnabled;
    await _service.setShuffle(nextShuffle);
    state = state.copyWith(isShuffleEnabled: nextShuffle);
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}

/// Provider do PlayerController em Riverpod.
final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerStateModel>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  final handler = ref.watch(audioHandlerProvider);
  return PlayerController(service, handler);
});
