import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/play_log_model.dart';
import '../../domain/models/top_track_model.dart';
import '../../domain/repositories/history_repository.dart';

/// Implementação do repositório de histórico usando Firebase Firestore.
class FirestoreHistoryRepository implements HistoryRepository {
  final FirebaseFirestore _firestore;

  FirestoreHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> logPlay(String userId, PlayLogModel log) async {
    final json = log.toJson();
    json['userId'] = userId;
    json['createdAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('play_history')
        .add(json);
  }

  @override
  Future<List<PlayLogModel>> getRecentHistory(
      String userId, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('play_history')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return PlayLogModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> deletePlayLog(String userId, String logId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('play_history')
        .doc(logId)
        .delete();
  }

  @override
  Future<List<TopTrackModel>> getTopTracks(
      String userId, {int limit = 20}) async {
    // Agrupa por trackId e conta as ocorrências localmente
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('play_history')
        .get();

    final Map<String, int> playCounts = {};
    final Map<String, String> trackTitles = {};
    final Map<String, String> trackArtists = {};
    final Map<String, Duration> trackDurations = {};
    final Map<String, String> trackThumbnails = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final trackId = data['trackId'] as String?;
      final title = data['title'] as String?;
      final artistName = data['artistName'] as String?;
      final duration = data['duration'] as int?;
      final thumbnailUrl = data['thumbnailUrl'] as String?;

      if (trackId != null) {
        playCounts[trackId] = (playCounts[trackId] ?? 0) + 1;
        if (title != null && !trackTitles.containsKey(trackId)) {
          trackTitles[trackId] = title;
        }
        if (artistName != null && !trackArtists.containsKey(trackId)) {
          trackArtists[trackId] = artistName;
        }
        if (duration != null && trackDurations[trackId] == null) {
          trackDurations[trackId] = Duration(seconds: duration);
        }
        if (thumbnailUrl != null && !trackThumbnails.containsKey(trackId)) {
          trackThumbnails[trackId] = thumbnailUrl;
        }
      }
    }

    // Converter para TopTrackModel ordenado por playCount decrescente
    final rankedTracks = playCounts.entries
        .map((e) => TopTrackModel(
              id: e.key,
              title: trackTitles[e.key] ?? '',
              artistName: trackArtists[e.key] ?? '',
              playCount: e.value,
              thumbnailUrl: trackThumbnails[e.key],
            ))
        .toList()
      ..sort((a, b) {
          final countA = a.playCount ?? 0;
          final countB = b.playCount ?? 0;
          return countB.compareTo(countA);
        });

    return rankedTracks.take(limit).toList();
  }

  @override
  Future<List<TopTrackModel>> getMonthlyTopTracks(
      String userId, int month, int year, {int limit = 20}) async {
    // Agrupa por mês e conta as ocorrências localmente
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('play_history')
        .get();

    final Map<String, int> playCounts = {};
    final Map<String, String> trackTitles = {};
    final Map<String, String> trackArtists = {};
    final Map<String, Duration> trackDurations = {};
    final Map<String, String> trackThumbnails = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt == null) continue;
      final dt = createdAt.toDate();
      if (dt.month == month && dt.year == year) {
        final trackId = data['trackId'] as String?;
        final title = data['title'] as String?;
        final artistName = data['artistName'] as String?;
        final duration = data['duration'] as int?;
        final thumbnailUrl = data['thumbnailUrl'] as String?;

        if (trackId != null) {
          playCounts[trackId] = (playCounts[trackId] ?? 0) + 1;
          if (title != null && !trackTitles.containsKey(trackId)) {
            trackTitles[trackId] = title;
          }
          if (artistName != null && !trackArtists.containsKey(trackId)) {
            trackArtists[trackId] = artistName;
          }
          if (duration != null && trackDurations[trackId] == null) {
            trackDurations[trackId] = Duration(seconds: duration);
          }
          if (thumbnailUrl != null && !trackThumbnails.containsKey(trackId)) {
            trackThumbnails[trackId] = thumbnailUrl;
          }
        }
      }
    }

    // Converter para TopTrackModel ordenado por playCount decrescente
    final rankedTracks = playCounts.entries
        .map((e) => TopTrackModel(
              id: e.key,
              title: trackTitles[e.key] ?? '',
              artistName: trackArtists[e.key] ?? '',
              playCount: e.value,
              thumbnailUrl: trackThumbnails[e.key],
            ))
        .toList()
      ..sort((a, b) {
          final countA = a.playCount ?? 0;
          final countB = b.playCount ?? 0;
          return countB.compareTo(countA);
        });

    return rankedTracks.take(limit).toList();
  }
}