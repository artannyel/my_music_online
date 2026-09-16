import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_music_online/src/features/download/domain/models/download_task_model.dart';
import 'package:my_music_online/src/features/download/domain/models/offline_track_model.dart';
import 'package:my_music_online/src/features/download/data/repositories/local_download_repository.dart';
import 'package:my_music_online/src/features/download/data/services/audio_downloader_service.dart';
import 'package:my_music_online/src/features/download/presentation/controllers/download_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadTaskModel & Formats Tests', () {
    test('AudioFormat extensions', () {
      expect(AudioFormat.m4a.extension, 'm4a');
      expect(AudioFormat.mp3.extension, 'mp3');
      expect(AudioFormat.m4a.label, contains('M4A'));
      expect(AudioFormat.mp3.label, contains('MP3'));
    });

    test('DownloadTaskModel serialization', () {
      final task = DownloadTaskModel(
        id: 'task_1',
        trackId: 'track_123',
        title: 'Test Song',
        artistName: 'Test Artist',
        playlistName: 'Rock Classics',
        audioFormat: AudioFormat.mp3,
        progress: 0.5,
        status: DownloadStatus.downloading,
      );

      final jsonMap = task.toJson();
      final restored = DownloadTaskModel.fromJson(jsonMap);

      expect(restored.id, 'task_1');
      expect(restored.trackId, 'track_123');
      expect(restored.playlistName, 'Rock Classics');
      expect(restored.audioFormat, AudioFormat.mp3);
      expect(restored.progress, 0.5);
    });
  });

  group('OfflineTrackModel Tests', () {
    test('OfflineTrackModel toAudioTrack conversion', () {
      final offline = OfflineTrackModel(
        id: '123',
        videoId: 'vid_123',
        title: 'Offline Song',
        artistName: 'Offline Artist',
        playlistName: 'Minhas Favoritas',
        localFilePath: '/path/to/file.m4a',
        downloadedAt: DateTime.now(),
        fileSizeBytes: 5000000,
      );

      final audioTrack = offline.toAudioTrack();
      expect(audioTrack.id, '123');
      expect(audioTrack.videoId, 'vid_123');
      expect(audioTrack.title, 'Offline Song');
      expect(audioTrack.artistName, 'Offline Artist');
    });
  });

  group('AudioDownloaderService Tests', () {
    test('sanitizeName remove caracteres inválidos de arquivos e pastas', () {
      final rawName = 'Rock / Metal : Part 1 * (Special? "Edition") <V2>';
      final sanitized = AudioDownloaderService.sanitizeName(rawName);

      expect(sanitized.contains('/'), isFalse);
      expect(sanitized.contains(':'), isFalse);
      expect(sanitized.contains('*'), isFalse);
      expect(sanitized.contains('?'), isFalse);
      expect(sanitized.contains('"'), isFalse);
      expect(sanitized.contains('<'), isFalse);
      expect(sanitized.contains('>'), isFalse);
    });
  });

  group('LocalDownloadRepository Tests', () {
    test('getPreferredAudioFormat e setPreferredAudioFormat', () async {
      final repo = LocalDownloadRepository();
      expect(await repo.getPreferredAudioFormat(), AudioFormat.m4a);

      await repo.setPreferredAudioFormat(AudioFormat.mp3);
      expect(await repo.getPreferredAudioFormat(), AudioFormat.mp3);
    });

    test('saveActiveQueue e getActiveQueue persistem fila em andamento', () async {
      final repo = LocalDownloadRepository();
      expect(await repo.getActiveQueue(), isEmpty);

      final task = DownloadTaskModel(
        id: 'task_queue_1',
        trackId: 'track_queue_1',
        title: 'Queue Song',
        artistName: 'Queue Artist',
        status: DownloadStatus.pending,
      );

      await repo.saveActiveQueue({'track_queue_1': task});
      final loadedQueue = await repo.getActiveQueue();

      expect(loadedQueue.length, 1);
      expect(loadedQueue['track_queue_1']?.title, 'Queue Song');

      await repo.saveActiveQueue({});
      expect(await repo.getActiveQueue(), isEmpty);
    });
  });

  group('DownloadController Tests', () {
    test('setPreferredFormat altera estado do controller', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(downloadControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.setPreferredFormat(AudioFormat.mp3);
      final state = container.read(downloadControllerProvider);

      expect(state.preferredFormat, AudioFormat.mp3);
    });
  });
}
