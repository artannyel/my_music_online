# Task 3: Presentation - Controller com Debounce (Riverpod)

## 📌 Descrição Aprofundada
Criar o provider Riverpod para busca contendo lógica de *debounce* (ex: aguardar 400ms após a última tecla digitada antes de disparar a requisição de busca).

## 🎯 Escopo da Task
1. Criar `lib/src/features/search/presentation/controllers/search_controller.dart`.
2. Expor `searchQueryProvider`, `selectedFilterProvider` e `searchResultsProvider`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/search/presentation/controllers/search_controller.dart`

## ✅ Critérios de Aceite
- Redução de requisições desnecessárias durante a digitação rápida do usuário.
