import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yt_extractor/yt_extractor.dart';
import '../../domain/models/player_state_model.dart';

/// Serviço do Player de Áudio focado no just_audio e AudiosResolver
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  final AndroidEqualizer? _equalizer;
  AndroidEqualizerParameters? _equalizerParameters;
  final Map<double, double> _pendingGains = {};
  bool _pendingEnabled = true;

  AudioPlayerService({
    AudioPlayer? audioPlayer,
    AndroidEqualizer? equalizer,
  }) : this._internal(
          equalizer ?? (!kIsWeb && Platform.isAndroid ? AndroidEqualizer() : null),
          audioPlayer,
        );

  AudioPlayerService._internal(this._equalizer, AudioPlayer? audioPlayer)
      : _audioPlayer = audioPlayer ??
            AudioPlayer(
              audioPipeline: _equalizer != null
                  ? AudioPipeline(androidAudioEffects: [_equalizer])
                  : null,
            ) {
    _initEqualizer();
  }

  AudioPlayer get player => _audioPlayer;
  AndroidEqualizer? get equalizer => _equalizer;
  AndroidEqualizerParameters? get equalizerParameters => _equalizerParameters;

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

  void _initEqualizer() {
    if (_equalizer == null) return;

    _equalizer.parameters.then((params) {
      debugPrint('[AudioPlayerService] AndroidEqualizer parameters carregados com sucesso!');
      debugPrint('[AudioPlayerService] minDecibels: ${params.minDecibels}, maxDecibels: ${params.maxDecibels}');
      for (final band in params.bands) {
        debugPrint('[AudioPlayerService] Band ${band.index}: centerFreq=${band.centerFrequency}Hz, gain=${band.gain}');
      }
      _equalizerParameters = params;
      _applyPendingEqualizerSettings();
    }).catchError((e) {
      debugPrint('[AudioPlayerService] Erro ao carregar parâmetros do equalizador: $e');
    });
  }

  /// Liga ou desliga o equalizador de áudio em tempo real.
  Future<void> setEqualizerEnabled(bool enabled) async {
    _pendingEnabled = enabled;
    if (_equalizer == null) return;

    try {
      await _equalizer.setEnabled(enabled);
      debugPrint('[AudioPlayerService] Equalizador ${enabled ? "ativado" : "desativado"}');
    } catch (e) {
      debugPrint('[AudioPlayerService] Erro ao alterar status do equalizador: $e');
    }
  }

  /// Ajusta o ganho em dB de uma faixa de frequência em tempo real.
  Future<void> setBandGain(double frequencyHz, double gainDb) async {
    _pendingGains[frequencyHz] = gainDb;
    if (_equalizer == null) return;

    final params = _equalizerParameters;
    if (params == null) {
      debugPrint('[AudioPlayerService] Parâmetros do equalizador ainda não disponíveis. Ganho $gainDb dB para $frequencyHz Hz salvo como pendente.');
      return;
    }

    try {
      final band = _findClosestBand(frequencyHz, params.bands);
      if (band != null) {
        final platformGain = _convertDbToPlatformGain(gainDb, params);
        await band.setGain(platformGain);
        debugPrint('[AudioPlayerService] Banda ${band.index} (${band.centerFrequency}Hz) ajustada para $gainDb dB (platform: $platformGain)');
      }
    } catch (e) {
      debugPrint('[AudioPlayerService] Erro ao ajustar ganho da banda ($frequencyHz Hz): $e');
    }
  }

  /// Aplica todos os ganhos das frequências simultaneamente (ex: ao trocar de preset).
  Future<void> setAllBandGains(Map<double, double> gains) async {
    _pendingGains.addAll(gains);
    if (_equalizer == null) return;

    final params = _equalizerParameters;
    if (params == null) {
      debugPrint('[AudioPlayerService] Parâmetros do equalizador ainda não disponíveis. ${gains.length} ganhos salvos como pendentes.');
      return;
    }

    for (final entry in gains.entries) {
      try {
        final band = _findClosestBand(entry.key, params.bands);
        if (band != null) {
          final platformGain = _convertDbToPlatformGain(entry.value, params);
          await band.setGain(platformGain);
        }
      } catch (e) {
        debugPrint('[AudioPlayerService] Erro ao aplicar ganho da banda ${entry.key}Hz: $e');
      }
    }
    debugPrint('[AudioPlayerService] Todas as bandas do equalizador foram atualizadas.');
  }

  Future<void> _applyPendingEqualizerSettings() async {
    if (_equalizer == null || _equalizerParameters == null) return;

    try {
      await _equalizer.setEnabled(_pendingEnabled);
      if (_pendingGains.isNotEmpty) {
        await setAllBandGains(_pendingGains);
      }
    } catch (e) {
      debugPrint('[AudioPlayerService] Erro ao aplicar configurações pendentes do equalizador: $e');
    }
  }

  AndroidEqualizerBand? _findClosestBand(double freqHz, List<AndroidEqualizerBand> bands) {
    if (bands.isEmpty) return null;
    AndroidEqualizerBand closest = bands.first;
    double minDiff = (closest.centerFrequency - freqHz).abs();
    for (final band in bands.skip(1)) {
      final diff = (band.centerFrequency - freqHz).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = band;
      }
    }
    return closest;
  }

  double _convertDbToPlatformGain(double gainDb, AndroidEqualizerParameters params) {
    final isScaledBy1000 = params.maxDecibels <= 3.0;
    final platformGain = isScaledBy1000 ? (gainDb / 10.0) : gainDb;
    final min = params.minDecibels < params.maxDecibels ? params.minDecibels : -1.5;
    final max = params.minDecibels < params.maxDecibels ? params.maxDecibels : 1.5;
    return platformGain.clamp(min, max);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
