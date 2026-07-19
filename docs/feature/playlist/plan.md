# Plano de Implementação - Feature: Playlist (Criar, Salvar e Gerenciar)

## 1. Visão Geral
A feature `playlist` permite aos usuários criar novas playlists personalizadas, salvar playlists públicas, adicionar faixas a qualquer playlist existente e visualizar os detalhes de cada lista de reprodução com persistência em tempo real no **Firebase Cloud Firestore**.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Header com colagem da capa da playlist, metadados (quantidade de faixas, autor, tempo total), botões de ação ("Tocar Tudo", "Aleatório", "Editar"), bottom sheets arredondados para seleção rápida de playlists.

## 3. Arquitetura da Feature
```text
lib/src/features/playlist/
├── domain/
│   ├── models/
│   │   └── playlist_model.dart
│   └── repositories/
│       └── playlist_repository.dart
├── data/
│   └── repositories/
│       └── firestore_playlist_repository.dart
└── presentation/
    ├── controllers/
    │   └── playlist_controller.dart
    ├── widgets/
    │   ├── create_playlist_dialog.dart
    │   └── add_to_playlist_bottom_sheet.dart
    └── views/
        └── playlist_detail_screen.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain - Modelo PlaylistModel & Interface](./task-1-domain-models.md)
- [ ] [Task 2: Data - Repositório FirestorePlaylistRepository](./task-2-firestore-playlist-repository.md)
- [ ] [Task 3: Presentation - Controller de Playlists em Riverpod](./task-3-playlist-riverpod-controller.md)
- [ ] [Task 4: Presentation - Modal de Criação de Playlist (Dialog UI)](./task-4-create-playlist-dialog-ui.md)
- [ ] [Task 5: Presentation - Bottom Sheet "Adicionar à Playlist"](./task-5-add-to-playlist-bottom-sheet-ui.md)
- [ ] [Task 6: Presentation - Tela de Detalhes da Playlist (Stitch UI)](./task-6-playlist-detail-screen-ui.md)
