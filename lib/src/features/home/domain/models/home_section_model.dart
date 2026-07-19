enum HomeItemType { song, playlist, album, artist }

/// Model que representa um item exibido nos carrosséis ou listas da Home.
class HomeItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final HomeItemType type;
  final String? artistId;
  final String? albumId;
  final String? playlistId;
  final Duration? duration;

  const HomeItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    required this.type,
    this.artistId,
    this.albumId,
    this.playlistId,
    this.duration,
  });

  factory HomeItemModel.fromJson(Map<String, dynamic> json) {
    return HomeItemModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      type: HomeItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HomeItemType.song,
      ),
      artistId: json['artistId'] as String?,
      albumId: json['albumId'] as String?,
      playlistId: json['playlistId'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
      'type': type.name,
      'artistId': artistId,
      'albumId': albumId,
      'playlistId': playlistId,
      'duration': duration?.inSeconds,
    };
  }
}

/// Seção da Home (ex: "Sugestões para Você", "Mais Tocadas", "Álbuns Populares").
class HomeSectionModel {
  final String title;
  final List<HomeItemModel> items;

  const HomeSectionModel({
    required this.title,
    required this.items,
  });
}
