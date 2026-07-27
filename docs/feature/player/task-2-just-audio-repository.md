# Task 2: Data - Repositório JustAudioPlayerRepository & Stream Extract

## 📌 Descrição Aprofundada
Implementar o player de áudio nativo com a biblioteca `just_audio` e suporte a segundo plano com `audio_service`. Integração de streams para obtenção de mídia da web.

## 🎯 Escopo da Task
1. Criar `lib/src/features/player/data/repositories/just_audio_player_repository.dart`.
2. Implementar métodos: `play()`, `pause()`, `seek(Duration position)`, `playTrack(SongModel song)`, `setQueue(List<SongModel> queue)`, `skipToNext()`, `skipToPrevious()`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/data/repositories/just_audio_player_repository.dart`

## ✅ Critérios de Aceite
- Áudio tocando com fluidez, controle de pausa/play e seek bar reativo.
