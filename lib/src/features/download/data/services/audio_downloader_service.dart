import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:yt_extractor/yt_extractor.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../domain/models/download_task_model.dart';
import '../../domain/models/offline_track_model.dart';

/// Serviço para extração de stream e salvamento físico dos áudios no sistema de arquivos.
class AudioDownloaderService {
  final http.Client _client;

  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.arttecsoftware.my_music_online/media_scanner');

  AudioDownloaderService({http.Client? client}) : _client = client ?? http.Client();

  /// Sanitiza o nome de arquivos e pastas para remover caracteres inválidos do sistema de arquivos.
  static String sanitizeName(String input) {
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Retorna o diretório base público para gravação de arquivos de música.
  Future<Directory> _getBaseDirectory({String? playlistName}) async {
    Directory baseDir;

    if (!kIsWeb && Platform.isAndroid) {
      // Tenta utilizar o diretório público de Música no armazenamento interno do Android
      final publicMusicDir = Directory('/storage/emulated/0/Music/MyMusicOnline');
      try {
        if (!await publicMusicDir.exists()) {
          await publicMusicDir.create(recursive: true);
        }
        baseDir = publicMusicDir;
      } catch (e) {
        debugPrint('[AudioDownloaderService] Aviso: Diretório público inacessível, usando armazenamento estendido: $e');
        final extDir = await getExternalStorageDirectory();
        baseDir = Directory('${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/Music/MyMusicOnline');
      }
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      baseDir = Directory('${appDir.path}/Music/MyMusicOnline');
    }

    if (playlistName != null && playlistName.trim().isNotEmpty) {
      final folderName = sanitizeName(playlistName);
      final playlistDir = Directory('${baseDir.path}/$folderName');
      if (!await playlistDir.exists()) {
        await playlistDir.create(recursive: true);
      }
      return playlistDir;
    } else {
      final downloadsDir = Directory('${baseDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    }
  }

  /// Notifica o MediaScanner do sistema Android para indexar o novo arquivo de música.
  Future<void> scanMediaFile(String filePath) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _mediaScannerChannel.invokeMethod('scanFile', {'path': filePath});
        debugPrint('[AudioDownloaderService] MediaScanner notificado para: $filePath');
      } catch (e) {
        debugPrint('[AudioDownloaderService] Erro ao notificar MediaScanner: $e');
      }
    }
  }

  /// Realiza o download de uma faixa de áudio emitindo atualizações de progresso.
  Stream<DownloadTaskModel> downloadTrack({
    required AudioTrackModel track,
    String? playlistName,
    AudioFormat format = AudioFormat.m4a,
  }) async* {
    final taskId = 'download_${track.id}_${DateTime.now().millisecondsSinceEpoch}';
    final sanitizedTitle = sanitizeName(track.title);
    final sanitizedArtist = sanitizeName(track.artistName);
    final fileName = '$sanitizedTitle - $sanitizedArtist.${format.extension}';

    var currentTask = DownloadTaskModel(
      id: taskId,
      trackId: track.id,
      title: track.title,
      artistName: track.artistName,
      playlistName: playlistName,
      thumbnailUrl: track.thumbnailUrl,
      progress: 0.0,
      status: DownloadStatus.downloading,
      audioFormat: format,
    );

    yield currentTask;

    try {
      final targetDir = await _getBaseDirectory(playlistName: playlistName);
      debugPrint('[AudioDownloaderService] --- Target directory: ${targetDir.path} ---');
      final file = File('${targetDir.path}/$fileName');

      final musicUrl = 'https://youtube.com/watch?v=${track.videoId}';
      final extractor = YtExtractor();
      final info = await extractor.getStreamInfo(musicUrl);
      final audioStream = info.bestAudioStream;

      if (audioStream == null) {
        throw Exception('Stream de áudio não disponível para esta música.');
      }

      final request = http.Request('GET', Uri.parse(audioStream.url));
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Falha na resposta do servidor (HTTP ${response.statusCode})');
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        final progress = totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

        currentTask = currentTask.copyWith(
          progress: progress,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          filePath: file.path,
        );
        yield currentTask;
      }

      await sink.flush();
      await sink.close();

      // Notifica o MediaScanner do sistema Android
      await scanMediaFile(file.path);

      currentTask = currentTask.copyWith(
        progress: 1.0,
        status: DownloadStatus.completed,
        filePath: file.path,
      );
      yield currentTask;
    } catch (e, st) {
      debugPrint('[AudioDownloaderService] Erro ao baixar faixa: $e\n$st');
      currentTask = currentTask.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      yield currentTask;
    }
  }

  /// Converte uma tarefa concluída com sucesso em `OfflineTrackModel`.
  OfflineTrackModel createOfflineTrack({
    required AudioTrackModel track,
    required DownloadTaskModel completedTask,
  }) {
    final file = File(completedTask.filePath ?? '');
    final fileSizeBytes = file.existsSync() ? file.lengthSync() : completedTask.totalBytes;

    return OfflineTrackModel(
      id: track.id,
      videoId: track.videoId,
      title: track.title,
      artistName: track.artistName,
      albumName: track.albumName,
      playlistName: completedTask.playlistName,
      thumbnailUrl: track.thumbnailUrl,
      duration: track.duration,
      localFilePath: completedTask.filePath ?? '',
      audioFormat: completedTask.audioFormat,
      downloadedAt: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
    );
  }
}
