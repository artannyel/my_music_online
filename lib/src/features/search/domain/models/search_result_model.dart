enum SearchFilterType { all, song, album, artist, playlist }

/// Modelo unificado de resultado de pesquisa no aplicativo
class SearchResultModel {
  final String id;
  final String videoId;
  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final SearchFilterType type;
  final Duration? duration;
  final String? albumId;
  final String? artistId;
  final String? playlistId;

  const SearchResultModel({
    required this.id,
    required this.videoId,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    required this.type,
    this.duration,
    this.albumId,
    this.artistId,
    this.playlistId,
  });
}
