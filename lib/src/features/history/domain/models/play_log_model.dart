import 'package:cloud_firestore/cloud_firestore.dart';
class PlayLogModel {
  final String id;
  final String userId;
  final String trackId;
  final String title;
  final String artistName;
  final String? albumName;
  final String? thumbnailUrl;
  final String videoId;
  final Duration? duration;
  final DateTime playedAt;

  const PlayLogModel({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.title,
    required this.artistName,
    this.albumName,
    this.thumbnailUrl,
    required this.videoId,
    this.duration,
    required this.playedAt,
  });

  factory PlayLogModel.fromJson(Map<String, dynamic> json) {
    final playedAtValue = json['playedAt'];
    final createdAtValue = json['createdAt'];

    DateTime? playedAt;
    if (playedAtValue is DateTime) {
      playedAt = playedAtValue;
    } else if (playedAtValue is String) {
      playedAt = DateTime.tryParse(playedAtValue);
    } else if (playedAtValue is Timestamp) {
      playedAt = playedAtValue.toDate();
    } else if (createdAtValue is Timestamp) {
      playedAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      playedAt = DateTime.tryParse(createdAtValue);
    }

    return PlayLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      trackId: json['trackId'] as String? ?? json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoId: json['videoId'] as String? ?? json['trackId'] as String? ?? '',
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      playedAt: playedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'trackId': trackId,
      'title': title,
      'artistName': artistName,
      'albumName': albumName,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'duration': duration?.inSeconds,
      'playedAt': playedAt.toIso8601String(),
    };
  }
}