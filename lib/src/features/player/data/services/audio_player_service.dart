import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yt_extractor/yt_extractor.dart';
import '../../domain/models/player_state_model.dart';

/// Serviço do Player de Áudio focado no just_audio e AudiosResolver
class AudioPlayerService {
  final AudioPlayer _audioPlayer;

  AudioPlayerService({
    AudioPlayer? audioPlayer,
  }) : _audioPlayer = audioPlayer ?? AudioPlayer();

  AudioPlayer get player => _audioPlayer;

  /// Inicia a reprodução de uma nova faixa no just_audio
  Future<void> playTrack(AudioTrackModel track) async {
    debugPrint('[AudioPlayerService] --- Iniciando playTrack: "${track.title}" (videoId: ${track.videoId}) ---');

    try {
      await setTrack(track);
      debugPrint('[AudioPlayerService] AudioSource configurado com sucesso. Chamando play()...');
      await _audioPlayer.play();
      debugPrint('[AudioPlayerService] Reprodução iniciada com sucesso via AudiosResolver!');
    } catch (e, st) {
      debugPrint('[AudioPlayerService] Falha no AudiosResolver: $e\n$st');
      throw Exception('Não foi possível carregar a faixa ${track.title}');
    }
  }

  /// Prepara o áudio carregando a URL sem iniciar a reprodução.
  Future<void> setTrack(AudioTrackModel track) async {
    debugPrint('[AudioPlayerService] --- setTrack: "${track.title}" (videoId: ${track.videoId}) ---');

    // 1. Se a faixa possui um caminho local offline (audioUrl) e o arquivo existe, reproduz o arquivo local direto!
    if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
      final localFile = File(track.audioUrl!);
      if (localFile.existsSync()) {
        debugPrint('[AudioPlayerService] Reproduzindo arquivo offline local: ${localFile.path}');
        await _audioPlayer.setFilePath(localFile.path);
        return;
      }
    }

    // 2. Caso contrário, faz a busca online de stream no YouTube
    final musicUrl = 'https://youtube.com/watch?v=${track.videoId}';
    final extractor = YtExtractor();
    try {
      final info = await extractor.getStreamInfo(musicUrl);
      final audio = info.bestAudioStream;
      if (audio != null) {
        await _audioPlayer.setUrl(audio.url);
        return;
      }
    } catch (e) {
      debugPrint('[YtExtractor] --- Error extracting track: $e');
      throw Exception('URL não encontrada no YtExtractor');
    }
  }

  Future<void> play() async => await _audioPlayer.play();
  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> stop() async => await _audioPlayer.stop();
  Future<void> seek(Duration position) async => await _audioPlayer.seek(position);

  Future<void> setRepeatMode(RepeatMode mode) async {
    // A fila completa é gerenciada pelo PlayerController.
    // LoopMode.all no just_audio repetiria apenas a única faixa carregada.
    if (mode == RepeatMode.one) {
      await _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      await _audioPlayer.setLoopMode(LoopMode.off);
    }
  }

  Future<void> setShuffle(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
