import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../data/repositories/local_download_repository.dart';
import '../../data/services/audio_downloader_service.dart';
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

  DownloadController(this._repository, this._downloaderService)
      : super(const DownloadState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final offlineTracks = await _repository.getOfflineTracks();
      final totalBytes = await _repository.getTotalStorageUsedBytes();
      final format = await _repository.getPreferredAudioFormat();

      state = DownloadState(
        offlineTracks: offlineTracks,
        totalStorageBytes: totalBytes,
        preferredFormat: format,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[DownloadController] Erro na inicialização: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Altera o formato de áudio preferido para os downloads futuros (`.m4a` ou `.mp3`).
  Future<void> setPreferredFormat(AudioFormat format) async {
    state = state.copyWith(preferredFormat: format);
    await _repository.setPreferredAudioFormat(format);
  }

  /// Inicia o download de uma faixa individual.
  Future<void> downloadTrack(AudioTrackModel track, {String? playlistName}) async {
    // Se a faixa já estiver baixada ou sendo baixada, ignorar
    if (state.activeDownloads.containsKey(track.id)) return;
    if (state.offlineTracks.any((t) => t.id == track.id || t.videoId == track.videoId)) return;

    final stream = _downloaderService.downloadTrack(
      track: track,
      playlistName: playlistName,
      format: state.preferredFormat,
    );

    await for (final task in stream) {
      final updatedMap = Map<String, DownloadTaskModel>.from(state.activeDownloads);
      updatedMap[track.id] = task;

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
      } else if (task.status == DownloadStatus.failed) {
        state = state.copyWith(activeDownloads: updatedMap);
      } else {
        state = state.copyWith(activeDownloads: updatedMap);
      }
    }
  }

  /// Inicia o download sequencial de todas as faixas de uma playlist.
  Future<void> downloadPlaylist(List<AudioTrackModel> tracks, String playlistTitle) async {
    for (final track in tracks) {
      await downloadTrack(track, playlistName: playlistTitle);
    }
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
  return DownloadController(repo, service);
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
