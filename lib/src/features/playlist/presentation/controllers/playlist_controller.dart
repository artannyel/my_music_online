import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_playlist_repository.dart';
import '../../domain/models/playlist_model.dart';
import '../../domain/repositories/playlist_repository.dart';

/// Provider para a instância do repositório de Playlists.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return FirestorePlaylistRepository();
});

/// StreamProvider que escuta em tempo real as playlists do usuário (passado userId).
final userPlaylistsStreamProvider = StreamProvider.family<List<PlaylistModel>, String>((ref, userId) {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.getUserPlaylists(userId);
});

/// Family FutureProvider que carrega os detalhes e faixas de uma playlist pelo ID.
final playlistDetailsProvider = FutureProvider.family<PlaylistModel?, String>((ref, playlistId) async {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.getPlaylistById(playlistId);
});

/// StateNotifier/Controller para mutações de playlist (Criar, Adicionar Músicas, Deletar).
class PlaylistMutationsNotifier extends StateNotifier<AsyncValue<void>> {
  final PlaylistRepository _repository;

  PlaylistMutationsNotifier(this._repository) : super(const AsyncData(null));

  Future<PlaylistModel?> createPlaylist({
    required String userId,
    required String title,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      final playlist = await _repository.createPlaylist(
        userId: userId,
        title: title,
        description: description,
      );
      state = const AsyncData(null);
      return playlist;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required PlaylistTrackModel track,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.addTrackToPlaylist(playlistId: playlistId, track: track);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.removeTrackFromPlaylist(playlistId: playlistId, trackId: trackId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    state = const AsyncLoading();
    try {
      await _repository.deletePlaylist(playlistId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final playlistMutationsProvider = StateNotifierProvider<PlaylistMutationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return PlaylistMutationsNotifier(repository);
});
