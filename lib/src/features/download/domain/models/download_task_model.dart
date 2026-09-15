import 'package:flutter/foundation.dart';

/// Status do ciclo de vida de um download.
enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
}

/// Formato de gravação do áudio.
enum AudioFormat {
  m4a,
  mp3,
}

extension AudioFormatExtension on AudioFormat {
  String get extension => this == AudioFormat.mp3 ? 'mp3' : 'm4a';
  String get label => this == AudioFormat.mp3 ? 'MP3 Universal' : 'M4A (AAC Rápido)';
}

/// Modelo imutável que representa uma tarefa de download ativa ou pendente.
@immutable
class DownloadTaskModel {
  final String id;
  final String trackId;
  final String title;
  final String artistName;
  final String? playlistName;
  final String? thumbnailUrl;
  final double progress; // 0.0 a 1.0
  final DownloadStatus status;
  final AudioFormat audioFormat;
  final String? filePath;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  const DownloadTaskModel({
    required this.id,
    required this.trackId,
    required this.title,
    required this.artistName,
    this.playlistName,
    this.thumbnailUrl,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    this.audioFormat = AudioFormat.m4a,
    this.filePath,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  DownloadTaskModel copyWith({
    String? id,
    String? trackId,
    String? title,
    String? artistName,
    String? playlistName,
    String? thumbnailUrl,
    double? progress,
    DownloadStatus? status,
    AudioFormat? audioFormat,
    String? filePath,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadTaskModel(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      playlistName: playlistName ?? this.playlistName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      audioFormat: audioFormat ?? this.audioFormat,
      filePath: filePath ?? this.filePath,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'title': title,
      'artistName': artistName,
      'playlistName': playlistName,
      'thumbnailUrl': thumbnailUrl,
      'progress': progress,
      'status': status.name,
      'audioFormat': audioFormat.name,
      'filePath': filePath,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'errorMessage': errorMessage,
    };
  }

  factory DownloadTaskModel.fromJson(Map<String, dynamic> json) {
    return DownloadTaskModel(
      id: json['id'] as String? ?? '',
      trackId: json['trackId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      playlistName: json['playlistName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.pending,
      ),
      audioFormat: AudioFormat.values.firstWhere(
        (e) => e.name == json['audioFormat'],
        orElse: () => AudioFormat.m4a,
      ),
      filePath: json['filePath'] as String?,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          trackId == other.trackId &&
          progress == other.progress &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ trackId.hashCode ^ progress.hashCode ^ status.hashCode;
}
