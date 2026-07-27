import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_playlist_repository.dart';
import '../../domain/models/playlist_model.dart';
import '../../domain/repositories/playlist_repository.dart';

/// Provider para a instância do repositório de Playlists.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return FirestorePlaylistRepository();
});

/// StreamProvider que escuta em tempo real as playlists do usuário.
final userPlaylistsStreamProvider = StreamProvider.family<List<PlaylistModel>, String>((ref, userId) {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.getUserPlaylists(userId);
});

/// Controller para gerenciar os detalhes da playlist e carregar mais faixas (Mix).
class PlaylistDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<PlaylistModel?, ({String id, String? url})> {
  @override
  FutureOr<PlaylistModel?> build(({String id, String? url}) arg) async {
    final repository = ref.watch(playlistRepositoryProvider);
    return repository.getPlaylistById(arg.id, arg.url);
  }

  /// Atualiza o estado local com novas faixas sem refazer a requisição ao Firestore.
  void updateTracks(List<PlaylistTrackModel> tracks) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(tracks: tracks));
    }
  }
}

final playlistDetailsProvider = AsyncNotifierProvider.autoDispose.family<PlaylistDetailsNotifier, PlaylistModel?, ({String id, String? url})>(() {
  return PlaylistDetailsNotifier();
});

/// Family FutureProvider para checar se uma playlist do YouTube está salva na biblioteca do usuário.
final isPlaylistSavedProvider = FutureProvider.family<bool, ({String userId, String playlistId})>((ref, arg) async {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.isPlaylistSaved(userId: arg.userId, playlistId: arg.playlistId);
});

/// Family FutureProvider para checar se um álbum está salvo na biblioteca do usuário.
final isAlbumSavedProvider = FutureProvider.family<bool, ({String userId, String albumId})>((ref, arg) async {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.isAlbumSaved(userId: arg.userId, albumId: arg.albumId);
});

/// Controller para mutações de playlist (Criar, Salvar do YT, Duplicar, Adicionar Músicas, Deletar).
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

  Future<bool> saveYtPlaylistToLibrary({
    required String userId,
    required PlaylistModel ytPlaylist,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.saveYtPlaylistToLibrary(userId: userId, ytPlaylist: ytPlaylist);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> unsaveYtPlaylistFromLibrary({
    required String userId,
    required String playlistId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.unsaveYtPlaylistFromLibrary(userId: userId, playlistId: playlistId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<PlaylistModel?> duplicatePlaylistAsCustom({
    required String userId,
    required PlaylistModel sourcePlaylist,
    String? customTitle,
    String? customDescription,
  }) async {
    state = const AsyncLoading();
    try {
      final customPlaylist = await _repository.duplicatePlaylistAsCustom(
        userId: userId,
        sourcePlaylist: sourcePlaylist,
        customTitle: customTitle,
        customDescription: customDescription,
      );
      state = const AsyncData(null);
      return customPlaylist;
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

  Future<bool> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updatePlaylist(
        playlistId: playlistId,
        title: title,
        description: description,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> reorderPlaylistTracks({
    required String playlistId,
    required List<PlaylistTrackModel> tracks,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.reorderPlaylistTracks(
        playlistId: playlistId,
        tracks: tracks,
      );
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

  Future<bool> saveAlbumToLibrary({
    required String userId,
    required AlbumSaveData album,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.saveAlbumToLibrary(userId: userId, album: album);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> unsaveAlbumFromLibrary({
    required String userId,
    required String albumId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.unsaveAlbumFromLibrary(userId: userId, albumId: albumId);
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
