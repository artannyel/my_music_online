import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_music_online/src/features/search/data/services/speech_to_text_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FakeSpeechToText extends SpeechToText {
  bool initializedResult = true;
  bool listenResult = true;
  bool isListeningState = false;
  bool isAvailableState = true;
  bool hasPermissionState = true;
  SpeechErrorListener? registeredOnError;
  SpeechStatusListener? registeredOnStatus;

  FakeSpeechToText() : super.withMethodChannel();

  @override
  bool get isListening => isListeningState;

  @override
  bool get isAvailable => isAvailableState;

  @override
  Future<bool> get hasPermission async => hasPermissionState;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    registeredOnError = onError;
    registeredOnStatus = onStatus;
    return initializedResult;
  }

  @override
  Future<bool> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    Function(double soundLevel)? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    if (listenResult) {
      isListeningState = true;
      if (onResult != null) {
        onResult(SpeechRecognitionResult(
          [SpeechRecognitionWords('Coldplay Yellow', const ['Coldplay Yellow'], 0.95)],
          ResultType.finalResult.value,
        ));
      }
    }
    return listenResult;
  }

  @override
  Future<void> stop() async {
    isListeningState = false;
  }

  @override
  Future<void> cancel() async {
    isListeningState = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeechToTextService Tests', () {
    test('instanciação padrão e estado inicial', () {
      final service = SpeechToTextService();
      expect(service.isInitialized, isFalse);
      expect(service.isListening, isFalse);
    });

    test('inicialização com sucesso', () async {
      final fake = FakeSpeechToText()..initializedResult = true;
      final service = SpeechToTextService(speechToText: fake);

      final ok = await service.initialize();
      expect(ok, isTrue);
      expect(service.isInitialized, isTrue);
      expect(await service.hasPermission, isTrue);
    });

    test('startListening captura resultado de fala e notifica callback', () async {
      final fake = FakeSpeechToText();
      final service = SpeechToTextService(speechToText: fake);

      String? capturedWords;
      bool? isFinalResult;

      final started = await service.startListening(
        onResult: (words, isFinal) {
          capturedWords = words;
          isFinalResult = isFinal;
        },
      );

      expect(started, isTrue);
      expect(capturedWords, 'Coldplay Yellow');
      expect(isFinalResult, isTrue);
      expect(service.isListening, isTrue);
    });

    test('stopListening e cancelListening alteram estado para inativo', () async {
      final fake = FakeSpeechToText();
      final service = SpeechToTextService(speechToText: fake);

      await service.startListening(onResult: (_, __) {});
      expect(service.isListening, isTrue);

      await service.stopListening();
      expect(service.isListening, isFalse);

      await service.startListening(onResult: (_, __) {});
      expect(service.isListening, isTrue);

      await service.cancelListening();
      expect(service.isListening, isFalse);
    });

    test('tratamento de erro durante a inicialização', () async {
      final fake = FakeSpeechToText()..initializedResult = false;
      final service = SpeechToTextService(speechToText: fake);

      final ok = await service.initialize();
      expect(ok, isFalse);
      expect(service.isInitialized, isFalse);
    });

    test('speechToTextServiceProvider provê instância funcional', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(speechToTextServiceProvider);
      expect(service, isA<SpeechToTextService>());
    });
  });
}
