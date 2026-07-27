# Task 3: Presentation - Controller com Debounce (Riverpod)

## 📌 Descrição Aprofundada
Criar o provider Riverpod para busca contendo lógica de *debounce* (ex: aguardar 400ms após a última tecla digitada antes de disparar a requisição de busca).

## 🎯 Escopo da Task
1. Criar `lib/src/features/search/presentation/controllers/search_controller.dart`.
2. Expor `searchQueryProvider`, `searchSuggestionsProvider` (debounce de 300ms chamando `getSearchSuggestions`), `selectedFilterProvider` e `searchResultsProvider`.
3. Adicionar método de submissão de busca e seleção de sugestões.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/search/presentation/controllers/search_controller.dart`

## ✅ Critérios de Aceite
- Autocompletar rápido e dinâmico ao digitar.
- Redução de requisições desnecessárias durante a digitação do usuário.
