# Task 2: Data - Repositório FirestorePlaylistRepository

## 📌 Descrição Aprofundada
Conectar com a coleção `playlists` no Cloud Firestore para persistir alterações, novas faixas e exclusões em tempo real.

## 🎯 Escopo da Task
1. Criar `lib/src/features/playlist/data/repositories/firestore_playlist_repository.dart`.
2. Implementar: `getUserPlaylists(userId)`, `createPlaylist(userId, title, description)`, `addSongToPlaylist(playlistId, song)`, `removeSongFromPlaylist(playlistId, songId)`, `deletePlaylist(playlistId)`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/playlist/data/repositories/firestore_playlist_repository.dart`

## ✅ Critérios de Aceite
- Sincronização em tempo real via `Stream<List<PlaylistModel>>`.
