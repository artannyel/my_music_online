# Plano de Implementação - Feature: Settings & Cookies Management

## 1. Visão Geral
A feature `settings` disponibiliza a interface de configurações do aplicativo e a área de gerenciamento e upload do arquivo `cookies.txt`. Esses cookies são enviados e persistidos no Firebase Cloud Firestore para que as bibliotecas do ecossistema do YouTube (`dart_ytmusic_api`, `youtube_explode_dart`, `newpipeextractor_dart`) consigam autenticar as requisições de busca e extração de áudio de forma estável e contornar limitações.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Tela de configurações limpa em modo escuro, botões estilizados para seleção de arquivo `.txt`, área de texto para colagem manual de cookies com pré-visualização, indicador de status dos cookies ("Cookies Ativos" / "Nenhum Cookie Configurado").

## 3. Arquitetura da Feature
```text
lib/src/features/settings/
├── domain/
│   ├── models/
│   │   └── app_settings_model.dart
│   └── repositories/
│       └── settings_repository.dart
├── data/
│   └── repositories/
│       └── firestore_settings_repository.dart
└── presentation/
    ├── controllers/
    │   └── settings_controller.dart
    └── views/
        └── cookies_settings_screen.dart
```

## 4. Divisão de Tasks
- [x] [Task 1: Domain - Modelo AppSettingsModel](./task-1-domain-models.md)
- [x] [Task 2: Data - Repositório FirestoreSettingsRepository (Cookies)](./task-2-firestore-cookies-repository.md)
- [x] [Task 3: Presentation - Controller de Configurações em Riverpod](./task-3-settings-riverpod-controller.md)
- [x] [Task 4: Presentation - Interface da Tela de Cookies (Stitch UI)](./task-4-cookies-upload-screen-ui.md)
