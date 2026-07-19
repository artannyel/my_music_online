import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/player_state_model.dart';

/// Serviço encapsulado do Player de Áudio que utiliza YoutubeExplode para
/// extração garantida de URLs de stream e just_audio / ExoPlayer para reprodução.
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  final YoutubeExplode _ytExplode;

  AudioPlayerService({
    AudioPlayer? audioPlayer,
    YoutubeExplode? ytExplode,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _ytExplode = ytExplode ?? YoutubeExplode();

  AudioPlayer get player => _audioPlayer;

  /// Resolve a URL de stream de áudio direta de alta qualidade de uma faixa do YouTube
  Future<String?> resolveAudioUrl(String videoId) async {
    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isNotEmpty) {
        final bestAudio = audioStreams.withHighestBitrate();
        return bestAudio.url.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Inicia a reprodução de uma nova faixa ou retoma a atual
  Future<void> playTrack(AudioTrackModel track) async {
    String? streamUrl = track.audioUrl;

    if (streamUrl == null || streamUrl.isEmpty) {
      streamUrl = await resolveAudioUrl(track.videoId);
    }

    if (streamUrl != null && streamUrl.isNotEmpty) {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
        ),
      );
      await _audioPlayer.play();
    } else {
      throw Exception('Não foi possível obter a URL de áudio para ${track.title}');
    }
  }

  Future<void> play() async => await _audioPlayer.play();
  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> stop() async => await _audioPlayer.stop();
  Future<void> seek(Duration position) async => await _audioPlayer.seek(position);

  Future<void> setRepeatMode(RepeatMode mode) async {
    switch (mode) {
      case RepeatMode.off:
        await _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.one:
        await _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.all:
        await _audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }

  Future<void> setShuffle(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  void dispose() {
    _ytExplode.close();
    _audioPlayer.dispose();
  }
}
