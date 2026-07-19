# Plano de Implementação - Feature: Core & Infraestrutura Base

## 1. Visão Geral
A feature `core` estabelece os alicerces técnicos, estéticos e estruturais do aplicativo **My Music Online**. Ela contém as configurações globais de tema escuro (guiado pelo design do Stitch), gerenciamento de dependências, navegação com `GoRouter` e inicializações do Firebase e Audio Handler.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Aparência**: Dark Theme limpo, moderno, fundo Obsidian Deep (`#090A0F`), superfícies com leve glassmorphism (`#12141D`), acentos neon magenta/roxo (`#FF0055` / `#7C4DFF`), e tipografia de alto contraste.

## 3. Arquitetura da Feature
```text
lib/src/core/
├── constants/
│   ├── app_colors.dart
│   └── app_sizes.dart
├── theme/
│   ├── app_theme.dart
│   └── text_styles.dart
├── router/
│   ├── app_router.dart
│   └── route_names.dart
└── services/
    ├── firebase_service.dart
    └── audio_handler.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Configuração do `pubspec.yaml`](./task-1-pubspec-dependencies.md)
- [ ] [Task 2: Design System & Tema Escuro (Stitch)](./task-2-design-system-and-dark-theme.md)
- [ ] [Task 3: GoRouter & ShellRoute (MiniPlayer Global)](./task-3-gorouter-and-shellroute.md)
- [ ] [Task 4: Inicialização de Serviços Globais (Firebase & Audio)](./task-4-firebase-and-services-init.md)
