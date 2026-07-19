import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/audio_player_service.dart';
import '../../domain/models/player_state_model.dart';

/// Provider singleton para a instância do AudioPlayerService.
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Controller StateNotifier do Player de Áudio reativo em tempo real.
class PlayerController extends StateNotifier<PlayerStateModel> {
  final AudioPlayerService _service;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  PlayerController(this._service) : super(const PlayerStateModel()) {
    _initSubscriptions();
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
        nextTrack();
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

  /// Toca uma faixa específica e limpa a fila atual
  Future<void> playTrack(AudioTrackModel track) async {
    state = state.copyWith(
      currentTrack: track,
      queue: [track],
      currentIndex: 0,
      isBuffering: true,
      position: Duration.zero,
    );

    try {
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
    );

    try {
      await _service.playTrack(targetTrack);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playQueue: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
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
  Future<void> nextTrack() async {
    if (state.queue.isEmpty) return;

    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        await _service.pause();
        return;
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

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = state.queue.length - 1;
    }

    final prevTrackItem = state.queue[prevIndex];
    state = state.copyWith(
      currentIndex: prevIndex,
      currentTrack: prevTrackItem,
      isBuffering: true,
      position: Duration.zero,
    );

    try {
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
  return PlayerController(service);
});
