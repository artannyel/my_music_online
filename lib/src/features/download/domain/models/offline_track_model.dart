import 'package:flutter/foundation.dart';
import '../../../player/domain/models/player_state_model.dart';
import 'download_task_model.dart';

/// Modelo imutável que representa uma faixa de áudio gravada no armazenamento local para reprodução off-line.
@immutable
class OfflineTrackModel {
  final String id;
  final String videoId;
  final String title;
  final String artistName;
  final String? albumName;
  final String? playlistName;
  final String? thumbnailUrl;
  final Duration? duration;
  final String localFilePath;
  final AudioFormat audioFormat;
  final DateTime downloadedAt;
  final int fileSizeBytes;

  const OfflineTrackModel({
    required this.id,
    required this.videoId,
    required this.title,
    required this.artistName,
    this.albumName,
    this.playlistName,
    this.thumbnailUrl,
    this.duration,
    required this.localFilePath,
    this.audioFormat = AudioFormat.m4a,
    required this.downloadedAt,
    required this.fileSizeBytes,
  });

  /// Converte a faixa off-line em um `AudioTrackModel` para reprodução direta no `PlayerController`.
  AudioTrackModel toAudioTrack() {
    return AudioTrackModel(
      id: id,
      videoId: videoId,
      title: title,
      artistName: artistName,
      albumName: albumName,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
    );
  }

  OfflineTrackModel copyWith({
    String? id,
    String? videoId,
    String? title,
    String? artistName,
    String? albumName,
    String? playlistName,
    String? thumbnailUrl,
    Duration? duration,
    String? localFilePath,
    AudioFormat? audioFormat,
    DateTime? downloadedAt,
    int? fileSizeBytes,
  }) {
    return OfflineTrackModel(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      playlistName: playlistName ?? this.playlistName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      localFilePath: localFilePath ?? this.localFilePath,
      audioFormat: audioFormat ?? this.audioFormat,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'artistName': artistName,
      'albumName': albumName,
      'playlistName': playlistName,
      'thumbnailUrl': thumbnailUrl,
      'durationMs': duration?.inMilliseconds,
      'localFilePath': localFilePath,
      'audioFormat': audioFormat.name,
      'downloadedAt': downloadedAt.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory OfflineTrackModel.fromJson(Map<String, dynamic> json) {
    return OfflineTrackModel(
      id: json['id'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String?,
      playlistName: json['playlistName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      localFilePath: json['localFilePath'] as String? ?? '',
      audioFormat: AudioFormat.values.firstWhere(
        (e) => e.name == json['audioFormat'],
        orElse: () => AudioFormat.m4a,
      ),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineTrackModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localFilePath == other.localFilePath;

  @override
  int get hashCode => id.hashCode ^ localFilePath.hashCode;
}
