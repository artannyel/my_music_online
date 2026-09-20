import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_history_repository.dart';
import '../../domain/models/play_log_model.dart';
import '../../domain/models/top_track_model.dart';
import '../../domain/repositories/history_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider para a instância do repositório de histórico.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return FirestoreHistoryRepository(
    firestore: FirebaseFirestore.instance,
  );
});

/// Controller para gerenciar o histórico de reprodução e os rankings.
class HistoryController extends StateNotifier<AsyncValue<void>> {
  final HistoryRepository _repository;

  HistoryController(this._repository) : super(const AsyncData(null));

  /// Registra uma reprodução no histórico do usuário.
  Future<void> logPlay(String userId, PlayLogModel log) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.logPlay(userId, log));
  }

  /// Obtém o histórico recente do usuário.
  Future<List<PlayLogModel>> getRecentHistory(String userId, {int limit = 50}) async {
    return _repository.getRecentHistory(userId, limit: limit);
  }

  /// Obtém os Top Tracks do usuário.
  Future<List<TopTrackModel>> getTopTracks(String userId, {int limit = 20}) async {
    return _repository.getTopTracks(userId, limit: limit);
  }

  /// Obtém os Top Tracks do mês atual.
  Future<List<TopTrackModel>> getMonthlyTopTracks(
      String userId, int month, int year, {int limit = 20}) async {
    return _repository.getMonthlyTopTracks(userId, month, year, limit: limit);
  }
}

final historyControllerProvider =
    StateNotifierProvider<HistoryController, AsyncValue<void>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryController(repository);
});

/// Provider que expõe o histórico recente para a HomeScreen.
final recentHistoryProvider = FutureProvider.family<List<PlayLogModel>, String>((ref, userId) {
  final controller = ref.watch(historyControllerProvider.notifier);
  return controller.getRecentHistory(userId);
});

/// Provider que expõe os Top Tracks para a HomeScreen.
final topTracksProvider = FutureProvider.family<List<TopTrackModel>, String>((ref, userId) {
  final controller = ref.watch(historyControllerProvider.notifier);
  return controller.getTopTracks(userId);
});