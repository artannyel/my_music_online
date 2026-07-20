# Plano de Implementação - Feature: Player (Áudio & Interface YouTube Music)

## 1. Visão Geral
A feature `player` é o coração do aplicativo de música. Ela gerencia o mecanismo de áudio nativo (`just_audio` / `audio_service`), o controle de estado da fila de reprodução, o `MiniPlayer` persistente na parte inferior do aplicativo e a tela `FullPlayerView` expandível com design inspirado no **YouTube Music** (prototipado no Stitch).

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Capa de música grande centralizada com bordas ligeiramente arredondadas, brilho colorido neon em segundo plano, scrubber/slider de progresso customizado, botões circulares de mídia com destaque no Play/Pause, drawer deslizante da Fila de Reprodução.

## 3. Arquitetura da Feature
```text
lib/src/features/player/
├── domain/
│   ├── models/
│   │   ├── song_model.dart
│   │   └── player_state_model.dart
│   └── repositories/
│       └── audio_player_repository.dart
├── data/
│   └── repositories/
│       └── just_audio_player_repository.dart
└── presentation/
    ├── controllers/
    │   └── player_controller.dart
    ├── widgets/
    │   └── mini_player_widget.dart
    └── views/
        └── full_player_screen.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain - Modelos SongModel, PlayerStateModel & Interface](./task-1-domain-models.md)
- [ ] [Task 2: Data - Repositório JustAudioPlayerRepository & Stream Extract](./task-2-just-audio-repository.md)
- [ ] [Task 3: Presentation - PlayerController em Riverpod](./task-3-player-riverpod-controller.md)
- [ ] [Task 4: Presentation - Componente MiniPlayer (UI Bar Persistente)](./task-4-mini-player-widget-ui.md)
- [ ] [Task 5: Presentation - Tela FullPlayerView Estilo YouTube Music (Stitch)](./task-5-full-player-screen-ui.md)
- [ ] [Task 6: Feature - Modo Rádio Automix / Autoplay Infinito (getUpNexts)](./task-6-radio-automix.md)

