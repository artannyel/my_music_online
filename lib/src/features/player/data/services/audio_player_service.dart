// ignore_for_file: experimental_member_use

import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/player_state_model.dart';

/// Fonte de áudio customizada que utiliza o cliente Dart do YoutubeExplode para
/// transmitir bytes diretamente ao just_audio/ExoPlayer sem erros HTTP 403 Forbidden.
class YoutubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode ytExplode;

  YoutubeAudioSource({
    required this.videoId,
    required this.ytExplode,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final manifest = await ytExplode.videos.streamsClient.getManifest(videoId);
    final audioStreams = manifest.audioOnly;

    if (audioStreams.isEmpty) {
      throw Exception('Nenhum stream de áudio disponível para o videoId $videoId');
    }

    // Prioriza container MP4 para compatibilidade com o ExoPlayer
    final mp4Streams = audioStreams.where((s) => s.container.name == 'mp4').toList();
    final audioStreamInfo = mp4Streams.isNotEmpty
        ? mp4Streams.withHighestBitrate()
        : audioStreams.withHighestBitrate();

    final totalBytes = audioStreamInfo.size.totalBytes;
    final stream = ytExplode.videos.streamsClient.get(audioStreamInfo);

    final contentType = audioStreamInfo.container.name == 'mp4'
        ? 'audio/mp4'
        : 'audio/webm';

    return StreamAudioResponse(
      sourceLength: totalBytes,
      contentLength: (end ?? totalBytes) - (start ?? 0),
      offset: start ?? 0,
      stream: stream,
      contentType: contentType,
    );
  }
}

/// Serviço encapsulado do Player de Áudio que gerencia a reprodução usando just_audio
/// e a transmissão garantida de faixas via YoutubeAudioSource.
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  final YoutubeExplode _ytExplode;

  AudioPlayerService({
    AudioPlayer? audioPlayer,
    YoutubeExplode? ytExplode,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _ytExplode = ytExplode ?? YoutubeExplode();

  AudioPlayer get player => _audioPlayer;

  /// Inicia a reprodução de uma nova faixa via YoutubeAudioSource
  Future<void> playTrack(AudioTrackModel track) async {
    try {
      final audioSource = YoutubeAudioSource(
        videoId: track.videoId,
        ytExplode: _ytExplode,
      );

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Falha ao reproduzir a faixa ${track.title}: $e');
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
