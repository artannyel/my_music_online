import '../models/play_log_model.dart';
import '../models/top_track_model.dart';

/// Contrato para operações com o histórico de reprodução do usuário.
abstract class HistoryRepository {
  Future<void> logPlay(String userId, PlayLogModel log);
  Future<List<PlayLogModel>> getRecentHistory(String userId, {int limit = 50});
  Future<List<TopTrackModel>> getTopTracks(String userId, {int limit = 20});
  Future<void> deletePlayLog(String userId, String logId);
  Future<List<TopTrackModel>> getMonthlyTopTracks(
    String userId,
    int month,
    int year, {int limit = 20});
}
