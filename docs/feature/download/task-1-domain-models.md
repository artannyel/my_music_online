# Task 1: Domain - Modelos DownloadTaskModel, OfflineTrackModel e Interface DownloadRepository

## 📌 Descrição Aprofundada
Definir as entidades de domínio necessárias para representar o estado dos downloads (pendente, em andamento, concluído, com falha), o formato do arquivo (`.m4a` ou `.mp3`), o mapeamento de pastas por playlist e a interface de repositório de downloads.

## 🎯 Escopo da Task
1. Criar `lib/src/features/download/domain/models/download_task_model.dart`:
   - Enum `DownloadStatus`: `{ pending, downloading, completed, failed, paused }`.
   - Enum `AudioFormat`: `{ m4a, mp3 }`.
   - Campos: `id`, `trackId`, `title`, `artistName`, `playlistName`, `thumbnailUrl`, `progress` (double 0.0 a 1.0), `status`, `audioFormat`, `filePath`, `downloadedBytes`, `totalBytes`, `errorMessage`.
2. Criar `lib/src/features/download/domain/models/offline_track_model.dart`:
   - Campos: `id`, `videoId`, `title`, `artistName`, `albumName`, `playlistName`, `thumbnailUrl`, `duration`, `localFilePath`, `audioFormat`, `downloadedAt`, `fileSizeBytes`.
   - Método auxiliar para converter em `AudioTrackModel` para reprodução direta no `playerControllerProvider`.
3. Criar `lib/src/features/download/domain/repositories/download_repository.dart`:
   - Interfaces:
     - `Future<List<OfflineTrackModel>> getOfflineTracks();`
     - `Future<OfflineTrackModel?> getOfflineTrack(String trackId);`
     - `Future<bool> isTrackDownloaded(String trackId);`
     - `Future<void> saveOfflineTrack(OfflineTrackModel track);`
     - `Future<void> deleteOfflineTrack(String trackId);`
     - `Future<int> getTotalStorageUsedBytes();`
     - `Future<void> clearAllDownloads();`
     - `Future<AudioFormat> getPreferredAudioFormat();`
     - `Future<void> setPreferredAudioFormat(AudioFormat format);`

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/download/domain/models/download_task_model.dart`
- `lib/src/features/download/domain/models/offline_track_model.dart`
- `lib/src/features/download/domain/repositories/download_repository.dart`

## ✅ Critérios de Aceite
- Estruturas de dados tipadas e imutáveis prontas para suporte a pastas físicas e formatos configuráveis (`.m4a` e `.mp3`).
