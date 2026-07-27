import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_music_online/src/features/player/data/services/audio_player_service.dart';

/// Classe responsável por integrar o controle de mídia (Play/Pause/Next)
/// na tela de bloqueio e na barra de notificações nativa.
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayerService _audioService;
  
  // Callbacks para o PlayerController gerenciar a fila
  void Function()? onSkipToNext;
  void Function()? onSkipToPrevious;

  AppAudioHandler(this._audioService) {
    _initStreams();
  }

  void _initStreams() {
    _audioService.player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isCompleted = processingState == ProcessingState.completed;
      final isBuffering = processingState == ProcessingState.buffering || 
                          processingState == ProcessingState.loading;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.play,
          MediaAction.pause,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: isCompleted
            ? AudioProcessingState.completed
            : isBuffering
                ? AudioProcessingState.buffering
                : AudioProcessingState.ready,
        playing: isPlaying,
      ));
    });

    _audioService.player.positionStream.listen((position) {
       playbackState.add(playbackState.value.copyWith(
         updatePosition: position,
       ));
    });

    _audioService.player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        if (mediaItem.value!.duration != duration) {
          mediaItem.add(mediaItem.value!.copyWith(
            duration: duration,
          ));
        }
      }
    });
  }

  // Atualiza os dados da música atual para aparecer na tela de bloqueio
  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
  }

  @override
  Future<void> play() async => await _audioService.play();

  @override
  Future<void> pause() async => await _audioService.pause();

  @override
  Future<void> stop() async => await _audioService.stop();

  @override
  Future<void> seek(Duration position) async => await _audioService.seek(position);

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) onSkipToNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) onSkipToPrevious!();
  }
}
