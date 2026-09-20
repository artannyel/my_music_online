# Plano de Implementação - Feature: Play History & Top Stats

## 1. Visão Geral
A feature `play_history` adiciona a capacidade de rastrear e armazenar no banco de dados todas as músicas escutadas pelo usuário. A partir desses dados, será possível exibir o Histórico Recente, um "Top 20 Mais Tocadas (Geral)" e "Mais Tocadas do Mês", criando uma experiência altamente personalizada e nostálgica.

## 2. Abordagem Técnica
- **Registro:** O `PlayerController` vai monitorar o progresso da música atual. Se a música tocar por mais de X segundos (ex: 30 segundos), um evento de reprodução (`PlayLog`) será enviado ao Firestore em uma subcoleção do usuário logado.
- **Leitura:** O repositório irá fazer consultas (queries) no Firestore:
  - Ordenar por `timestamp` para o Histórico Recente.
  - Usar aggregation/grouping para as "Top 20" e "Mensais" (processamento local após puxar o banco, ou mantendo um documento de contadores consolidados no Firestore para otimização de custo).

## 3. Arquitetura da Feature
```text
lib/src/features/history/
├── domain/
│   ├── models/
│   │   ├── play_log_model.dart
│   │   └── top_track_model.dart
│   └── repositories/
│       └── history_repository.dart
├── data/
│   └── repositories/
│       └── firestore_history_repository.dart
└── presentation/
    ├── controllers/
    │   └── history_controller.dart
    └── views/
        ├── history_screen.dart
        └── top_tracks_screen.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain - Modelos PlayLog e TopTrack](./task-1-domain-models.md)
- [ ] [Task 2: Data - Repositório do Firestore e Lógica de Agregação](./task-2-firestore-repository.md)
- [ ] [Task 3: Integração - Rastreador de Reprodução no Player](./task-3-player-tracker.md)
- [ ] [Task 4: Presentation - Controllers e Telas de UI](./task-4-history-ui.md)
