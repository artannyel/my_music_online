import '../models/download_task_model.dart';
import '../models/offline_track_model.dart';

/// Contract / Repositório de gerenciamento de downloads e biblioteca off-line.
abstract class DownloadRepository {
  /// Retorna a lista completa de músicas baixadas off-line.
  Future<List<OfflineTrackModel>> getOfflineTracks();

  /// Retorna uma faixa off-line pelo seu ID (ou null se não estiver baixada).
  Future<OfflineTrackModel?> getOfflineTrack(String trackId);

  /// Retorna true se a faixa especificada já foi baixada.
  Future<bool> isTrackDownloaded(String trackId);

  /// Salva o índice de uma nova faixa baixada off-line.
  Future<void> saveOfflineTrack(OfflineTrackModel track);

  /// Apaga o arquivo físico da faixa e remove-a da biblioteca off-line.
  Future<void> deleteOfflineTrack(String trackId);

  /// Apaga todas as músicas de uma playlist baixada e sua pasta.
  Future<void> deleteOfflinePlaylist(String playlistName);

  /// Retorna o tamanho total ocupado em bytes por todos os downloads.
  Future<int> getTotalStorageUsedBytes();

  /// Apaga todos os downloads e limpa o armazenamento local.
  Future<void> clearAllDownloads();

  /// Retorna o formato de áudio preferido para os downloads (`.m4a` ou `.mp3`).
  Future<AudioFormat> getPreferredAudioFormat();

  /// Define a preferência de formato de áudio para futuros downloads.
  Future<void> setPreferredAudioFormat(AudioFormat format);
}
