# Task 3: Presentation - Controller de Playlists em Riverpod

## 📌 Descrição Aprofundada
Criar o provider Riverpod para expor as playlists do usuário logado e lidar com as mutações de dados.

## 🎯 Escopo da Task
1. Criar `lib/src/features/playlist/presentation/controllers/playlist_controller.dart`.
2. Expor `userPlaylistsProvider`: `StreamProvider<List<PlaylistModel>>`.
3. Notifier com métodos para executar a criação e adição de músicas a playlists.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/playlist/presentation/controllers/playlist_controller.dart`

## ✅ Critérios de Aceite
- Notificação automática em caso de adição ou remoção de faixas.
