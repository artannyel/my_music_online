import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:my_music_online/src/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/app_audio_handler.dart';
import '../../data/services/audio_handler_provider.dart';
import '../../domain/models/player_state_model.dart';
import '../../../playlist/domain/repositories/playlist_repository.dart';

const _prefsKey = 'player_session';

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
  final PlaylistRepository _playlistRepository;
  final YTMusic _ytMusic = YTMusic();
  bool _isYtMusicInitialized = false;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  PlayerController(this._service, this._audioHandler, this._playlistRepository) : super(const PlayerStateModel()) {
    _initSubscriptions();
    _audioHandler.onSkipToNext = () => nextTrack();
    _audioHandler.onSkipToPrevious = () => previousTrack();
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

  /// Restaura a sessão anterior do player a partir do SharedPreferences.
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == null || saved.isEmpty) return;

      final data = json.decode(saved) as Map<String, dynamic>;
      final queueJson = data['queue'] as List<dynamic>?;
      if (queueJson == null || queueJson.isEmpty) return;

      final restoredQueue = queueJson
          .map((e) => AudioTrackModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final savedIndex = data['currentIndex'] as int? ?? 0;
      final clampedIndex = savedIndex.clamp(0, restoredQueue.length - 1);

      state = state.copyWith(
        queue: restoredQueue,
        currentIndex: clampedIndex,
        currentTrack: restoredQueue[clampedIndex],
        isPlaying: false,
        isBuffering: false,
      );

      // Pré-carrega a faixa restaurada sem iniciar a reprodução
      unawaited(_service.setTrack(restoredQueue[clampedIndex]));
    } catch (e) {
      debugPrint('[PlayerController] Erro ao restaurar sessão: $e');
    }
  }

  /// Salva a fila e o índice atual no SharedPreferences.
  void _saveSession() {
    try {
      final data = json.encode({
        'queue': state.queue.map((t) => t.toJson()).toList(),
        'currentIndex': state.currentIndex,
      });
      SharedPreferences.getInstance().then((prefs) => prefs.setString(_prefsKey, data));
    } catch (e) {
      debugPrint('[PlayerController] Erro ao salvar sessão: $e');
    }
  }

  // ─── Queue manipulation ──────────────────────────────────────

  /// Adiciona uma faixa ao final da fila atual.
  void addToQueue(AudioTrackModel track) {
    if (state.queue.any((t) => t.id == track.id)) return;
    final updated = List<AudioTrackModel>.from(state.queue)..add(track);
    state = state.copyWith(queue: updated);
    _saveSession();
  }

  /// Insere uma faixa logo após a faixa que está tocando no momento.
  void insertNext(AudioTrackModel track) {
    if (state.queue.any((t) => t.id == track.id)) return;
    final insertAt = state.currentIndex + 1;
    final updated = List<AudioTrackModel>.from(state.queue);
    updated.insert(insertAt.clamp(0, updated.length), track);
    state = state.copyWith(queue: updated);
    _saveSession();
  }

  /// Remove uma faixa da fila pelo índice.
  /// Não permite remover a faixa que está tocando no momento.
  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    if (index == state.currentIndex) return;

    final updated = List<AudioTrackModel>.from(state.queue)..removeAt(index);
    final newIndex = index < state.currentIndex ? state.currentIndex - 1 : state.currentIndex;
    state = state.copyWith(queue: updated, currentIndex: newIndex);
    _saveSession();
  }

  /// Reordena a fila movendo um item de [oldIndex] para [newIndex].
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final updated = List<AudioTrackModel>.from(state.queue);
    final track = updated.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    updated.insert(insertAt.clamp(0, updated.length), track);

    int newCurrentIndex = state.currentIndex;
    if (oldIndex == state.currentIndex) {
      newCurrentIndex = insertAt;
    } else if (oldIndex < state.currentIndex && newIndex > state.currentIndex) {
      newCurrentIndex = state.currentIndex - 1;
    } else if (oldIndex > state.currentIndex && newIndex < state.currentIndex) {
      newCurrentIndex = state.currentIndex + 1;
    }

    state = state.copyWith(queue: updated, currentIndex: newCurrentIndex);
    _saveSession();
  }

  /// Limpa toda a fila de reprodução.
  void clearQueue() {
    state = state.copyWith(
      queue: [],
      currentIndex: -1,
      currentTrack: null,
      isPlaying: false,
      isRadioMode: false,
      clearMix: true,
    );
    _saveSession();
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
      clearMix: true,
    );
    _saveSession();

    try {
      _updateNotification(track);
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
      clearMix: true,
    );
    _saveSession();

    try {
      _updateNotification(track);
      await _service.playTrack(track);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playTrack: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Inicia a reprodução de uma lista/fila completa de faixas a partir de um índice
  Future<void> playQueue(List<AudioTrackModel> queue, {int initialIndex = 0, bool isRadioMode = false, String? mixUrl, String? mixNextPageToken}) async {
    if (queue.isEmpty) return;

    final targetIndex = initialIndex.clamp(0, queue.length - 1);
    final targetTrack = queue[targetIndex];

    state = state.copyWith(
      queue: queue,
      currentIndex: targetIndex,
      currentTrack: targetTrack,
      isBuffering: true,
      position: Duration.zero,
      isRadioMode: isRadioMode,
      mixUrl: mixUrl,
      mixNextPageToken: mixNextPageToken,
      clearMix: mixUrl == null,
    );
    _saveSession();

    try {
      _updateNotification(targetTrack);
      await _service.playTrack(targetTrack);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro capturado em playQueue: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  Future<void>? _activeRadioFetch;

  /// Toca uma faixa selecionada da fila de reprodução mantendo o modo atual
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
    _saveSession();

    if (state.mixUrl != null && state.mixNextPageToken != null && targetIndex >= state.queue.length - 3) {
      _fetchAndAppendMixNextPage();
    } else if (state.isRadioMode && state.mixUrl == null && targetIndex >= state.queue.length - 3) {
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

  bool _isFetchingMix = false;

  Future<void> _fetchAndAppendMixNextPage() async {
    final url = state.mixUrl;
    final token = state.mixNextPageToken;
    if (url == null || token == null || _isFetchingMix) return;

    _isFetchingMix = true;

    try {
      final (tracks: newTracks, nextPageUrl: newToken) = await _playlistRepository.getMixNextPage(url, token);

      if (newTracks.isNotEmpty) {
        final audioTracks = newTracks.map((t) => AudioTrackModel(
          id: t.id,
          videoId: t.videoId ?? t.id,
          title: t.title,
          artistName: t.artistName,
          thumbnailUrl: t.thumbnailUrl,
          duration: t.duration,
        )).where((t) => !state.queue.any((qTrack) => qTrack.videoId == t.videoId)).toList();

        if (audioTracks.isNotEmpty) {
          final updatedQueue = List<AudioTrackModel>.from(state.queue)..addAll(audioTracks);
          state = state.copyWith(queue: updatedQueue, mixNextPageToken: newToken);
          _saveSession();
        } else {
          state = state.copyWith(mixNextPageToken: newToken);
        }
      } else {
        state = state.copyWith(mixNextPageToken: newToken);
      }
    } catch (e, st) {
      debugPrint('[PlayerController] Erro ao buscar próxima página do Mix: $e\n$st');
    } finally {
      _isFetchingMix = false;
    }
  }

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
        _saveSession();
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

  Future<void> togglePlayPause() async {
    if (state.currentTrack == null) return;

    if (state.isPlaying) {
      await _service.pause();
    } else {
      await _service.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _service.seek(position);
  }

  Future<void> nextTrack({bool isAutoCompletion = false}) async {
    if (state.queue.isEmpty) return;

    if (isAutoCompletion && state.repeatMode == RepeatMode.one && state.currentTrack != null) {
      await seek(Duration.zero);
      await _service.play();
      return;
    }

    int nextIndex = state.currentIndex + 1;

    if (state.mixUrl != null && state.mixNextPageToken != null) {
      if (nextIndex >= state.queue.length - 2) {
        if (nextIndex >= state.queue.length) {
          state = state.copyWith(isBuffering: true);
          await _fetchAndAppendMixNextPage();
        } else {
          _fetchAndAppendMixNextPage();
        }
      }
    } else if (state.isRadioMode && state.mixUrl == null) {
      if (nextIndex >= state.queue.length - 2) {
        final lastVideoId = state.queue.last.videoId;
        if (nextIndex >= state.queue.length) {
          state = state.copyWith(isBuffering: true);
          await _fetchAndAppendUpNexts(lastVideoId);
        } else {
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
    _saveSession();

    try {
      _updateNotification(nextTrackItem);
      await _service.playTrack(nextTrackItem);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro em nextTrack: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

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
    _saveSession();

    try {
      _updateNotification(prevTrackItem);
      await _service.playTrack(prevTrackItem);
    } catch (e, st) {
      debugPrint('[PlayerController] Erro em previousTrack: $e\n$st');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  Future<void> toggleRepeatMode() async {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };

    await _service.setRepeatMode(nextMode);
    state = state.copyWith(repeatMode: nextMode);
  }

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

final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerStateModel>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  final handler = ref.watch(audioHandlerProvider);
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  final controller = PlayerController(service, handler, playlistRepo);
  controller.restoreSession();
  return controller;
});
