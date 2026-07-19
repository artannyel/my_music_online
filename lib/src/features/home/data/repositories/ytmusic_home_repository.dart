import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../domain/models/home_section_model.dart';
import '../../domain/repositories/home_repository.dart';

/// Implementação do HomeRepository consumindo a API dart_ytmusic_api
/// com dados dinâmicos e fallback elegante para visualização contínua.
class YtMusicHomeRepository implements HomeRepository {
  final YTMusic _ytMusic;

  YtMusicHomeRepository({YTMusic? ytMusic})
      : _ytMusic = ytMusic ?? YTMusic();

  @override
  Future<List<HomeSectionModel>> getHomeSections() async {
    try {
      await _ytMusic.initialize();
      
      final searchResults = await _ytMusic.search('Top Hits 2026');

      if (searchResults.isNotEmpty) {
        final items = <HomeItemModel>[];
        
        for (final res in searchResults.take(10)) {
          final dyn = res as dynamic;
          final String title = dyn.title?.toString() ?? dyn.name?.toString() ?? 'Música';
          final String id = dyn.videoId?.toString() ?? dyn.id?.toString() ?? title;
          final String artist = dyn.artist?.name?.toString() ?? dyn.artist?.toString() ?? 'Artistas em Destaque';
          
          String thumbnail = 'https://picsum.photos/300/300';
          if (dyn.thumbnails != null && dyn.thumbnails is List && dyn.thumbnails.isNotEmpty) {
            thumbnail = dyn.thumbnails.last.url?.toString() ?? thumbnail;
          }

          items.add(
            HomeItemModel(
              id: id,
              title: title,
              subtitle: artist,
              thumbnailUrl: thumbnail,
              type: HomeItemType.song,
            ),
          );
        }

        if (items.isNotEmpty) {
          return [
            HomeSectionModel(
              title: 'Sugestões para Você',
              items: items,
            ),
            HomeSectionModel(
              title: 'Mais Tocadas da Semana',
              items: items.reversed.toList(),
            ),
          ];
        }
      }
    } catch (_) {
      // Ignora e usa fallback em ambiente offline
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
            id: 'demo_2',
            title: 'Cyberpunk Odyssey',
            subtitle: 'Electronic Pulse',
            thumbnailUrl: 'https://picsum.photos/seed/music2/300/300',
            type: HomeItemType.song,
          ),
          HomeItemModel(
            id: 'demo_3',
            title: 'Acoustic Sunset',
            subtitle: 'Unplugged Vibes',
            thumbnailUrl: 'https://picsum.photos/seed/music3/300/300',
            type: HomeItemType.song,
          ),
        ],
      ),
      const HomeSectionModel(
        title: 'Mais Tocadas da Semana',
        items: [
          HomeItemModel(
            id: 'demo_4',
            title: 'Neon Nights',
            subtitle: 'Synthwave Remix',
            thumbnailUrl: 'https://picsum.photos/seed/music4/300/300',
            type: HomeItemType.song,
          ),
          HomeItemModel(
            id: 'demo_5',
            title: 'Deep House Flow',
            subtitle: 'Club Essentials',
            thumbnailUrl: 'https://picsum.photos/seed/music5/300/300',
            type: HomeItemType.song,
          ),
        ],
      ),
    ];
  }
}
