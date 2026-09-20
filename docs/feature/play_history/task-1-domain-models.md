# Task 1: Domain - Modelos PlayLog e TopTrack

## 📌 Descrição Aprofundada
Definir as entidades responsáveis por carregar os dados de reprodução e de agregação estatística, além dos contratos de repositório necessários para salvar e buscar essas informações.

## 🎯 Escopo da Task
1. **Criar `PlayLogModel`**:
   - Campos: `id` (DocumentID), `userId`, `trackId`, `title`, `artistName`, `albumName`, `thumbnailUrl`, `videoId`, `duration` e `playedAt` (DateTime).
   - Métodos: `fromJson`, `toJson`, e factory methods necessários.
2. **Criar `TopTrackModel`**:
   - Um modelo estendido ou que contém a música e um contador (`playCount`).
3. **Criar `HistoryRepository` (Interface)**:
   - `Future<void> logPlay(String userId, PlayLogModel log)`
   - `Future<List<PlayLogModel>> getRecentHistory(String userId, {int limit = 50})`
   - `Future<List<TopTrackModel>> getTopTracks(String userId, {int limit = 20})`
   - `Future<List<TopTrackModel>> getMonthlyTopTracks(String userId, int month, int year, {int limit = 20})`

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/history/domain/models/play_log_model.dart`
- `lib/src/features/history/domain/models/top_track_model.dart`
- `lib/src/features/history/domain/repositories/history_repository.dart`

## ✅ Critérios de Aceite
- Classes de modelo com construtores nomeados e serialização (Freezed ou manual).
- Interface do repositório bem definida cobrindo todos os casos de uso de leitura (Recente, Top20, Top Mensal).
