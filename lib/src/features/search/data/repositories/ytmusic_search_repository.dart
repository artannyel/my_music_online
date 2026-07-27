import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart' as newpipe;
import '../../domain/models/search_result_model.dart';
import '../../domain/repositories/search_repository.dart';

/// Repositório de Busca que integra com a biblioteca dart_ytmusic_api.
class YtMusicSearchRepository implements SearchRepository {
  final YTMusic _ytMusic;
  final Map<SearchFilterType, newpipe.PageToken?> _pageTokens = {};
  bool _isInitialized = false;

  YtMusicSearchRepository({YTMusic? ytMusic}) : _ytMusic = ytMusic ?? YTMusic();

  bool isMore(SearchFilterType type) => _pageTokens[type] != null;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      await newpipe.LocalizationExtractor.setLocalization('pt-BR', 'BR');
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
      List<String> newpipeFilters = [];
      bool useYoutubeMusic = filter == SearchFilterType.song;

      switch (filter) {
        case SearchFilterType.song:
          newpipeFilters = [newpipe.SearchFilter.musicSongs.value];
          break;
        case SearchFilterType.album:
          newpipeFilters = [newpipe.SearchFilter.musicAlbums.value];
          break;
        case SearchFilterType.artist:
          newpipeFilters = [newpipe.SearchFilter.musicArtists.value];
          break;
        case SearchFilterType.playlist:
          newpipeFilters = [newpipe.SearchFilter.musicPlaylists.value];
          break;
        case SearchFilterType.all:
          newpipeFilters = [newpipe.SearchFilter.all.value];
          break;
      }

      final streams = useYoutubeMusic
          ? await newpipe.SearchExtractor.searchYoutubeMusic(
              trimmedQuery,
              newpipeFilters,
            )
          : await newpipe.SearchExtractor.searchYoutube(
              trimmedQuery,
              newpipeFilters,
            );

      _pageTokens[filter] = streams.next;

      return _mapNewpipeResult(streams.result, filter);
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResultModel>> moreResults(
    String query,
    SearchFilterType filter,
  ) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];
    if (!isMore(filter)) return [];

    try {
      final token = _pageTokens[filter]!;
      List<String> newpipeFilters = [];
      bool useYoutubeMusic = filter == SearchFilterType.song;

      switch (filter) {
        case SearchFilterType.song:
          newpipeFilters = [newpipe.SearchFilter.musicSongs.value];
          break;
        case SearchFilterType.album:
          newpipeFilters = [newpipe.SearchFilter.musicAlbums.value];
          break;
        case SearchFilterType.artist:
          newpipeFilters = [newpipe.SearchFilter.musicArtists.value];
          break;
        case SearchFilterType.playlist:
          newpipeFilters = [newpipe.SearchFilter.musicPlaylists.value];
          break;
        case SearchFilterType.all:
          newpipeFilters = [newpipe.SearchFilter.all.value];
          break;
      }

      final streams = useYoutubeMusic
          ? await newpipe.SearchExtractor.searchMusicNextPage(
              trimmedQuery,
              newpipeFilters,
              token,
            )
          : await newpipe.SearchExtractor.searchNextPage(
              trimmedQuery,
              newpipeFilters,
              token,
            );

      _pageTokens[filter] = streams.next;

      return _mapNewpipeResult(streams.result, filter);
    } catch (e) {
      return [];
    }
  }

  List<SearchResultModel> _mapNewpipeResult(
    newpipe.SearchResult result,
    SearchFilterType requestedFilter,
  ) {
    final List<SearchResultModel> mapped = [];

    void processItem(dynamic item, String? url) {
      final thumb = item.thumbnails.isNotEmpty ? item.thumbnails.last : null;
      final name = item.name ?? '';

      String id = '';
      String uploader = '';

      if (item is newpipe.StreamInfoItem) {
        id = item.id ?? '';
        uploader = item.uploaderName ?? '';
      } else if (item is newpipe.PlaylistInfoItem) {
        uploader = item.uploaderName ?? '';
      } else if (item is newpipe.ChannelInfoItem) {
        uploader = '';
      }

      if (id.isEmpty && url != null) {
        if (url.contains('list=')) {
          id = url.split('list=').last.split('&').first;
        } else if (url.contains('/channel/')) {
          id = url.split('/channel/').last.split('?').first;
        } else {
          id = url;
        }
      }

      SearchFilterType type = requestedFilter;
      if (type == SearchFilterType.all) {
        if (item is newpipe.ChannelInfoItem)
          type = SearchFilterType.artist;
        else if (item is newpipe.PlaylistInfoItem)
          type = SearchFilterType.playlist;
        else
          type = SearchFilterType.song;
      }

      // YouTube Music albums usually start with MPREb_ or OLAK5uy_
      if (type == SearchFilterType.album ||
          (type == SearchFilterType.all &&
              (id.startsWith('MPREb_') || id.startsWith('OLAK5uy_')))) {
        mapped.add(
          SearchResultModel(
            id: id,
            videoId: '',
            title: name,
            subtitle: uploader.isNotEmpty ? uploader : 'No artist',
            thumbnailUrl: thumb,
            type: SearchFilterType.album,
            albumId: id,
            url: url,
          ),
        );
      } else if (type == SearchFilterType.artist) {
        mapped.add(
          SearchResultModel(
            id: id,
            videoId: '',
            title: name,
            subtitle: 'Artista',
            thumbnailUrl: thumb,
            type: SearchFilterType.artist,
            artistId: id,
            url: url,
          ),
        );
      } else if (type == SearchFilterType.playlist) {
        mapped.add(
          SearchResultModel(
            id: id,
            videoId: '',
            title: name,
            subtitle: 'Playlist • $uploader',
            thumbnailUrl: thumb,
            type: SearchFilterType.playlist,
            playlistId: id,
            url: url,
          ),
        );
      } else {
        mapped.add(
          SearchResultModel(
            id: id,
            videoId: id,
            title: name,
            subtitle: uploader.isNotEmpty ? uploader : 'No artist',
            thumbnailUrl: thumb,
            type: SearchFilterType.song,
            duration: (item is newpipe.StreamInfoItem && item.duration != null)
                ? Duration(seconds: item.duration!)
                : null,
            url: url,
          ),
        );
      }
    }

    for (final ch in result.channels) {
      processItem(ch, ch.url);
    }
    for (final pl in result.playlists) {
      processItem(pl, pl.url);
    }
    for (final song in result.videos) {
      processItem(song, song.url);
    }
    return mapped;
  }
}
