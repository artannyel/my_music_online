import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/player_state_model.dart';

/// Serviço encapsulado do Player de Áudio que utiliza YoutubeExplode para
/// extração de URLs de stream e just_audio com cabeçalhos HTTP adequados para o ExoPlayer (Android).
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  final YoutubeExplode _ytExplode;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  AudioPlayerService({
    AudioPlayer? audioPlayer,
    YoutubeExplode? ytExplode,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _ytExplode = ytExplode ?? YoutubeExplode();

  AudioPlayer get player => _audioPlayer;

  /// Resolve a lista de URLs de stream de áudio (priorizando MP4 e maior bitrate)
  Future<List<String>> resolveAudioUrls(String videoId) async {
    final urls = <String>[];
    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isNotEmpty) {
        // Prioriza streams em container MP4 (compatibilidade total com ExoPlayer)
        final mp4Streams = audioStreams.where((s) => s.container.name == 'mp4').toList();
        if (mp4Streams.isNotEmpty) {
          urls.add(mp4Streams.withHighestBitrate().url.toString());
        }

        // Adiciona a de maior bitrate no geral (WebM/Opus)
        final highestBitrateUrl = audioStreams.withHighestBitrate().url.toString();
        if (!urls.contains(highestBitrateUrl)) {
          urls.add(highestBitrateUrl);
        }

        // Adiciona os demais streams como fallback
        for (final stream in audioStreams) {
          final urlStr = stream.url.toString();
          if (!urls.contains(urlStr)) {
            urls.add(urlStr);
          }
        }
      }
    } catch (_) {}
    return urls;
  }

  /// Inicia a reprodução de uma nova faixa no just_audio/ExoPlayer com User-Agent
  Future<void> playTrack(AudioTrackModel track) async {
    List<String> streamUrls = [];

    if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
      streamUrls.add(track.audioUrl!);
    } else {
      streamUrls = await resolveAudioUrls(track.videoId);
    }

    if (streamUrls.isEmpty) {
      throw Exception('Não foi possível obter a URL de áudio para ${track.title}');
    }

    // Tenta reproduzir as URLs até uma ter sucesso
    Object? lastError;
    for (final url in streamUrls) {
      try {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: _defaultHeaders,
          ),
        );
        await _audioPlayer.play();
        return; // Reprodução iniciada com sucesso!
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Falha ao tocar áudio para ${track.title}: $lastError');
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
