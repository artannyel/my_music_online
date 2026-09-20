/// Modelo de uma linha de letra com sincronização de tempo.
class LyricLineModel {
  final String text;
  final Duration startTime;
  final Duration endTime;

  const LyricLineModel({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  /// Verifica se a posição de reprodução dada está dentro do intervalo desta linha.
  bool isActiveAt(Duration position) {
    return position >= startTime && position <= endTime;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLineModel &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => text.hashCode ^ startTime.hashCode ^ endTime.hashCode;

  @override
  String toString() =>
      'LyricLineModel(text: $text, startTime: $startTime, endTime: $endTime)';
}

/// Modelo agregado das letras de uma música.
class LyricsModel {
  final String videoId;
  final bool hasTimedLyrics;
  final List<LyricLineModel> timedLines;
  final String? plainLyrics;
  final String? sourceMessage;

  const LyricsModel({
    required this.videoId,
    this.hasTimedLyrics = false,
    this.timedLines = const [],
    this.plainLyrics,
    this.sourceMessage,
  });

  /// Indica se há alguma letra (sincronizada ou texto estático) disponível.
  bool get hasContent =>
      (hasTimedLyrics && timedLines.isNotEmpty) ||
      (plainLyrics != null && plainLyrics!.trim().isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricsModel &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId &&
          hasTimedLyrics == other.hasTimedLyrics &&
          plainLyrics == other.plainLyrics &&
          sourceMessage == other.sourceMessage;

  @override
  int get hashCode =>
      videoId.hashCode ^
      hasTimedLyrics.hashCode ^
      plainLyrics.hashCode ^
      sourceMessage.hashCode;

  @override
  String toString() =>
      'LyricsModel(videoId: $videoId, hasTimedLyrics: $hasTimedLyrics, timedLines: ${timedLines.length}, sourceMessage: $sourceMessage)';
}
