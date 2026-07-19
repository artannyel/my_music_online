import 'models/playlist_model.dart';

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

  /// Adiciona uma faixa a uma playlist existente no Firestore.
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required PlaylistTrackModel track,
  });

  /// Remove uma faixa de uma playlist no Firestore.
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  /// Exclui uma playlist do usuário no Firestore.
  Future<void> deletePlaylist(String playlistId);
}
