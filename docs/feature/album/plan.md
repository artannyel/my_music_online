# Plano de Implementação - Feature: Album (Tela do Álbum)

## 1. Visão Geral
A feature `album` permite a navegação e visualização de álbuns musicais completos. Exibe a capa estendida do álbum, ano de lançamento, gravadora, nome do artista com atalho interativo e a lista ordenada de faixas com opção de reprodução em lote.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Capa do álbum grande centralizada no topo com degradê suave (*gradient overlay*), botão magenta para "Reproduzir Álbum" e lista com numeração de faixas (1, 2, 3...).

## 3. Arquitetura da Feature
```text
lib/src/features/album/
├── domain/
│   ├── models/
│   │   └── album_model.dart
│   └── repositories/
│       └── album_repository.dart
├── data/
│   └── repositories/
│       └── ytmusic_album_repository.dart
└── presentation/
    ├── controllers/
    │   └── album_controller.dart
    └── views/
        └── album_detail_screen.dart
```

## 4. Divisão de Tasks
- [x] [Task 1: Domain - Modelo AlbumModel](./task-1-domain-models.md)
- [x] [Task 2: Data - Repositório AlbumRepository (dart_ytmusic_api)](./task-2-album-repository.md)
- [x] [Task 3: Presentation - Controller em Riverpod](./task-3-album-riverpod-controller.md)
- [x] [Task 4: Presentation - Interface de Usuário AlbumDetailScreen (Stitch)](./task-4-album-detail-screen-ui.md)
