# Task 1: Domain - Modelos SearchResultModel

## 📌 Descrição Aprofundada
Definir o modelo unificado de resultado de busca que suporte os diferentes tipos de entidades retornadas (músicas, álbuns, artistas e playlists).

## 🎯 Escopo da Task
1. Criar `lib/src/features/search/domain/models/search_result_model.dart`:
   - Enum `SearchType` (`song`, `album`, `artist`, `playlist`).
   - Campos: `id`, `title`, `subtitle`, `thumbnailUrl`, `type`, `extraData`.
2. Criar `lib/src/features/search/domain/repositories/search_repository.dart`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/search/domain/models/search_result_model.dart`
- `lib/src/features/search/domain/repositories/search_repository.dart`

## ✅ Critérios de Aceite
- Modelo bem tipado pronto para mapear qualquer retorno de pesquisa.
