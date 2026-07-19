// ignore_for_file: experimental_member_use

import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/models/player_state_model.dart';

/// Fonte de áudio customizada que transmite os bytes do stream do YouTube via Range HTTP.
class YoutubeAudioSource extends StreamAudioSource {
  final AudioOnlyStreamInfo streamInfo;
  final http.Client _client = http.Client();

  YoutubeAudioSource(this.streamInfo);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final totalBytes = streamInfo.size.totalBytes;
    final rangeStart = start ?? 0;
    final rangeEnd = end ?? (totalBytes - 1);

    debugPrint('[YoutubeAudioSource] Chunk request: range=$rangeStart-$rangeEnd (total=$totalBytes)');

    final request = http.Request('GET', streamInfo.url);
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    request.headers['Range'] = 'bytes=$rangeStart-$rangeEnd';

    try {
      final response = await _client.send(request);
      debugPrint('[YoutubeAudioSource] Chunk response status: ${response.statusCode}');

      final contentType = streamInfo.container.name == 'mp4'
          ? 'audio/mp4'
          : 'audio/webm';

      return StreamAudioResponse(
        sourceLength: totalBytes,
        contentLength: response.contentLength ?? (rangeEnd - rangeStart + 1),
        offset: rangeStart,
        stream: response.stream,
        contentType: contentType,
      );
    } catch (e, st) {
      debugPrint('[YoutubeAudioSource] Erro no chunk request: $e\n$st');
      rethrow;
    }
  }
}

/// Serviço do Player de Áudio com logs de diagnóstico detalhados para diagnóstico de qualquer falha.
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

  /// Método de fallback via YTMusic API para obter a URL do stream de áudio
  Future<String?> _resolveFallbackAudioUrl(String videoId) async {
    try {
      debugPrint('[AudioPlayerService] Tentando fallback via YTMusic API para $videoId...');
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
            debugPrint('[AudioPlayerService] Fallback encontrou URL válida via YTMusic.');
            return url;
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioPlayerService] Erro no fallback YTMusic: $e');
    }
    return null;
  }

  /// Inicia a reprodução de uma nova faixa no just_audio
  Future<void> playTrack(AudioTrackModel track) async {
    debugPrint('[AudioPlayerService] --- Iniciando playTrack: "${track.title}" (videoId: ${track.videoId}) ---');

    // 1. Tenta obter o manifesto do YoutubeExplode
    try {
      debugPrint('[AudioPlayerService] Requisitando manifesto YoutubeExplode para ${track.videoId}...');
      final manifest = await _ytExplode.videos.streamsClient.getManifest(track.videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isNotEmpty) {
        final mp4Streams = audioStreams.where((s) => s.container.name == 'mp4').toList();
        final streamInfo = mp4Streams.isNotEmpty
            ? mp4Streams.withHighestBitrate()
            : audioStreams.withHighestBitrate();

        debugPrint('[AudioPlayerService] StreamInfo obtido: container=${streamInfo.container.name}, bitrate=${streamInfo.bitrate}');
        final audioSource = YoutubeAudioSource(streamInfo);
        
        await _audioPlayer.setAudioSource(audioSource);
        debugPrint('[AudioPlayerService] AudioSource configurado com sucesso. Chamando play()...');
        await _audioPlayer.play();
        debugPrint('[AudioPlayerService] Reprodução iniciada com sucesso via YoutubeAudioSource!');
        return;
      }
    } catch (e, st) {
      debugPrint('[AudioPlayerService] Falha na estratégia YoutubeExplode: $e\n$st');
    }

    // 2. Fallback via YTMusic API e AudioSource.uri
    debugPrint('[AudioPlayerService] Tentando estratégia de fallback para ${track.title}...');
    final fallbackUrl = await _resolveFallbackAudioUrl(track.videoId);
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      try {
        debugPrint('[AudioPlayerService] Configurando AudioSource.uri com fallback URL...');
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(fallbackUrl),
            headers: _defaultHeaders,
          ),
        );
        await _audioPlayer.play();
        debugPrint('[AudioPlayerService] Reprodução iniciada com sucesso via Fallback URI!');
        return;
      } catch (e, st) {
        debugPrint('[AudioPlayerService] Erro ao tocar via Fallback URI: $e\n$st');
      }
    }

    throw Exception('Não foi possível carregar a faixa ${track.title}');
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
