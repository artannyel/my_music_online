import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/artist_model.dart';
import '../../domain/repositories/artist_repository.dart';
import '../../data/repositories/ytmusic_artist_repository.dart';
import '../../../../features/player/domain/models/player_state_model.dart';
import '../../../../features/album/domain/models/album_model.dart';

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return YtMusicArtistRepository();
});

class ArtistDetailsNotifier extends AutoDisposeAsyncNotifier<ArtistModel?> {
  @override
  FutureOr<ArtistModel?> build() {
    return null;
  }

  Future<void> fetchArtist(String artistId) async {
    state = const AsyncLoading();
    final repository = ref.read(artistRepositoryProvider);
    try {
      final artist = await repository.getArtist(artistId);
      state = AsyncData(artist);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final artistDetailsProvider = AsyncNotifierProvider.autoDispose<ArtistDetailsNotifier, ArtistModel?>(() {
  return ArtistDetailsNotifier();
});

final artistSongsProvider = FutureProvider.autoDispose.family<List<AudioTrackModel>, String>((ref, artistId) async {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.getArtistSongs(artistId);
});

final artistAlbumsProvider = FutureProvider.autoDispose.family<List<AlbumModel>, String>((ref, artistId) async {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.getArtistAlbums(artistId);
});

final artistSinglesProvider = FutureProvider.autoDispose.family<List<AlbumModel>, String>((ref, artistId) async {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.getArtistSingles(artistId);
});
