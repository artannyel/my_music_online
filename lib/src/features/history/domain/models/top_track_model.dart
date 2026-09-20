/// Modelo que representa um item do ranking de tocos (Top Tracks).
class TopTrackModel {
  final String id;
  final String title;
  final String artistName;
  final Duration? duration;
  final int? playCount;
  final String? thumbnailUrl;

  const TopTrackModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.duration,
    this.playCount,
    this.thumbnailUrl,
  });

  factory TopTrackModel.fromJson(Map<String, dynamic> json) {
    return TopTrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      playCount: json['playCount'] as int?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'duration': duration?.inSeconds,
      'playCount': playCount,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
