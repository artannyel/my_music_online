enum RepeatMode { off, one, all }

/// Model de dados de uma faixa reproduzível pelo player de áudio.
class AudioTrackModel {
  final String id;
  final String videoId;
  final String title;
  final String artistName;
  final String? albumName;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? audioUrl;

  const AudioTrackModel({
    required this.id,
    required this.videoId,
    required this.title,
    required this.artistName,
    this.albumName,
    this.thumbnailUrl,
    this.duration,
    this.audioUrl,
  });

  factory AudioTrackModel.fromJson(Map<String, dynamic> json) {
    return AudioTrackModel(
      id: json['id'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'artistName': artistName,
      'albumName': albumName,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration?.inSeconds,
      'audioUrl': audioUrl,
    };
  }

  AudioTrackModel copyWith({
    String? id,
    String? videoId,
    String? title,
    String? artistName,
    String? albumName,
    String? thumbnailUrl,
    Duration? duration,
    String? audioUrl,
  }) {
    return AudioTrackModel(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

/// Estado global da reprodução do Player de Áudio.
class PlayerStateModel {
  final AudioTrackModel? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final List<AudioTrackModel> queue;
  final int currentIndex;

  const PlayerStateModel({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.queue = const [],
    this.currentIndex = -1,
  });

  PlayerStateModel copyWith({
    AudioTrackModel? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    List<AudioTrackModel>? queue,
    int? currentIndex,
  }) {
    return PlayerStateModel(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
