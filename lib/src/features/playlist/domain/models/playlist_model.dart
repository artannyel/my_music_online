enum PlaylistType { youtube, custom }

/// Model que representa uma faixa dentro de uma playlist.
class PlaylistTrackModel {
  final String id;
  final String title;
  final String artistName;
  final String? albumName;
  final String? thumbnailUrl;
  final String? videoId;
  final Duration? duration;

  const PlaylistTrackModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.albumName,
    this.thumbnailUrl,
    this.videoId,
    this.duration,
  });

  factory PlaylistTrackModel.fromJson(Map<String, dynamic> json) {
    return PlaylistTrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoId: json['videoId'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'albumName': albumName,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'duration': duration?.inSeconds,
    };
  }
}

/// Model principal de Playlist (pública do YTMusic ou salva/criada pelo usuário no Firestore).
class PlaylistModel {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final String? coverUrl;
  final List<PlaylistTrackModel> tracks;
  final DateTime createdAt;
  final bool isPublic;
  final PlaylistType type;
  final String? originalYtPlaylistId;

  const PlaylistModel({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.coverUrl,
    this.tracks = const [],
    required this.createdAt,
    this.isPublic = true,
    this.type = PlaylistType.custom,
    this.originalYtPlaylistId,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List<dynamic>? ?? [];
    return PlaylistModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      tracks: rawTracks
          .map((t) => PlaylistTrackModel.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isPublic: json['isPublic'] as bool? ?? true,
      type: PlaylistType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlaylistType.custom,
      ),
      originalYtPlaylistId: json['originalYtPlaylistId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
      'type': type.name,
      'originalYtPlaylistId': originalYtPlaylistId,
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? coverUrl,
    List<PlaylistTrackModel>? tracks,
    DateTime? createdAt,
    bool? isPublic,
    PlaylistType? type,
    String? originalYtPlaylistId,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      type: type ?? this.type,
      originalYtPlaylistId: originalYtPlaylistId ?? this.originalYtPlaylistId,
    );
  }
}
