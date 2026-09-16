import 'dart:async';
import 'dart:io';
import 'package:extractor/extractor.dart';
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
  bool _isExtractorInitialized = false;

  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.arttecsoftware.my_music_online/media_scanner');

  AudioDownloaderService({http.Client? client}) : _client = client ?? http.Client();

  Future<bool> _initExtractor() async {
    if (!kIsWeb && Platform.isAndroid) {
      if (_isExtractorInitialized) return true;
      try {
        final isInit = await YoutubeDLFlutter.instance.isInitialized();
        if (!isInit) {
          final res = await YoutubeDLFlutter.instance.initialize(
            enableFFmpeg: true,
            enableAria2c: true,
          );
          _isExtractorInitialized = res.success;
          debugPrint('[AudioDownloaderService] YoutubeDL init status: ${res.success}, error: ${res.errorMessage}');
        } else {
          _isExtractorInitialized = true;
        }

        if (_isExtractorInitialized) {
          // Tenta atualizar o binary do yt-dlp de forma assíncrona
          YoutubeDLFlutter.instance.updateYoutubeDL().then((up) {
            debugPrint('[AudioDownloaderService] yt-dlp update status: ${up.status}, version: ${up.version}');
          }).catchError((e) {
            debugPrint('[AudioDownloaderService] Aviso ao atualizar yt-dlp: $e');
          });
        }
        return _isExtractorInitialized;
      } catch (e) {
        debugPrint('[AudioDownloaderService] Erro ao inicializar extractor: $e');
        return false;
      }
    }
    return false;
  }

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

  /// Retorna o diretório temporário de trabalho no armazenamento privado para downloads nativos.
  Future<Directory> _getTempDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final tempDir = Directory('${extDir.path}/TempDownloads');
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        return tempDir;
      }
    }
    final tempDir = await getTemporaryDirectory();
    return tempDir;
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

      // Limpa qualquer diretório ou arquivo corrompido pré-existente no caminho do arquivo final
      if (FileSystemEntity.typeSync(file.path) == FileSystemEntityType.directory) {
        debugPrint('[AudioDownloaderService] Removendo diretório corrompido residual: ${file.path}');
        await Directory(file.path).delete(recursive: true);
      }

      final useNativeExtractor = await _initExtractor();

      if (useNativeExtractor) {
        debugPrint('[AudioDownloaderService] Baixando via native extractor (yt-dlp + aria2c)...');
        bool nativeSuccess = false;
        try {
          final tempDir = await _getTempDirectory();
          final tempFile = File('${tempDir.path}/$fileName');

          if (FileSystemEntity.typeSync(tempFile.path) == FileSystemEntityType.directory) {
            await Directory(tempFile.path).delete(recursive: true);
          } else if (await tempFile.exists()) {
            await tempFile.delete();
          }

          final request = DownloadRequest(
            url: musicUrl,
            outputPath: tempDir.path,
            outputTemplate: '$sanitizedTitle - $sanitizedArtist.${format.extension}',
            format: 'bestaudio[ext=m4a]/bestaudio/best',
            embedThumbnail: true,
            embedMetadata: true,
            embedSubtitles: true,
            processId: taskId,
            customOptions: {
              '--extractor-args': 'youtube:player_client=android,web',
              '--user-agent':
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            },
          );

          final controller = StreamController<DownloadTaskModel>();

          final progressSub = YoutubeDLFlutter.instance.onProgress.listen((p) {
            if (p.processId == taskId) {
              currentTask = currentTask.copyWith(
                progress: p.progressFraction.clamp(0.0, 1.0),
                filePath: file.path,
              );
              if (!controller.isClosed) {
                controller.add(currentTask);
              }
            }
          });

          final errorSub = YoutubeDLFlutter.instance.onError.listen((err) {
            if (err.processId == taskId) {
              if (!controller.isClosed) {
                controller.addError(Exception(err.error));
              }
            }
          });

          final downloadFuture = YoutubeDLFlutter.instance.download(request).then((result) async {
            await progressSub.cancel();
            await errorSub.cancel();

            if (result.status != OperationStatus.success) {
              throw Exception(result.errorMessage ?? 'Falha no download via YoutubeDL (Status: ${result.status})');
            }

            var downloadedPath = result.outputPath ?? tempFile.path;
            var downloadedFile = File(downloadedPath);

            if (!downloadedFile.existsSync()) {
              downloadedFile = tempFile;
            }

            if (!downloadedFile.existsSync()) {
              throw Exception('Arquivo baixado não foi encontrado no caminho temporário: ${downloadedFile.path}');
            }

            // Copia o arquivo da pasta temporária privada para o diretório de destino público
            await downloadedFile.copy(file.path);
            try {
              await downloadedFile.delete();
            } catch (_) {}

            final fileSize = file.existsSync() ? file.lengthSync() : 0;

            await scanMediaFile(file.path);

            currentTask = currentTask.copyWith(
              progress: 1.0,
              status: DownloadStatus.completed,
              filePath: file.path,
              totalBytes: fileSize,
              downloadedBytes: fileSize,
            );
            if (!controller.isClosed) {
              controller.add(currentTask);
              await controller.close();
            }
          }).catchError((e, st) {
            progressSub.cancel();
            errorSub.cancel();
            if (!controller.isClosed) {
              controller.addError(e, st);
              controller.close();
            }
          });

          try {
            await for (final taskUpdate in controller.stream) {
              yield taskUpdate;
            }
            await downloadFuture;
            nativeSuccess = true;
            return;
          } catch (streamErr) {
            debugPrint('[AudioDownloaderService] Native extractor falhou na execução ($streamErr).');
          }
        } catch (nativeErr) {
          debugPrint('[AudioDownloaderService] Erro ao preparar native extractor ($nativeErr).');
        }

        if (!nativeSuccess) {
          debugPrint('[AudioDownloaderService] Executando fallback YtExtractor + HTTP...');
        }
      }

      // Fallback para HTTP stream caso o native extractor não esteja disponível ou falhe
      debugPrint('[AudioDownloaderService] Usando fallback YtExtractor + HTTP...');

      // Garante que não haja diretório residual no caminho antes de salvar via HTTP
      if (FileSystemEntity.typeSync(file.path) == FileSystemEntityType.directory) {
        await Directory(file.path).delete(recursive: true);
      }
      final extractor = YtExtractor();
      final info = await extractor.getStreamInfo(musicUrl);
      final audioStream = info.bestAudioStream;

      if (audioStream == null) {
        throw Exception('Stream de áudio não disponível para esta música.');
      }

      final request = http.Request('GET', Uri.parse(audioStream.url));
      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Referer': 'https://music.youtube.com/',
        'Origin': 'https://music.youtube.com',
        'Accept': '*/*',
        'Accept-Encoding': 'identity',
        'Connection': 'keep-alive',
      });
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Falha na resposta do servidor (HTTP ${response.statusCode})');
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;
      var lastYieldTimeMs = 0;
      var lastYieldProgress = -1.0;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        final progress = totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final shouldYield = progress == 1.0 ||
            (progress - lastYieldProgress).abs() >= 0.02 ||
            (nowMs - lastYieldTimeMs) >= 250;

        if (shouldYield) {
          lastYieldProgress = progress;
          lastYieldTimeMs = nowMs;
          currentTask = currentTask.copyWith(
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            filePath: file.path,
          );
          yield currentTask;
        }
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


