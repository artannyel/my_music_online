import '../models/playlist_model.dart';

/// Contrato para operações com Playlists (Firestore & YTMusic).
abstract class PlaylistRepository {
  /// Obtém a lista de playlists do usuário salvas no Firestore.
  Stream<List<PlaylistModel>> getUserPlaylists(String userId);

  /// Obtém os detalhes completos de uma playlist pelo ID (Firestore ou YTMusic).
  Future<PlaylistModel?> getPlaylistById(String playlistId);

  /// Cria uma nova playlist personalizada no Firestore (requer autenticação).
  Future<PlaylistModel> createPlaylist({
    required String userId,
    required String title,
    String? description,
  });

  /// Salva uma referência de playlist do YouTube na biblioteca do usuário no Firestore.
  Future<void> saveYtPlaylistToLibrary({
    required String userId,
    required PlaylistModel ytPlaylist,
  });

  /// Remove uma referência de playlist do YouTube da biblioteca do usuário.
  Future<void> unsaveYtPlaylistFromLibrary({
    required String userId,
    required String playlistId,
  });

  /// Duplica qualquer playlist (do YouTube ou de outro usuário) como uma cópia editável personalizada no Firestore.
  Future<PlaylistModel> duplicatePlaylistAsCustom({
    required String userId,
    required PlaylistModel sourcePlaylist,
  });

  /// Verifica se uma playlist do YouTube está salva na biblioteca do usuário.
  Future<bool> isPlaylistSaved({
    required String userId,
    required String playlistId,
  });

  /// Adiciona uma faixa a uma playlist personalizada do usuário no Firestore.
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required PlaylistTrackModel track,
  });

  /// Remove uma faixa de uma playlist personalizada no Firestore.
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  /// Exclui uma playlist do usuário no Firestore.
  Future<void> deletePlaylist(String playlistId);
}
