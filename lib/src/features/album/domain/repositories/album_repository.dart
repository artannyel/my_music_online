import '../models/album_model.dart';

/// Contrato do repositório para obtenção de dados de Álbuns
abstract class AlbumRepository {
  /// Obtém os detalhes completos de um Álbum pelo seu ID
  Future<AlbumModel?> getAlbumDetails(String albumId);
}
