import '../../../../features/player/domain/models/player_state_model.dart';
import '../../../../features/album/domain/models/album_model.dart';
import '../../../../features/playlist/domain/models/playlist_model.dart';

class ArtistModel {
  final String id;
  final String name;
  final String? bannerUrl;
  final String? avatarUrl;
  final String? description;
  final List<AudioTrackModel> topSongs;
  final List<AlbumModel> albums;
  final List<AlbumModel> singles;
  final List<PlaylistModel> featuredOn;
  final List<ArtistModel> similarArtists;

  const ArtistModel({
    required this.id,
    required this.name,
    this.bannerUrl,
    this.avatarUrl,
    this.description,
    this.topSongs = const [],
    this.albums = const [],
    this.singles = const [],
    this.featuredOn = const [],
    this.similarArtists = const [],
  });

  ArtistModel copyWith({
    String? id,
    String? name,
    String? bannerUrl,
    String? avatarUrl,
    String? description,
    List<AudioTrackModel>? topSongs,
    List<AlbumModel>? albums,
    List<AlbumModel>? singles,
    List<PlaylistModel>? featuredOn,
    List<ArtistModel>? similarArtists,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      topSongs: topSongs ?? this.topSongs,
      albums: albums ?? this.albums,
      singles: singles ?? this.singles,
      featuredOn: featuredOn ?? this.featuredOn,
      similarArtists: similarArtists ?? this.similarArtists,
    );
  }
}
