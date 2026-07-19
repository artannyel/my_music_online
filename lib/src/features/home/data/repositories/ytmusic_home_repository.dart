import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../domain/models/home_section_model.dart';
import '../../domain/repositories/home_repository.dart';

/// Implementação do HomeRepository padronizado que consome getHomeSections() da API dart_ytmusic_api
/// configurado para o Brasil (GL=BR, HL=pt-BR), identificando cada item por seu tipo (Song, Playlist, Album, Artist).
class YtMusicHomeRepository implements HomeRepository {
  final YTMusic _ytMusic;

  YtMusicHomeRepository({YTMusic? ytMusic})
      : _ytMusic = ytMusic ?? YTMusic();

  @override
  Future<List<HomeSectionModel>> getHomeSections() async {
    try {
      // Inicializa a API configurada para o mercado brasileiro e idioma pt-BR
      await _ytMusic.initialize(gl: 'BR', hl: 'pt-BR');
      
      final List<HomeSection> rawSections = await _ytMusic.getHomeSections();

      if (rawSections.isNotEmpty) {
        final sections = <HomeSectionModel>[];

        for (final rawSection in rawSections) {
          final String sectionTitle = rawSection.title.isNotEmpty ? rawSection.title : 'Destaques';
          final List<dynamic> rawContents = rawSection.contents;

          if (rawContents.isNotEmpty) {
            final items = <HomeItemModel>[];

            for (final rawItem in rawContents) {
              HomeItemModel? item;

              if (rawItem is SongDetailed) {
                item = HomeItemModel(
                  id: rawItem.videoId,
                  title: rawItem.name,
                  subtitle: rawItem.artist.name,
                  thumbnailUrl: rawItem.thumbnails.isNotEmpty ? rawItem.thumbnails.last.url : 'https://picsum.photos/300/300',
                  type: HomeItemType.song,
                  artistId: rawItem.artist.artistId,
                  albumId: rawItem.album?.albumId,
                  duration: rawItem.duration != null ? Duration(seconds: rawItem.duration!) : null,
                );
              } else if (rawItem is AlbumDetailed) {
                item = HomeItemModel(
                  id: rawItem.albumId,
                  title: rawItem.name,
                  subtitle: rawItem.artist.name.isNotEmpty ? rawItem.artist.name : 'Álbum',
                  thumbnailUrl: rawItem.thumbnails.isNotEmpty ? rawItem.thumbnails.last.url : 'https://picsum.photos/300/300',
                  type: HomeItemType.album,
                  artistId: rawItem.artist.artistId,
                  albumId: rawItem.albumId,
                );
              } else if (rawItem is ArtistDetailed) {
                item = HomeItemModel(
                  id: rawItem.artistId,
                  title: rawItem.name,
                  subtitle: 'Artista',
                  thumbnailUrl: rawItem.thumbnails.isNotEmpty ? rawItem.thumbnails.last.url : 'https://picsum.photos/300/300',
                  type: HomeItemType.artist,
                  artistId: rawItem.artistId,
                );
              } else if (rawItem is PlaylistDetailed) {
                item = HomeItemModel(
                  id: rawItem.playlistId,
                  title: rawItem.name,
                  subtitle: 'Playlist',
                  thumbnailUrl: rawItem.thumbnails.isNotEmpty ? rawItem.thumbnails.last.url : 'https://picsum.photos/300/300',
                  type: HomeItemType.playlist,
                );
              } else {
                final dyn = rawItem as dynamic;
                final String name = dyn.name?.toString() ?? dyn.title?.toString() ?? '';
                if (name.isNotEmpty) {
                  final String id = dyn.videoId?.toString() ?? dyn.playlistId?.toString() ?? dyn.albumId?.toString() ?? dyn.artistId?.toString() ?? name;
                  final String subtitle = dyn.artist?.name?.toString() ?? dyn.subtitle?.toString() ?? 'Música';
                  String thumbnail = 'https://picsum.photos/300/300';
                  if (dyn.thumbnails != null && dyn.thumbnails is List && (dyn.thumbnails as List).isNotEmpty) {
                    thumbnail = (dyn.thumbnails as List).last.url?.toString() ?? thumbnail;
                  }

                  HomeItemType itemType = HomeItemType.song;
                  if (dyn.playlistId != null) {
                    itemType = HomeItemType.playlist;
                  } else if (dyn.albumId != null) {
                    itemType = HomeItemType.album;
                  } else if (dyn.artistId != null) {
                    itemType = HomeItemType.artist;
                  }

                  item = HomeItemModel(
                    id: id,
                    title: name,
                    subtitle: subtitle,
                    thumbnailUrl: thumbnail,
                    type: itemType,
                  );
                }
              }

              if (item != null) {
                items.add(item);
              }
            }

            if (items.isNotEmpty) {
              sections.add(
                HomeSectionModel(
                  title: sectionTitle,
                  items: items,
                ),
              );
            }
          }
        }

        if (sections.isNotEmpty) {
          return sections;
        }
      }
    } catch (_) {
      // Ignora erro de rede e recorre ao fallback visual
    }

    return _getFallbackSections();
  }

  List<HomeSectionModel> _getFallbackSections() {
    return [
      const HomeSectionModel(
        title: 'Sugestões para Você',
        items: [
          HomeItemModel(
            id: 'demo_1',
            title: 'Midnight Beats',
            subtitle: 'Lo-Fi Chill & Synth',
            thumbnailUrl: 'https://picsum.photos/seed/music1/300/300',
            type: HomeItemType.song,
          ),
          HomeItemModel(
            id: 'demo_playlist_1',
            title: 'Top Brasil 2026',
            subtitle: 'Playlist Recomendada',
            thumbnailUrl: 'https://picsum.photos/seed/playlist1/300/300',
            type: HomeItemType.playlist,
          ),
          HomeItemModel(
            id: 'demo_2',
            title: 'Cyberpunk Odyssey',
            subtitle: 'Electronic Pulse',
            thumbnailUrl: 'https://picsum.photos/seed/music2/300/300',
            type: HomeItemType.song,
          ),
        ],
      ),
      const HomeSectionModel(
        title: 'Playlists e Álbuns em Destaque',
        items: [
          HomeItemModel(
            id: 'demo_playlist_2',
            title: 'Hits Internacionais',
            subtitle: 'Playlist',
            thumbnailUrl: 'https://picsum.photos/seed/playlist2/300/300',
            type: HomeItemType.playlist,
          ),
          HomeItemModel(
            id: 'demo_album_1',
            title: 'Starboy Deluxe',
            subtitle: 'Álbum',
            thumbnailUrl: 'https://picsum.photos/seed/album1/300/300',
            type: HomeItemType.album,
          ),
        ],
      ),
    ];
  }
}
