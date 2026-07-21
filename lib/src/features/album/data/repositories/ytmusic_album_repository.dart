import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';
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

      final coverUrl = albumFull.thumbnails.isNotEmpty
          ? albumFull.thumbnails.last.url
          : null;

      final songs = await _getPlaylistItems(albumFull.playlistId);

      final mappedTracks = songs.map((song) {
        final trackThumb = song.thumbnails.isNotEmpty
            ? song.thumbnails.last
            : coverUrl;

        return AudioTrackModel(
          id: song.id ?? 'No id',
          videoId: song.id ?? 'No id',
          title: song.name ?? 'No title',
          artistName: song.uploaderName ?? albumFull.artist.name,
          albumName: albumFull.name,
          thumbnailUrl: trackThumb,
          duration: song.duration != null
              ? Duration(seconds: song.duration!)
              : null,
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
        yt.close();

        final url = 'https://www.youtube.com/playlist?list=${playlist.id.value}';
        final newpipePlaylist = await PlaylistExtractor.getPlaylistDetails(url);
        final videos = await _getPlaylistItems(playlist.id.value);

        final coverUrl = newpipePlaylist.thumbnails.isNotEmpty
            ? newpipePlaylist.thumbnails.last
            : null;

        final mappedTracks = videos.map((video) {
          final trackThumb = video.thumbnails.isNotEmpty
              ? video.thumbnails.last
              : coverUrl;
          return AudioTrackModel(
            id: video.id ?? 'No id',
            videoId: video.id ?? 'No id',
            title: video.name ?? 'No title',
            artistName: video.uploaderName ?? playlist.author,
            albumName: playlist.title,
            thumbnailUrl: trackThumb,
            duration: video.duration != null
                ? Duration(seconds: video.duration!)
                : null,
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
          final coverUrl = songFull.thumbnails.isNotEmpty
              ? songFull.thumbnails.last.url
              : null;
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
              ),
            ],
          );
        } catch (e3) {
          return null;
        }
      }
    }
  }

  Future<List<StreamInfoItem>> _getPlaylistItems(
    String playlistId,
  ) async {
    final url = 'https://www.youtube.com/playlist?list=${playlistId}';
    final streams = await PlaylistExtractor.getPlaylistStreams(url);
    final itens = streams.items;
    if (streams.next != null) {
      final nextItens = await _getPlaylistNextItems(playlistId, streams.next!);
      itens.addAll(nextItens);
    }
    return itens;
  }

  Future<List<StreamInfoItem>> _getPlaylistNextItems(
    String playlistId,
    PageToken pageToken,
  ) async {
    final url = 'https://www.youtube.com/playlist?list=${playlistId}';
    final streams = await PlaylistExtractor.getPlaylistNextPage(url, pageToken);
    final itens = streams.items;
    if (streams.next != null) {
      final nextItens = await _getPlaylistNextItems(playlistId, streams.next!);
      itens.addAll(nextItens);
    }
    return itens;
  }
}
