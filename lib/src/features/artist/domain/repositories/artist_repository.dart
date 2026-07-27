import '../models/artist_model.dart';
import '../../../../features/player/domain/models/player_state_model.dart';
import '../../../../features/album/domain/models/album_model.dart';

abstract class ArtistRepository {
  Future<ArtistModel?> getArtist(String artistId);
  Future<List<AudioTrackModel>> getArtistSongs(String artistId);
  Future<List<AlbumModel>> getArtistAlbums(String artistId);
  Future<List<AlbumModel>> getArtistSingles(String artistId);
}
