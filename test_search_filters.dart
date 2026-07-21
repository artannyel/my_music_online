import 'package:newpipeextractor_dart/newpipeextractor_dart.dart' as newpipe;

void main() async {
  await newpipe.LocalizationExtractor.setLocalization('pt-BR', 'BR');
  
  print('--- ALBUMS ---');
  final albums = await newpipe.SearchExtractor.searchYoutubeMusic(
    'Metallica',
    [newpipe.SearchFilter.musicAlbums.value],
  );
  print('videos: ${albums.result.videos.length}');
  print('playlists: ${albums.result.playlists.length}');
  print('channels: ${albums.result.channels.length}');
  if (albums.result.playlists.isNotEmpty) {
    print('First playlist: ${albums.result.playlists.first.name} - ${albums.result.playlists.first.url}');
  }

  print('\n--- ARTISTS ---');
  final artists = await newpipe.SearchExtractor.searchYoutubeMusic(
    'Metallica',
    [newpipe.SearchFilter.musicArtists.value],
  );
  print('videos: ${artists.result.videos.length}');
  print('playlists: ${artists.result.playlists.length}');
  print('channels: ${artists.result.channels.length}');
  if (artists.result.channels.isNotEmpty) {
    print('First channel: ${artists.result.channels.first.name} - ${artists.result.channels.first.url}');
  }
}
