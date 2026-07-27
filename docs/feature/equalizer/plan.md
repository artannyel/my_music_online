# Plano de Implementação - Feature: Equalizer (Tela de Equalização)

## 1. Visão Geral
A feature `equalizer` oferece controles visuais de equalização de som, como alteração de ganho por faixas de frequência (60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz), chave Mestre ON/OFF e seleção de *Presets* pré-configurados (Rock, Pop, Jazz, Bass Boost, Flat).

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Interface estilo mesa de som digital em tema escuro, sliders de frequência verticais com brilho neon nos mostradores, chips horizontais para seleção de presets e chave de alternância elegante.

## 3. Arquitetura da Feature
```text
lib/src/features/equalizer/
├── domain/
│   ├── models/
│   │   └── equalizer_preset_model.dart
│   └── repositories/
│       └── equalizer_repository.dart
├── data/
│   └── repositories/
│       └── audio_equalizer_repository.dart
└── presentation/
    ├── controllers/
    │   └── equalizer_controller.dart
    └── views/
        └── equalizer_screen.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain - Modelo EqualizerPresetModel](./task-1-domain-models.md)
- [ ] [Task 2: Data - Repositório de Equalização (just_audio audio_service)](./task-2-equalizer-repository.md)
- [ ] [Task 3: Presentation - Controller em Riverpod](./task-3-equalizer-riverpod-controller.md)
- [ ] [Task 4: Presentation - Interface de Usuário EqualizerScreen (Stitch)](./task-4-equalizer-screen-ui.md)
