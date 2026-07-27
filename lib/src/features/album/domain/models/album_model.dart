import '../../../player/domain/models/player_state_model.dart';

/// Modelo de domínio completo para exibição de um Álbum e suas faixas no aplicativo
class AlbumModel {
  final String id;
  final String title;
  final String artistName;
  final String? artistId;
  final String? coverUrl;
  final int? year;
  final int trackCount;
  final List<AudioTrackModel> tracks;

  const AlbumModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.artistId,
    this.coverUrl,
    this.year,
    required this.trackCount,
    required this.tracks,
  });
}
