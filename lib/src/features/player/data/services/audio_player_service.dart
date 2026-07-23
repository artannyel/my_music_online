// ignore_for_file: experimental_member_use

import 'package:audios_resolver/audios_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
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
      debugPrint('[AudioPlayerService] Requisitando manifesto AudiosResolver para ${track.videoId}...');
      final result = await AudiosResolver.fetchSingle(videoId: track.videoId, forceRefresh: true);

      if (result?.url != null) {
        await _audioPlayer.setUrl(result!.url);
        debugPrint('[AudioPlayerService] AudioSource configurado com sucesso. Chamando play()...');
        await _audioPlayer.play();
        debugPrint('[AudioPlayerService] Reprodução iniciada com sucesso via AudiosResolver!');
        return;
      } else {
        throw Exception('URL não encontrada no AudiosResolver');
      }
    } catch (e, st) {
      debugPrint('[AudioPlayerService] Falha no AudiosResolver: $e\n$st');
      throw Exception('Não foi possível carregar a faixa ${track.title}');
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
