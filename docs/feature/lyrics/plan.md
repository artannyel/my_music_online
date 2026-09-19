# Plano de Implementação - Feature: Letras de Músicas (Lyrics & Timed Lyrics)

## 1. Visão Geral
A feature de **Letras de Músicas (Lyrics)** adiciona a capacidade de exibir e acompanhar a letra da música em reprodução diretamente na interface do reprodutor (`FullPlayerScreen`), inspirada na experiência do **YouTube Music**.

Utiliza os recursos já presentes na dependência `dart_ytmusic_api`:
- `getTimedLyrics(String videoId)`: Retorna as linhas sincronizadas com carimbo de tempo (`CueRange` com `startTimeMilliseconds` e `endTimeMilliseconds`).
- `getLyrics(String videoId)`: Fallback com o texto integral e estático da letra caso as letras sincronizadas não estejam disponíveis para a faixa.

## 2. Experiência do Usuário & Design
- **Acesso rápido no Player**: Adição de um botão ou aba/painel dedicado no `FullPlayerScreen` (ex.: ícone de letra/microfone ou abas superiores/inferiores "Próximas" / "Letra").
- **Exibição Dinâmica (Sincronizada)**:
  - Quando houver `TimedLyrics`, a linha ativa é destacada com cores vibrantes do tema (`AppColors.primary`), scroll automático acompanhando a posição do áudio, e toque em uma linha para saltar (`seek`) diretamente para aquele trecho.
- **Exibição Estática**:
  - Quando houver apenas `getLyrics`, o texto completo é apresentado formatado com scroll suave e indicação da fonte/créditos.
- **Tratamento de Indisponibilidade**:
  - Se a música não tiver letra disponível em nenhuma das chamadas, exibir estado amigável ("Letra indisponível para esta música") sem travar ou poluir a UI.

## 3. Arquitetura da Feature
```text
lib/src/features/player/
├── domain/
│   └── models/
│       └── lyrics_model.dart              # Modelos para encapsular letras estáticas e sincronizadas
├── data/
│   ├── datasources/
│   │   └── lyrics_remote_data_source.dart # Chamadas getTimedLyrics e getLyrics do YTMusic
│   └── repositories/
│       └── lyrics_repository_impl.dart    # Tratamento de erros, fallback e cache em memória
└── presentation/
    ├── controllers/
    │   └── lyrics_controller.dart         # Gerenciamento de estado (AsyncValue, linha ativa por tempo)
    ├── views/
    │   └── full_player_screen.dart        # Integração visual no player principal
    └── widgets/
        ├── lyrics_view_widget.dart        # Componente de rolagem e sincronia de letras
        └── timed_lyric_line_widget.dart   # Item individual com destaque e clique para seek
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain & Data - Modelos e Repositório de Letras](./task-1-lyrics-repository.md)
- [ ] [Task 2: Presentation - Controller de Letras e Sincronização em Tempo Real](./task-2-lyrics-controller.md)
- [ ] [Task 3: UI/UX - Integração de Letras no FullPlayerScreen e Visualização](./task-3-lyrics-player-ui.md)
