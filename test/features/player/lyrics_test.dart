import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_online/src/features/player/domain/models/lyrics_model.dart';
import 'package:my_music_online/src/features/player/domain/repositories/lyrics_repository.dart';

class FakeLyricsRepository implements LyricsRepository {
  LyricsModel? stubbedLyrics;

  @override
  Future<LyricsModel?> getLyrics(String videoId) async {
    return stubbedLyrics;
  }
}

int calculateActiveLyricIndex({
  required LyricsModel? lyrics,
  required Duration position,
}) {
  if (lyrics == null || !lyrics.hasTimedLyrics || lyrics.timedLines.isEmpty) {
    return -1;
  }

  final lines = lyrics.timedLines;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].isActiveAt(position)) {
      return i;
    }
  }

  int lastStartedIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (position >= lines[i].startTime) {
      lastStartedIndex = i;
    } else {
      break;
    }
  }

  return lastStartedIndex;
}

void main() {
  group('LyricsModel Tests', () {
    test('LyricLineModel isActiveAt identifica intervalo correto', () {
      const line = LyricLineModel(
        text: 'Hello world',
        startTime: Duration(seconds: 10),
        endTime: Duration(seconds: 15),
      );

      expect(line.isActiveAt(const Duration(seconds: 9)), isFalse);
      expect(line.isActiveAt(const Duration(seconds: 10)), isTrue);
      expect(line.isActiveAt(const Duration(seconds: 12)), isTrue);
      expect(line.isActiveAt(const Duration(seconds: 15)), isTrue);
      expect(line.isActiveAt(const Duration(seconds: 16)), isFalse);
    });

    test('LyricsModel hasContent valida sincronizada e estática', () {
      const emptyModel = LyricsModel(videoId: '123');
      expect(emptyModel.hasContent, isFalse);

      const timedModel = LyricsModel(
        videoId: '123',
        hasTimedLyrics: true,
        timedLines: [
          LyricLineModel(
            text: 'Test',
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
          ),
        ],
      );
      expect(timedModel.hasContent, isTrue);

      const plainModel = LyricsModel(
        videoId: '123',
        hasTimedLyrics: false,
        plainLyrics: 'Some plain text lyrics',
      );
      expect(plainModel.hasContent, isTrue);
    });
  });

  group('Lyrics Sincronização e Repositório Tests', () {
    test('FakeLyricsRepository retorna as letras configuradas', () async {
      final repo = FakeLyricsRepository();
      const model = LyricsModel(
        videoId: 'test_vid',
        hasTimedLyrics: true,
        timedLines: [
          LyricLineModel(
            text: 'Verso 1',
            startTime: Duration(seconds: 0),
            endTime: Duration(seconds: 4),
          ),
        ],
      );
      repo.stubbedLyrics = model;

      final result = await repo.getLyrics('test_vid');
      expect(result, equals(model));
      expect(result?.timedLines.first.text, 'Verso 1');
    });

    test('calculateActiveLyricIndex calcula o verso correto em tempo real', () {
      const lyrics = LyricsModel(
        videoId: 'v1',
        hasTimedLyrics: true,
        timedLines: [
          LyricLineModel(
            text: 'Linha 1',
            startTime: Duration(seconds: 2),
            endTime: Duration(seconds: 6),
          ),
          LyricLineModel(
            text: 'Linha 2',
            startTime: Duration(seconds: 7),
            endTime: Duration(seconds: 12),
          ),
        ],
      );

      // Antes da música começar
      expect(calculateActiveLyricIndex(lyrics: lyrics, position: const Duration(seconds: 1)), -1);

      // Durante a Linha 1
      expect(calculateActiveLyricIndex(lyrics: lyrics, position: const Duration(seconds: 3)), 0);

      // Entre as duas linhas (pausa instrumental) -> mantém a última que começou
      expect(calculateActiveLyricIndex(lyrics: lyrics, position: const Duration(seconds: 6, milliseconds: 500)), 0);

      // Durante a Linha 2
      expect(calculateActiveLyricIndex(lyrics: lyrics, position: const Duration(seconds: 8)), 1);

      // Sem letras sincronizadas
      expect(calculateActiveLyricIndex(lyrics: null, position: const Duration(seconds: 5)), -1);
    });
  });
}
