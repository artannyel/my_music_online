# Task 3: Presentation - Controller de Autenticação com Riverpod

## 📌 Descrição Aprofundada
Criar os providers do Riverpod para gerenciar o estado reativo de login, cadastro, erros e estado da sessão do usuário no app.

## 🎯 Escopo da Task
1. Criar `lib/src/features/auth/presentation/controllers/auth_controller.dart`:
   - `authRepositoryProvider`: Provider que expõe a instância de `AuthRepository`.
   - `authStateProvider`: `StreamProvider<UserModel?>` que escuta as alterações da sessão em tempo real.
   - `authControllerProvider`: `StateNotifierProvider` / `NotifierProvider` para executar as ações de login/registro e expor estados de loading/erro.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/auth/presentation/controllers/auth_controller.dart`

## ✅ Critérios de Aceite
- Notificação reativa de mudança de estado de autenticação para a árvore de UI.
