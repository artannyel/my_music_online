# Plano de Implementação - Feature: Artist (Perfil do Artista)

## 1. Visão Geral
A feature `artist` exibe a página dedicada de perfil do artista, contendo banner de capa, botão para "Seguir", lista das 5 faixas mais populares e carrosséis com seus álbuns e singles lançados.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Header com foto de perfil do artista em circulo ou banner retangular, estatísticas de ouvintes, botão magenta "Seguir" / "Inscrever-se", seções bem separadas por cartões escuros.

## 3. Arquitetura da Feature
```text
lib/src/features/artist/
├── domain/
│   ├── models/
│   │   └── artist_model.dart
│   └── repositories/
│       └── artist_repository.dart
├── data/
│   └── repositories/
│       └── ytmusic_artist_repository.dart
└── presentation/
    ├── controllers/
    │   └── artist_controller.dart
    └── views/
        └── artist_detail_screen.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain - Modelo ArtistModel](./task-1-domain-models.md)
- [ ] [Task 2: Data - Repositório ArtistRepository (dart_ytmusic_api)](./task-2-artist-repository.md)
- [ ] [Task 3: Presentation - Controller em Riverpod](./task-3-artist-riverpod-controller.md)
- [ ] [Task 4: Presentation - Interface de Usuário ArtistDetailScreen (Stitch)](./task-4-artist-detail-screen-ui.md)
