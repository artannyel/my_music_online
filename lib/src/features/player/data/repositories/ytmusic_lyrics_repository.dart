import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/lyrics_model.dart';
import '../../domain/repositories/lyrics_repository.dart';

/// Implementação do [LyricsRepository] utilizando o pacote `dart_ytmusic_api`.
/// Inclui fallback automático para letra estática e cache simples em memória.
class YtmusicLyricsRepository implements LyricsRepository {
  final YTMusic _ytMusic;
  final Map<String, LyricsModel> _cache = {};

  YtmusicLyricsRepository([YTMusic? ytMusic]) : _ytMusic = ytMusic ?? YTMusic();

  @override
  Future<LyricsModel?> getLyrics(String videoId) async {
    if (videoId.isEmpty) return null;

    if (_cache.containsKey(videoId)) {
      return _cache[videoId];
    }

    try {
      // 1. Tenta buscar letras sincronizadas (Timed Lyrics)
      final timedLyricsRes = await _ytMusic.getTimedLyrics(videoId);
      if (timedLyricsRes != null && timedLyricsRes.timedLyricsData.isNotEmpty) {
        final List<LyricLineModel> timedLines = [];

        for (final data in timedLyricsRes.timedLyricsData) {
          final line = data.lyricLine?.trim();
          final cue = data.cueRange;
          if (line != null && line.isNotEmpty && cue != null) {
            timedLines.add(
              LyricLineModel(
                text: line,
                startTime: Duration(milliseconds: cue.startTimeMilliseconds),
                endTime: Duration(milliseconds: cue.endTimeMilliseconds),
              ),
            );
          }
        }

        if (timedLines.isNotEmpty) {
          final model = LyricsModel(
            videoId: videoId,
            hasTimedLyrics: true,
            timedLines: timedLines,
            sourceMessage: timedLyricsRes.sourceMessage.isNotEmpty
                ? timedLyricsRes.sourceMessage
                : null,
          );
          _cache[videoId] = model;
          return model;
        }
      }
    } catch (e) {
      debugPrint('[YtmusicLyricsRepository] Erro ao buscar timed lyrics: $e');
    }

    try {
      // 2. Fallback: Tenta buscar letra estática (Plain Lyrics)
      final plainLyrics = await _ytMusic.getLyrics(videoId);
      if (plainLyrics != null && plainLyrics.trim().isNotEmpty) {
        final model = LyricsModel(
          videoId: videoId,
          hasTimedLyrics: false,
          plainLyrics: plainLyrics.trim(),
        );
        _cache[videoId] = model;
        return model;
      }
    } catch (e) {
      debugPrint('[YtmusicLyricsRepository] Erro ao buscar plain lyrics: $e');
    }

    return null;
  }
}
