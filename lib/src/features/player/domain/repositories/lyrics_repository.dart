import '../models/lyrics_model.dart';

/// Interface do repositório responsável por recuperar letras de músicas.
abstract class LyricsRepository {
  /// Obtém as letras (sincronizadas ou estáticas) a partir do [videoId] da música.
  /// Retorna `null` se nenhuma letra estiver disponível.
  Future<LyricsModel?> getLyrics(String videoId);
}
