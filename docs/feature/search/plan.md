# Plano de Implementação - Feature: Search (Busca de Músicas, Álbuns & Artistas)

## 1. Visão Geral
A feature `search` possibilita a pesquisa instantânea de faixas, álbuns, artistas e playlists na API `dart_ytmusic_api`. Ela utiliza técnicas de *debounce* para evitar chamadas de API desnecessárias enquanto o usuário digita e oferece filtros rápidos por categoria.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Campo de busca moderno arredondado, chips de categoria interativos (*Músicas*, *Álbuns*, *Artistas*, *Playlists*), listas limpas com resultados instantâneos.

## 3. Arquitetura da Feature
```text
lib/src/features/search/
├── domain/
│   ├── models/
│   │   └── search_result_model.dart
│   └── repositories/
│       └── search_repository.dart
├── data/
│   ├── repositories/
│   │   └── ytmusic_search_repository.dart
│   └── services/
│       └── speech_to_text_service.dart
└── presentation/
    ├── controllers/
    │   └── search_controller.dart
    ├── views/
    │   └── search_screen.dart
    └── widgets/
        └── voice_search_bottom_sheet.dart
```

## 4. Divisão de Tasks
- [x] [Task 1: Domain - Modelos SearchResultModel](./task-1-domain-models.md)
- [x] [Task 2: Data - Repositório de Busca (dart_ytmusic_api)](./task-2-ytmusic-search-repository.md)
- [x] [Task 3: Presentation - Controller com Debounce (Riverpod)](./task-3-search-riverpod-controller.md)
- [x] [Task 4: Presentation - Interface de Busca SearchScreen (Stitch)](./task-4-search-screen-ui.md)
- [x] [Task 5: Voice Search - Pesquisa por Voz e Modal Animado (SpeechToText)](./task-5-voice-search.md)
