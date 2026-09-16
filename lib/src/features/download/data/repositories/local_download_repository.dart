import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/download_task_model.dart';
import '../../domain/models/offline_track_model.dart';
import '../../domain/repositories/download_repository.dart';

const String _prefsOfflineTracksKey = 'offline_tracks_index';
const String _prefsPreferredFormatKey = 'preferred_audio_format';
const String _prefsActiveQueueKey = 'active_download_queue';

/// Repositório local responsável por indexar as músicas baixadas e preferências de formato no SharedPreferences.
class LocalDownloadRepository implements DownloadRepository {

  @override
  Future<List<OfflineTrackModel>> getOfflineTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsOfflineTracksKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = json.decode(jsonString) as List<dynamic>;
      final tracks = <OfflineTrackModel>[];

      for (final item in decoded) {
        final track = OfflineTrackModel.fromJson(item as Map<String, dynamic>);
        // Verifica se o arquivo físico realmente ainda existe no dispositivo
        if (File(track.localFilePath).existsSync()) {
          tracks.add(track);
        }
      }

      return tracks;
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao obter músicas off-line: $e');
      return [];
    }
  }

  @override
  Future<OfflineTrackModel?> getOfflineTrack(String trackId) async {
    final tracks = await getOfflineTracks();
    for (final track in tracks) {
      if (track.id == trackId || track.videoId == trackId) {
        return track;
      }
    }
    return null;
  }

  @override
  Future<bool> isTrackDownloaded(String trackId) async {
    final track = await getOfflineTrack(trackId);
    return track != null;
  }

  @override
  Future<void> saveOfflineTrack(OfflineTrackModel track) async {
    try {
      final currentTracks = await getOfflineTracks();
      final updated = List<OfflineTrackModel>.from(currentTracks)
        ..removeWhere((t) => t.id == track.id)
        ..add(track);

      await _saveIndex(updated);
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao salvar índice da música off-line: $e');
    }
  }

  @override
  Future<void> deleteOfflineTrack(String trackId) async {
    try {
      final currentTracks = await getOfflineTracks();
      final trackToDelete = currentTracks.firstWhere(
        (t) => t.id == trackId || t.videoId == trackId,
        orElse: () => throw Exception('Faixa não encontrada'),
      );

      // Remove o arquivo físico
      final file = File(trackToDelete.localFilePath);
      if (await file.exists()) {
        await file.delete();
      }

      final updated = currentTracks.where((t) => t.id != trackToDelete.id).toList();
      await _saveIndex(updated);
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao deletar faixa off-line: $e');
    }
  }

  @override
  Future<void> deleteOfflinePlaylist(String playlistName) async {
    try {
      final currentTracks = await getOfflineTracks();
      final playlistTracks = currentTracks.where((t) => t.playlistName == playlistName).toList();

      for (final track in playlistTracks) {
        final file = File(track.localFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Tenta remover a pasta vazia se existir
      if (playlistTracks.isNotEmpty) {
        final samplePath = playlistTracks.first.localFilePath;
        final parentDir = File(samplePath).parent;
        if (await parentDir.exists() && (await parentDir.list().isEmpty)) {
          await parentDir.delete();
        }
      }

      final updated = currentTracks.where((t) => t.playlistName != playlistName).toList();
      await _saveIndex(updated);
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao deletar playlist off-line: $e');
    }
  }

  @override
  Future<int> getTotalStorageUsedBytes() async {
    final tracks = await getOfflineTracks();
    int total = 0;
    for (final track in tracks) {
      final file = File(track.localFilePath);
      if (file.existsSync()) {
        total += file.lengthSync();
      } else {
        total += track.fileSizeBytes;
      }
    }
    return total;
  }

  @override
  Future<void> clearAllDownloads() async {
    try {
      final tracks = await getOfflineTracks();
      for (final track in tracks) {
        final file = File(track.localFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsOfflineTracksKey);
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao limpar todos os downloads: $e');
    }
  }

  @override
  Future<AudioFormat> getPreferredAudioFormat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formatStr = prefs.getString(_prefsPreferredFormatKey);
      if (formatStr == 'mp3') return AudioFormat.mp3;
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao obter preferência de formato: $e');
    }
    return AudioFormat.m4a;
  }

  @override
  Future<void> setPreferredAudioFormat(AudioFormat format) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsPreferredFormatKey, format.name);
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao definir preferência de formato: $e');
    }
  }

  @override
  Future<void> saveActiveQueue(Map<String, DownloadTaskModel> activeDownloads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (activeDownloads.isEmpty) {
        await prefs.remove(_prefsActiveQueueKey);
        return;
      }
      final jsonList = activeDownloads.values.map((t) => t.toJson()).toList();
      await prefs.setString(_prefsActiveQueueKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao salvar fila ativa: $e');
    }
  }

  @override
  Future<Map<String, DownloadTaskModel>> getActiveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsActiveQueueKey);
      if (jsonString == null || jsonString.isEmpty) return {};

      final decoded = json.decode(jsonString) as List<dynamic>;
      final map = <String, DownloadTaskModel>{};

      for (final item in decoded) {
        final task = DownloadTaskModel.fromJson(item as Map<String, dynamic>);
        map[task.trackId] = task;
      }

      return map;
    } catch (e) {
      debugPrint('[LocalDownloadRepository] Erro ao obter fila ativa: $e');
      return {};
    }
  }

  Future<void> _saveIndex(List<OfflineTrackModel> tracks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tracks.map((t) => t.toJson()).toList();
    await prefs.setString(_prefsOfflineTracksKey, json.encode(jsonList));
  }
}
