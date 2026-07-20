import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../domain/models/search_result_model.dart';
import '../../domain/repositories/search_repository.dart';

/// Repositório de Busca que integra com a biblioteca dart_ytmusic_api.
class YtMusicSearchRepository implements SearchRepository {
  final YTMusic _ytMusic;
  bool _isInitialized = false;

  YtMusicSearchRepository({YTMusic? ytMusic}) : _ytMusic = ytMusic ?? YTMusic();

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      _isInitialized = true;
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      await _ensureInitialized();
      return await _ytMusic.getSearchSuggestions(query.trim());
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SearchResultModel>> search(
    String query, {
    SearchFilterType filter = SearchFilterType.all,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    await _ensureInitialized();

    try {
      switch (filter) {
        case SearchFilterType.song:
          final songs = await _ytMusic.searchSongs(trimmedQuery);
          return songs.map((s) {
            final thumb = s.thumbnails.isNotEmpty ? s.thumbnails.last.url : null;
            return SearchResultModel(
              id: s.videoId,
              videoId: s.videoId,
              title: s.name,
              subtitle: s.artist.name,
              thumbnailUrl: thumb,
              type: SearchFilterType.song,
              duration: s.duration != null ? Duration(seconds: s.duration!) : null,
            );
          }).toList();

        case SearchFilterType.album:
          final albums = await _ytMusic.searchAlbums(trimmedQuery);
          return albums.map((a) {
            final thumb = a.thumbnails.isNotEmpty ? a.thumbnails.last.url : null;
            final subtitle = a.year != null ? '${a.artist.name} • ${a.year}' : a.artist.name;
            return SearchResultModel(
              id: a.albumId,
              videoId: '',
              title: a.name,
              subtitle: subtitle,
              thumbnailUrl: thumb,
              type: SearchFilterType.album,
              albumId: a.albumId,
            );
          }).toList();

        case SearchFilterType.artist:
          final artists = await _ytMusic.searchArtists(trimmedQuery);
          return artists.map((art) {
            final thumb = art.thumbnails.isNotEmpty ? art.thumbnails.last.url : null;
            return SearchResultModel(
              id: art.artistId,
              videoId: '',
              title: art.name,
              subtitle: 'Artista',
              thumbnailUrl: thumb,
              type: SearchFilterType.artist,
              artistId: art.artistId,
            );
          }).toList();

        case SearchFilterType.playlist:
          final playlists = await _ytMusic.searchPlaylists(trimmedQuery);
          return playlists.map((p) {
            final thumb = p.thumbnails.isNotEmpty ? p.thumbnails.last.url : null;
            return SearchResultModel(
              id: p.playlistId,
              videoId: '',
              title: p.name,
              subtitle: 'Playlist • ${p.artist.name}',
              thumbnailUrl: thumb,
              type: SearchFilterType.playlist,
              playlistId: p.playlistId,
            );
          }).toList();

        case SearchFilterType.all:
          final rawResults = await _ytMusic.search(trimmedQuery);
          final List<SearchResultModel> results = [];
          for (final item in rawResults) {
            final mapped = _mapGenericSearchResult(item);
            if (mapped != null) {
              results.add(mapped);
            }
          }
          return results;
      }
    } catch (e) {
      return [];
    }
  }

  SearchResultModel? _mapGenericSearchResult(SearchResult item) {
    if (item is SongDetailed) {
      final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last.url : null;
      return SearchResultModel(
        id: item.videoId,
        videoId: item.videoId,
        title: item.name,
        subtitle: item.artist.name,
        thumbnailUrl: thumb,
        type: SearchFilterType.song,
        duration: item.duration != null ? Duration(seconds: item.duration!) : null,
      );
    } else if (item is VideoDetailed) {
      final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last.url : null;
      return SearchResultModel(
        id: item.videoId,
        videoId: item.videoId,
        title: item.name,
        subtitle: item.artist.name,
        thumbnailUrl: thumb,
        type: SearchFilterType.song,
        duration: item.duration != null ? Duration(seconds: item.duration!) : null,
      );
    } else if (item is AlbumDetailed) {
      final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last.url : null;
      final subtitle = item.year != null ? '${item.artist.name} • ${item.year}' : item.artist.name;
      return SearchResultModel(
        id: item.albumId,
        videoId: '',
        title: item.name,
        subtitle: subtitle,
        thumbnailUrl: thumb,
        type: SearchFilterType.album,
        albumId: item.albumId,
      );
    } else if (item is ArtistDetailed) {
      final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last.url : null;
      return SearchResultModel(
        id: item.artistId,
        videoId: '',
        title: item.name,
        subtitle: 'Artista',
        thumbnailUrl: thumb,
        type: SearchFilterType.artist,
        artistId: item.artistId,
      );
    } else if (item is PlaylistDetailed) {
      final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last.url : null;
      return SearchResultModel(
        id: item.playlistId,
        videoId: '',
        title: item.name,
        subtitle: 'Playlist • ${item.artist.name}',
        thumbnailUrl: thumb,
        type: SearchFilterType.playlist,
        playlistId: item.playlistId,
      );
    }
    return null;
  }
}
