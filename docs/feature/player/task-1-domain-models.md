# Task 1: Domain - Modelos SongModel, PlayerStateModel & Interface

## 📌 Descrição Aprofundada
Definir as estruturas de dados para representar faixas de áudio (`SongModel`), o estado da reprodução atual (`PlayerStateModel`) e o contrato de serviço do player.

## 🎯 Escopo da Task
1. Criar `lib/src/features/player/domain/models/song_model.dart`:
   - Campos: `id`, `title`, `artist`, `album`, `thumbnailUrl`, `duration`, `streamUrl`, `artistId`, `albumId`.
2. Criar `lib/src/features/player/domain/models/player_state_model.dart`:
   - Campos: `currentSong`, `isPlaying`, `isBuffering`, `position`, `duration`, `shuffleMode`, `repeatMode`, `queue`.
3. Criar `lib/src/features/player/domain/repositories/audio_player_repository.dart`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/domain/models/song_model.dart`
- `lib/src/features/player/domain/models/player_state_model.dart`
- `lib/src/features/player/domain/repositories/audio_player_repository.dart`

## ✅ Critérios de Aceite
- Modelos bem tipados com métodos `copyWith` e serialização.
