# Task 3: Presentation - PlayerController em Riverpod

## 📌 Descrição Aprofundada
Desenvolver o `PlayerNotifier` / `PlayerController` usando Riverpod para gerenciar de forma global o estado do player de áudio na aplicação.

## 🎯 Escopo da Task
1. Criar `lib/src/features/player/presentation/controllers/player_controller.dart`.
2. Expor `playerControllerProvider`: `StateNotifier<PlayerStateModel>` / `Notifier<PlayerStateModel>`.
3. Escutar posições em tempo real do `just_audio` e sincronizar com a interface gráfica.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/presentation/controllers/player_controller.dart`

## ✅ Critérios de Aceite
- Estado do player reativo, sincronizando capa, título, progresso de tempo e fila com a UI.
