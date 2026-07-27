# Plano de Implementação - Feature: Home (Sugestões & Destaques)

## 1. Visão Geral
A feature `home` fornece a experiência inicial de descoberta do aplicativo. Ela exibe sugestões de músicas e playlists personalizadas, os lançamentos e as músicas mais tocadas no momento, com dados fornecidos pela API `dart_ytmusic_api` e armazenados no Firebase.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Header de saudação customizado, carrossel de cards horizontais para "Sugestões para Você", listas verticais para "Mais Tocadas", grids limpos para Playlists recomendadas em modo escuro.

## 3. Arquitetura da Feature
```text
lib/src/features/home/
├── domain/
│   ├── models/
│   │   └── home_section_model.dart
│   └── repositories/
│       └── home_repository.dart
├── data/
│   └── repositories/
│       └── ytmusic_home_repository.dart
└── presentation/
    ├── controllers/
    │   └── home_controller.dart
    └── views/
        └── home_screen.dart
```

## 4. Divisão de Tasks
- [x] [Task 1: Domain - Modelos da Home](./task-1-domain-models.md)
- [x] [Task 2: Data - Repositório Home (dart_ytmusic_api)](./task-2-home-repository.md)
- [x] [Task 3: Presentation - Controller com Riverpod](./task-3-home-riverpod-controller.md)
- [x] [Task 4: Presentation - Interface de Usuário HomeScreen (Stitch)](./task-4-home-screen-ui.md)
