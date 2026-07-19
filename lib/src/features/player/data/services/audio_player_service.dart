// ignore_for_file: experimental_member_use

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/player_state_model.dart';

/// Fonte de áudio customizada que gerencia requisições de intervalo (Range HTTP Headers)
/// transmitindo bytes diretamente ao ExoPlayer sem erros de timeout, socket closed ou HTTP 403.
class YoutubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode ytExplode;
  final http.Client _client = http.Client();

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

    // Prioriza container MP4 para compatibilidade total com ExoPlayer no Android
    final mp4Streams = audioStreams.where((s) => s.container.name == 'mp4').toList();
    final audioStreamInfo = mp4Streams.isNotEmpty
        ? mp4Streams.withHighestBitrate()
        : audioStreams.withHighestBitrate();

    final totalBytes = audioStreamInfo.size.totalBytes;
    final rangeStart = start ?? 0;
    final rangeEnd = end ?? (totalBytes - 1);

    // Faz a requisição HTTP Range com o User-Agent correto via cliente Dart
    final request = http.Request('GET', audioStreamInfo.url);
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    request.headers['Range'] = 'bytes=$rangeStart-$rangeEnd';

    final response = await _client.send(request);

    final contentType = audioStreamInfo.container.name == 'mp4'
        ? 'audio/mp4'
        : 'audio/webm';

    return StreamAudioResponse(
      sourceLength: totalBytes,
      contentLength: response.contentLength ?? (rangeEnd - rangeStart + 1),
      offset: rangeStart,
      stream: response.stream,
      contentType: contentType,
    );
  }
}

/// Serviço encapsulado do Player de Áudio que gerencia a reprodução usando just_audio
/// e a transmissão garantida de faixas via YoutubeAudioSource com suporte a Range requests.
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
