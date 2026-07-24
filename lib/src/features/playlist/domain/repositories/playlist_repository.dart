import '../models/playlist_model.dart';

/// Contrato para operações com Playlists (Firestore & YTMusic).
abstract class PlaylistRepository {
  /// Obtém a lista de playlists do usuário salvas no Firestore.
  Stream<List<PlaylistModel>> getUserPlaylists(String userId);

  /// Obtém os detalhes completos de uma playlist pelo ID (Firestore ou YTMusic).
  Future<PlaylistModel?> getPlaylistById(String playlistId, [String? url]);

  /// Carrega a próxima página de um Mix infinito.
  Future<({List<PlaylistTrackModel> tracks, String? nextPageUrl})> getMixNextPage(String url, String serializedToken);

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
    String? customTitle,
    String? customDescription,
  });

  /// Verifica se uma playlist do YouTube está salva na biblioteca do usuário.
  Future<bool> isPlaylistSaved({
    required String userId,
    required String playlistId,
  });

  /// Salva um álbum na biblioteca do usuário no Firestore (tipo album, somente-leitura).
  Future<void> saveAlbumToLibrary({
    required String userId,
    required AlbumSaveData album,
  });

  /// Remove um álbum salvo da biblioteca do usuário.
  Future<void> unsaveAlbumFromLibrary({
    required String userId,
    required String albumId,
  });

  /// Verifica se um álbum está salvo na biblioteca do usuário.
  Future<bool> isAlbumSaved({
    required String userId,
    required String albumId,
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

  /// Atualiza os metadados de uma playlist (título, descrição).
  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
  });

  /// Reordena as faixas de uma playlist personalizada.
  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<PlaylistTrackModel> tracks,
  });

  /// Exclui uma playlist do usuário no Firestore.
  Future<void> deletePlaylist(String playlistId);
}
