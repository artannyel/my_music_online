# Task 1: Domain - Modelo PlaylistModel & Interface

## 📌 Descrição Aprofundada
Definir os modelos de dados e métodos para gerenciar playlists e suas faixas.

## 🎯 Escopo da Task
1. Criar `lib/src/features/playlist/domain/models/playlist_model.dart`:
   - Campos: `id`, `userId`, `title`, `description`, `coverUrl`, `tracks` (List<SongModel>), `createdAt`, `isPublic`.
2. Criar `lib/src/features/playlist/domain/repositories/playlist_repository.dart`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/playlist/domain/models/playlist_model.dart`
- `lib/src/features/playlist/domain/repositories/playlist_repository.dart`

## ✅ Critérios de Aceite
- Modelo imutável pronto com conversores JSON / Firestore Document Map.
