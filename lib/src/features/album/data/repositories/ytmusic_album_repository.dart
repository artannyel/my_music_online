import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
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
      // Fallback 1: Tentar como Playlist via youtube_explode_dart (ideal para listas OLAK)
      try {
        final yt = yt_explode.YoutubeExplode();
        final playlist = await yt.playlists.get(cleanId);
        final videos = await yt.playlists.getVideos(cleanId).toList();
        yt.close();

        final coverUrl = playlist.thumbnails.highResUrl;
        
        final mappedTracks = videos.map((video) {
          final trackThumb = video.thumbnails.highResUrl;
          return AudioTrackModel(
            id: video.id.value,
            videoId: video.id.value,
            title: video.title,
            artistName: video.author,
            albumName: playlist.title,
            thumbnailUrl: trackThumb,
            duration: video.duration,
          );
        }).toList();

        return AlbumModel(
          id: playlist.id.value,
          title: playlist.title,
          artistName: playlist.author,
          artistId: null,
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
