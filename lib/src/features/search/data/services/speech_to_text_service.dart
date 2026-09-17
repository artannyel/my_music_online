import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Provider singleton para a instância do SpeechToTextService.
final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  return SpeechToTextService();
});

/// Serviço para gerenciar o reconhecimento de fala nativo (Speech to Text)
class SpeechToTextService {
  final SpeechToText _speechToText;
  bool _isInitialized = false;

  SpeechToTextService({SpeechToText? speechToText})
      : _speechToText = speechToText ?? SpeechToText();

  bool get isInitialized => _isInitialized;
  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _speechToText.isAvailable;
  Future<bool> get hasPermission => _speechToText.hasPermission;

  /// Inicializa o motor de reconhecimento de voz e solicita permissões caso necessário.
  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(String error)? onError,
  }) async {
    if (_isInitialized && _speechToText.isAvailable) {
      return true;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('[SpeechToTextService] Status: $status');
          onStatus?.call(status);
        },
        onError: (SpeechRecognitionError errorNotification) {
          debugPrint('[SpeechToTextService] Error: ${errorNotification.errorMsg} (permanent: ${errorNotification.permanent})');
          onError?.call(errorNotification.errorMsg);
        },
        debugLogging: kDebugMode,
      );

      final hasPerm = await _speechToText.hasPermission;
      debugPrint('[SpeechToTextService] Inicializado: $_isInitialized (available: ${_speechToText.isAvailable}, hasPermission: $hasPerm)');
      return _isInitialized;
    } catch (e) {
      debugPrint('[SpeechToTextService] Falha ao inicializar: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Inicia a escuta do microfone para captura e transcrição de fala em tempo real.
  Future<bool> startListening({
    required Function(String words, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevelChange,
    Function(String status)? onStatus,
    Function(String error)? onError,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize(onStatus: onStatus, onError: onError);
      if (!ok) return false;
    }

    if (_speechToText.isListening) {
      await stopListening();
    }

    try {
      // Tenta obter o idioma padrão do sistema se não especificado
      String? targetLocale = localeId;
      if (targetLocale == null) {
        try {
          final systemLocale = await _speechToText.systemLocale();
          targetLocale = systemLocale?.localeId ?? 'pt_BR';
        } catch (_) {
          targetLocale = 'pt_BR';
        }
      }

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: targetLocale,
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.search,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('[SpeechToTextService] Erro ao iniciar escuta: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Interrompe a escuta mantendo os resultados processados até o momento.
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      debugPrint('[SpeechToTextService] Erro ao parar escuta: $e');
    }
  }

  /// Cancela imediatamente a escuta descartando qualquer processamento pendente.
  Future<void> cancelListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.cancel();
      }
    } catch (e) {
      debugPrint('[SpeechToTextService] Erro ao cancelar escuta: $e');
    }
  }
}
