import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../domain/models/artist_model.dart';
import '../../domain/repositories/artist_repository.dart';
import '../../../../features/player/domain/models/player_state_model.dart';
import '../../../../features/album/domain/models/album_model.dart';
import '../../../../features/playlist/domain/models/playlist_model.dart';

class YtMusicArtistRepository implements ArtistRepository {
  final YTMusic _ytMusic;
  bool _isInitialized = false;

  YtMusicArtistRepository({YTMusic? ytMusic}) : _ytMusic = ytMusic ?? YTMusic();

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      _isInitialized = true;
    }
  }

  @override
  Future<ArtistModel?> getArtist(String artistId) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return null;

    try {
      await _ensureInitialized();
      final artistFull = await _ytMusic.getArtist(cleanId);

      return ArtistModel(
        id: artistFull.artistId,
        name: artistFull.name,
        bannerUrl: artistFull.thumbnails.isNotEmpty ? artistFull.thumbnails.last.url : null,
        avatarUrl: artistFull.thumbnails.isNotEmpty ? artistFull.thumbnails.first.url : null,
        topSongs: artistFull.topSongs.map((s) => AudioTrackModel(
          id: s.videoId,
          videoId: s.videoId,
          title: s.name,
          artistName: artistFull.name,
          thumbnailUrl: s.thumbnails.isNotEmpty ? s.thumbnails.last.url : null,
          duration: null, // ytmusic_api doesn't reliably expose duration for these
        )).toList(),
        albums: artistFull.topAlbums.map((a) => AlbumModel(
          id: a.albumId,
          title: a.name,
          artistName: artistFull.name,
          artistId: artistFull.artistId,
          coverUrl: a.thumbnails.isNotEmpty ? a.thumbnails.last.url : null,
          year: null,
          trackCount: 0,
          tracks: const [],
        )).toList(),
        singles: artistFull.topSingles.map((a) => AlbumModel(
          id: a.albumId,
          title: a.name,
          artistName: artistFull.name,
          artistId: artistFull.artistId,
          coverUrl: a.thumbnails.isNotEmpty ? a.thumbnails.last.url : null,
          year: null,
          trackCount: 0,
          tracks: const [],
        )).toList(),
        featuredOn: artistFull.featuredOn.map((p) => PlaylistModel(
          id: p.playlistId,
          title: p.name,
          userId: p.artist.name, // fallback as userId
          coverUrl: p.thumbnails.isNotEmpty ? p.thumbnails.last.url : null,
          tracks: const [],
          createdAt: DateTime.now(),
          isPublic: true,
        )).toList(),
        similarArtists: artistFull.similarArtists.map((sa) => ArtistModel(
          id: sa.artistId,
          name: sa.name,
          avatarUrl: sa.thumbnails.isNotEmpty ? sa.thumbnails.last.url : null,
        )).toList(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AudioTrackModel>> getArtistSongs(String artistId) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return [];

    try {
      await _ensureInitialized();
      final songs = await _ytMusic.getArtistSongs(cleanId);
      return songs.map((s) => AudioTrackModel(
        id: s.videoId,
        videoId: s.videoId,
        title: s.name,
        artistName: s.artist.name,
        albumName: s.album?.name,
        thumbnailUrl: s.thumbnails.isNotEmpty ? s.thumbnails.last.url : null,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<AlbumModel>> getArtistAlbums(String artistId) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return [];

    try {
      await _ensureInitialized();
      final albums = await _ytMusic.getArtistAlbums(cleanId);
      return albums.map((a) => AlbumModel(
        id: a.albumId,
        title: a.name,
        artistName: a.artist.name,
        artistId: a.artist.artistId,
        coverUrl: a.thumbnails.isNotEmpty ? a.thumbnails.last.url : null,
        year: null,
        trackCount: 0,
        tracks: const [],
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<AlbumModel>> getArtistSingles(String artistId) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return [];

    try {
      await _ensureInitialized();
      final singles = await _ytMusic.getArtistSingles(cleanId);
      return singles.map((a) => AlbumModel(
        id: a.albumId,
        title: a.name,
        artistName: a.artist.name,
        artistId: a.artist.artistId,
        coverUrl: a.thumbnails.isNotEmpty ? a.thumbnails.last.url : null,
        year: null,
        trackCount: 0,
        tracks: const [],
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
