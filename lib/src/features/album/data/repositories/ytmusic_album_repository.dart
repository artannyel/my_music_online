import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../domain/models/album_model.dart';
import '../../domain/repositories/album_repository.dart';

/// Implementação do repositório de Álbuns utilizando dart_ytmusic_api
class YtMusicAlbumRepository implements AlbumRepository {
  final YTMusic _ytMusic;
  bool _isInitialized = false;

  YtMusicAlbumRepository({YTMusic? ytMusic}) : _ytMusic = ytMusic ?? YTMusic();

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      _isInitialized = true;
    }
  }

  @override
  Future<AlbumModel?> getAlbumDetails(String albumId) async {
    final cleanId = albumId.trim();
    if (cleanId.isEmpty) return null;

    try {
      await _ensureInitialized();
      final albumFull = await _ytMusic.getAlbum(cleanId);

      final coverUrl = albumFull.thumbnails.isNotEmpty ? albumFull.thumbnails.last.url : null;

      final mappedTracks = albumFull.songs.map((song) {
        final trackThumb = song.thumbnails.isNotEmpty
            ? song.thumbnails.last.url
            : coverUrl;

        return AudioTrackModel(
          id: song.videoId,
          videoId: song.videoId,
          title: song.name,
          artistName: song.artist.name.isNotEmpty ? song.artist.name : albumFull.artist.name,
          albumName: albumFull.name,
          thumbnailUrl: trackThumb,
          duration: song.duration != null ? Duration(seconds: song.duration!) : null,
        );
      }).toList();

      return AlbumModel(
        id: albumFull.albumId,
        title: albumFull.name,
        artistName: albumFull.artist.name,
        artistId: albumFull.artist.artistId,
        coverUrl: coverUrl,
        year: albumFull.year,
        trackCount: mappedTracks.length,
        tracks: mappedTracks,
      );
    } catch (e) {
      // Fallback 1: Tentar como Playlist
      try {
        final playlistFull = await _ytMusic.getPlaylist(cleanId);
        final playlistVideos = await _ytMusic.getPlaylistVideos(cleanId);

        final coverUrl = playlistFull.thumbnails.isNotEmpty ? playlistFull.thumbnails.last.url : null;
        
        final mappedTracks = playlistVideos.map((video) {
          final trackThumb = video.thumbnails.isNotEmpty ? video.thumbnails.last.url : coverUrl;
          return AudioTrackModel(
            id: video.videoId,
            videoId: video.videoId,
            title: video.name,
            artistName: video.artist.name.isNotEmpty ? video.artist.name : playlistFull.artist.name,
            albumName: playlistFull.name,
            thumbnailUrl: trackThumb,
            duration: video.duration != null ? Duration(seconds: video.duration!) : null,
          );
        }).toList();

        return AlbumModel(
          id: playlistFull.playlistId,
          title: playlistFull.name,
          artistName: playlistFull.artist.name,
          artistId: playlistFull.artist.artistId,
          coverUrl: coverUrl,
          year: null,
          trackCount: mappedTracks.length,
          tracks: mappedTracks,
        );
      } catch (e2) {
        // Fallback 2: Tentar como Single (Song)
        try {
          final songFull = await _ytMusic.getSong(cleanId);
          final coverUrl = songFull.thumbnails.isNotEmpty ? songFull.thumbnails.last.url : null;
          return AlbumModel(
            id: songFull.videoId,
            title: songFull.name,
            artistName: songFull.artist.name,
            artistId: songFull.artist.artistId,
            coverUrl: coverUrl,
            year: null,
            trackCount: 1,
            tracks: [
              AudioTrackModel(
                id: songFull.videoId,
                videoId: songFull.videoId,
                title: songFull.name,
                artistName: songFull.artist.name,
                albumName: songFull.name,
                thumbnailUrl: coverUrl,
                duration: Duration(seconds: songFull.duration),
              )
            ],
          );
        } catch(e3) {
          return null;
        }
      }
    }
  }
}
