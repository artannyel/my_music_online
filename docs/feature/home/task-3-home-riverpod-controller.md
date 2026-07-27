# Task 3: Presentation - Controller com Riverpod

## 📌 Descrição Aprofundada
Criar o provider Riverpod para a tela Home com suporte a estados de carregamento (*loading*), erro e recarregamento manual (*pull-to-refresh*).

## 🎯 Escopo da Task
1. Criar `lib/src/features/home/presentation/controllers/home_controller.dart`.
2. Expor `homeSectionsProvider`: `FutureProvider<List<HomeSectionModel>>`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/home/presentation/controllers/home_controller.dart`

## ✅ Critérios de Aceite
- Estado do Riverpod tratando exceções de rede e carregamento de forma elegante.
