// ignore_for_file: experimental_member_use

import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
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
/// e a transmissão garantida de faixas com fallback de resiliência.
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  final YoutubeExplode _ytExplode;
  final YTMusic _ytMusic;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  AudioPlayerService({
    AudioPlayer? audioPlayer,
    YoutubeExplode? ytExplode,
    YTMusic? ytMusic,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _ytExplode = ytExplode ?? YoutubeExplode(),
        _ytMusic = ytMusic ?? YTMusic();

  AudioPlayer get player => _audioPlayer;

  /// Método de fallback via YTMusic API para obter a URL do stream de áudio caso o YoutubeExplode atinja limite
  Future<String?> _resolveFallbackAudioUrl(String videoId) async {
    try {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      final songFull = await _ytMusic.getSong(videoId);

      final allFormats = [
        ...songFull.adaptiveFormats,
        ...songFull.formats,
      ];

      final audioFormats = allFormats.where((f) {
        final mime = f['mimeType']?.toString().toLowerCase() ?? '';
        return mime.contains('audio');
      }).toList();

      if (audioFormats.isNotEmpty) {
        audioFormats.sort((a, b) {
          final bitrateA = (a['bitrate'] as num?) ?? 0;
          final bitrateB = (b['bitrate'] as num?) ?? 0;
          return bitrateB.compareTo(bitrateA);
        });

        for (final format in audioFormats) {
          String? url = format['url']?.toString();
          if (url == null || url.isEmpty) {
            final cipher = format['signatureCipher']?.toString() ?? format['cipher']?.toString();
            if (cipher != null && cipher.isNotEmpty) {
              final queryParams = Uri.splitQueryString(cipher);
              url = queryParams['url'];
            }
          }
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Inicia a reprodução de uma nova faixa com resiliência e fallback
  Future<void> playTrack(AudioTrackModel track) async {
    // 1. Tenta reproduzir via YoutubeAudioSource (StreamAudioSource nativo)
    try {
      final audioSource = YoutubeAudioSource(
        videoId: track.videoId,
        ytExplode: _ytExplode,
      );

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
      return;
    } catch (e) {
      // Se houver erro ou rate limit no YoutubeExplode, cai no fallback de URL direta
    }

    // 2. Fallback: Obtém URL via YTMusic e toca via AudioSource.uri com headers
    final fallbackUrl = await _resolveFallbackAudioUrl(track.videoId);
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(fallbackUrl),
          headers: _defaultHeaders,
        ),
      );
      await _audioPlayer.play();
    } else {
      throw Exception('Não foi possível carregar a faixa ${track.title}');
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
