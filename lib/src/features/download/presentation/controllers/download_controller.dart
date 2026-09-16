import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../data/repositories/local_download_repository.dart';
import '../../data/services/audio_downloader_service.dart';
import '../../data/services/download_notification_service.dart';
import '../../domain/models/download_task_model.dart';
import '../../domain/models/offline_track_model.dart';
import '../../domain/repositories/download_repository.dart';

/// Provider singleton para o repositório de downloads.
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return LocalDownloadRepository();
});

/// Provider singleton para o serviço de download de áudio.
final audioDownloaderServiceProvider = Provider<AudioDownloaderService>((ref) {
  return AudioDownloaderService();
});

/// Provider singleton para o serviço de notificações de download.
final downloadNotificationServiceProvider = Provider<DownloadNotificationService>((ref) {
  return DownloadNotificationService();
});

/// Estado imutável do módulo de downloads.
@immutable
class DownloadState {
  final Map<String, DownloadTaskModel> activeDownloads;
  final List<OfflineTrackModel> offlineTracks;
  final AudioFormat preferredFormat;
  final int totalStorageBytes;
  final bool isLoading;

  const DownloadState({
    this.activeDownloads = const {},
    this.offlineTracks = const [],
    this.preferredFormat = AudioFormat.m4a,
    this.totalStorageBytes = 0,
    this.isLoading = false,
  });

  DownloadState copyWith({
    Map<String, DownloadTaskModel>? activeDownloads,
    List<OfflineTrackModel>? offlineTracks,
    AudioFormat? preferredFormat,
    int? totalStorageBytes,
    bool? isLoading,
  }) {
    return DownloadState(
      activeDownloads: activeDownloads ?? Map.from(this.activeDownloads),
      offlineTracks: offlineTracks ?? List.from(this.offlineTracks),
      preferredFormat: preferredFormat ?? this.preferredFormat,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller StateNotifier do módulo de downloads e biblioteca off-line.
class DownloadController extends StateNotifier<DownloadState> {
  final DownloadRepository _repository;
  final AudioDownloaderService _downloaderService;
  final DownloadNotificationService _notificationService;
  final Set<String> _cancelledTrackIds = {};

  DownloadController(
    this._repository,
    this._downloaderService,
    this._notificationService,
  ) : super(const DownloadState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final offlineTracks = await _repository.getOfflineTracks();
      final totalBytes = await _repository.getTotalStorageUsedBytes();
      final format = await _repository.getPreferredAudioFormat();
      final savedQueue = await _repository.getActiveQueue();

      final restoredQueue = <String, DownloadTaskModel>{};
      for (final entry in savedQueue.entries) {
        final trackId = entry.key;
        final task = entry.value;
        // Se a faixa não foi concluída no armazenamento, restaura na fila como pendente
        if (!offlineTracks.any((t) => t.id == trackId || t.videoId == trackId)) {
          restoredQueue[trackId] = task.copyWith(
            status: DownloadStatus.pending,
            progress: 0.0,
          );
        }
      }

      state = DownloadState(
        offlineTracks: offlineTracks,
        totalStorageBytes: totalBytes,
        preferredFormat: format,
        activeDownloads: restoredQueue,
        isLoading: false,
      );

      if (restoredQueue.isNotEmpty) {
        _resumePendingDownloads();
      }
    } catch (e) {
      debugPrint('[DownloadController] Erro na inicialização: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Retoma o download de faixas salvas na fila pendente ao reabrir o app.
  Future<void> _resumePendingDownloads() async {
    final pendingTasks = state.activeDownloads.values.toList();
    for (final task in pendingTasks) {
      if (_cancelledTrackIds.contains(task.trackId)) continue;
      final trackModel = AudioTrackModel(
        id: task.trackId,
        videoId: task.trackId,
        title: task.title,
        artistName: task.artistName,
        thumbnailUrl: task.thumbnailUrl,
      );
      await downloadTrack(trackModel, playlistName: task.playlistName);
    }
  }

  /// Altera o formato de áudio preferido para os downloads futuros (`.m4a` ou `.mp3`).
  Future<void> setPreferredFormat(AudioFormat format) async {
    state = state.copyWith(preferredFormat: format);
    await _repository.setPreferredAudioFormat(format);
  }

  /// Inicia o download de uma faixa individual.
  Future<void> downloadTrack(AudioTrackModel track, {String? playlistName}) async {
    // Se a faixa já estiver baixada ou cancelada, ignorar
    if (state.offlineTracks.any((t) => t.id == track.id || t.videoId == track.videoId)) return;

    _cancelledTrackIds.remove(track.id);

    final notificationId = track.id.hashCode.abs();
    int lastNotifiedPercent = -1;

    final initialTask = DownloadTaskModel(
      id: 'download_${track.id}_${DateTime.now().millisecondsSinceEpoch}',
      trackId: track.id,
      title: track.title,
      artistName: track.artistName,
      playlistName: playlistName,
      thumbnailUrl: track.thumbnailUrl,
      progress: 0.0,
      status: DownloadStatus.downloading,
      audioFormat: state.preferredFormat,
    );

    final initialMap = Map<String, DownloadTaskModel>.from(state.activeDownloads);
    initialMap[track.id] = initialTask;
    state = state.copyWith(activeDownloads: initialMap);
    await _repository.saveActiveQueue(initialMap);

    _notificationService.showDownloadProgress(
      id: notificationId,
      title: 'Baixando "${track.title}"',
      body: playlistName != null ? 'Playlist: $playlistName • 0%' : 'Iniciando download... 0%',
      progress: 0.0,
    );

    final stream = _downloaderService.downloadTrack(
      track: track,
      playlistName: playlistName,
      format: state.preferredFormat,
    );

    await for (final task in stream) {
      if (_cancelledTrackIds.contains(track.id)) {
        await _notificationService.cancelNotification(notificationId);
        final updatedMap = Map<String, DownloadTaskModel>.from(state.activeDownloads);
        updatedMap.remove(track.id);
        state = state.copyWith(activeDownloads: updatedMap);
        await _repository.saveActiveQueue(updatedMap);
        break;
      }

      final updatedMap = Map<String, DownloadTaskModel>.from(state.activeDownloads);
      updatedMap[track.id] = task;

      final currentPercent = (task.progress * 100).toInt();
      if (currentPercent != lastNotifiedPercent && (currentPercent % 5 == 0 || currentPercent == 100)) {
        lastNotifiedPercent = currentPercent;
        final bodyText = playlistName != null
            ? 'Playlist: $playlistName • $currentPercent%'
            : 'Progresso: $currentPercent% • ${state.preferredFormat.name.toUpperCase()}';
        await _notificationService.showDownloadProgress(
          id: notificationId,
          title: 'Baixando "${track.title}"',
          body: bodyText,
          progress: task.progress,
        );
      }

      if (task.status == DownloadStatus.completed) {
        updatedMap.remove(track.id);
        final offlineTrack = _downloaderService.createOfflineTrack(
          track: track,
          completedTask: task,
        );
        await _repository.saveOfflineTrack(offlineTrack);

        final updatedTracks = await _repository.getOfflineTracks();
        final updatedStorage = await _repository.getTotalStorageUsedBytes();

        state = state.copyWith(
          activeDownloads: updatedMap,
          offlineTracks: updatedTracks,
          totalStorageBytes: updatedStorage,
        );
        await _repository.saveActiveQueue(updatedMap);

        await _notificationService.showDownloadCompleted(
          id: notificationId,
          title: '🟢 Download Concluído',
          body: '"${track.title}" (${track.artistName}) foi salva off-line.',
        );
      } else {
        state = state.copyWith(activeDownloads: updatedMap);
        await _repository.saveActiveQueue(updatedMap);
      }
    }
  }

  /// Inicia o download sequencial de todas as faixas de uma playlist exibindo os pendentes na fila.
  Future<void> downloadPlaylist(List<AudioTrackModel> tracks, String playlistTitle) async {
    final updatedMap = Map<String, DownloadTaskModel>.from(state.activeDownloads);

    // Registra antecipadamente todas as faixas pendentes na fila de ativos
    for (final track in tracks) {
      if (!state.offlineTracks.any((t) => t.id == track.id || t.videoId == track.videoId) &&
          !updatedMap.containsKey(track.id)) {
        updatedMap[track.id] = DownloadTaskModel(
          id: 'pending_${track.id}',
          trackId: track.id,
          title: track.title,
          artistName: track.artistName,
          playlistName: playlistTitle,
          thumbnailUrl: track.thumbnailUrl,
          progress: 0.0,
          status: DownloadStatus.pending,
          audioFormat: state.preferredFormat,
        );
      }
    }

    state = state.copyWith(activeDownloads: updatedMap);
    await _repository.saveActiveQueue(updatedMap);

    final queueToProcess = List<AudioTrackModel>.from(tracks);
    const maxConcurrent = 2;

    Future<void> worker() async {
      while (queueToProcess.isNotEmpty) {
        final track = queueToProcess.removeAt(0);
        if (_cancelledTrackIds.contains(track.id)) continue;
        await downloadTrack(track, playlistName: playlistTitle);
      }
    }

    final activeWorkerCount = queueToProcess.isEmpty ? 0 : (queueToProcess.length < maxConcurrent ? queueToProcess.length : maxConcurrent);
    final workers = List.generate(activeWorkerCount, (_) => worker());
    await Future.wait(workers);
  }

  /// Cancela o download ativo ou pendente de uma faixa.
  void cancelDownload(String trackId) {
    _cancelledTrackIds.add(trackId);
    _notificationService.cancelNotification(trackId.hashCode.abs());
    final updatedMap = Map<String, DownloadTaskModel>.from(state.activeDownloads);
    updatedMap.remove(trackId);
    state = state.copyWith(activeDownloads: updatedMap);
    _repository.saveActiveQueue(updatedMap);
  }

  /// Cancela todos os downloads ativos e pendentes da fila.
  void cancelAllActiveDownloads() {
    _cancelledTrackIds.addAll(state.activeDownloads.keys);
    _notificationService.cancelAll();
    state = state.copyWith(activeDownloads: {});
    _repository.saveActiveQueue({});
  }

  /// Exclui uma faixa baixada do armazenamento.
  Future<void> deleteOfflineTrack(String trackId) async {
    await _repository.deleteOfflineTrack(trackId);
    final updatedTracks = await _repository.getOfflineTracks();
    final updatedStorage = await _repository.getTotalStorageUsedBytes();

    state = state.copyWith(
      offlineTracks: updatedTracks,
      totalStorageBytes: updatedStorage,
    );
  }

  /// Exclui uma playlist off-line inteira e seus arquivos do armazenamento.
  Future<void> deleteOfflinePlaylist(String playlistName) async {
    await _repository.deleteOfflinePlaylist(playlistName);
    final updatedTracks = await _repository.getOfflineTracks();
    final updatedStorage = await _repository.getTotalStorageUsedBytes();

    state = state.copyWith(
      offlineTracks: updatedTracks,
      totalStorageBytes: updatedStorage,
    );
  }

  /// Apaga todos os downloads e limpa o repositório local.
  Future<void> clearAllDownloads() async {
    cancelAllActiveDownloads();
    await _repository.clearAllDownloads();
    state = state.copyWith(
      offlineTracks: [],
      activeDownloads: {},
      totalStorageBytes: 0,
    );
  }
}

/// Provider global para a instância do DownloadController.
final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>((ref) {
  final repo = ref.watch(downloadRepositoryProvider);
  final service = ref.watch(audioDownloaderServiceProvider);
  final notificationService = ref.watch(downloadNotificationServiceProvider);
  return DownloadController(repo, service, notificationService);
});

/// Seletor para verificar se uma faixa está baixada.
final isTrackDownloadedProvider = Provider.family<bool, String>((ref, trackId) {
  final downloadState = ref.watch(downloadControllerProvider);
  return downloadState.offlineTracks.any((t) => t.id == trackId || t.videoId == trackId);
});

/// Seletor para obter a tarefa de download ativa de uma faixa.
final trackDownloadTaskProvider = Provider.family<DownloadTaskModel?, String>((ref, trackId) {
  final downloadState = ref.watch(downloadControllerProvider);
  return downloadState.activeDownloads[trackId];
});

/// Seletor para obter faixas off-line agrupadas por playlist.
final offlinePlaylistsProvider = Provider<Map<String, List<OfflineTrackModel>>>((ref) {
  final downloadState = ref.watch(downloadControllerProvider);
  final map = <String, List<OfflineTrackModel>>{};

  for (final track in downloadState.offlineTracks) {
    final playlistName = track.playlistName;
    if (playlistName != null && playlistName.trim().isNotEmpty) {
      map.putIfAbsent(playlistName, () => []).add(track);
    }
  }

  return map;
});
