# Task 3: Presentation - Controller Riverpod (DownloadController & Providers)

## 📌 Descrição Aprofundada
Criar o estado global e reativo dos downloads em andamento, preferência de formato (`.m4a` / `.mp3`) e da biblioteca off-line organizadas por faixas e playlists utilizando Riverpod.

## 🎯 Escopo da Task
1. Criar `lib/src/features/download/presentation/controllers/download_controller.dart`:
   - `DownloadState`:
     - `Map<String, DownloadTaskModel> activeDownloads` (Fila ativa por `trackId`).
     - `List<OfflineTrackModel> offlineTracks` (Lista de músicas salvas off-line).
     - `AudioFormat preferredFormat` (`m4a` por padrão ou `mp3`).
     - `int totalStorageBytes` (Espaço total consumido em disco).
   - Métodos do Controller:
     - `Future<void> downloadTrack(AudioTrackModel track, {String? playlistName})`
     - `Future<void> downloadPlaylist(List<AudioTrackModel> tracks, String playlistTitle)`
     - `Future<void> setPreferredFormat(AudioFormat format)`
     - `Future<void> cancelDownload(String trackId)`
     - `Future<void> deleteOfflineTrack(String trackId)`
     - `Future<void> deleteOfflinePlaylist(String playlistName)`
     - `Future<void> clearAllDownloads()`
2. Prover seletores reativos:
   - `isTrackDownloadedProvider(trackId)` (Retorna bool).
   - `trackDownloadProgressProvider(trackId)` (Retorna progresso 0.0 a 1.0).
   - `offlinePlaylistsProvider` (Retorna mapa de `playlistName` -> `List<OfflineTrackModel>`).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/download/presentation/controllers/download_controller.dart`

## ✅ Critérios de Aceite
- Estado reativo com atualizações fluidas de progresso durante downloads.
- Suporte a download de playlists agrupadas por pasta sem travar a interface.
