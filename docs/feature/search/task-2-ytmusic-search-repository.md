# Task 2: Data - Repositório de Busca (dart_ytmusic_api com Cookies do Firebase)

## 📌 Descrição Aprofundada
Conectar com a biblioteca `dart_ytmusic_api` para executar buscas por termo e inicializar a API injetando o conteúdo dos cookies recuperados do Cloud Firestore via `ytCookiesProvider`.

## 🎯 Escopo da Task
1. Criar `lib/src/features/search/data/repositories/ytmusic_search_repository.dart`.
2. Escutar/Receber o texto do `cookies.txt` salvo no Firebase para autenticar as requisições de busca do YouTube Music.
3. Implementar `search(String query, {SearchType? filterType})`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/search/data/repositories/ytmusic_search_repository.dart`

## ✅ Critérios de Aceite
- Requisições de busca autenticadas usando os cookies do Firebase de forma transparente.
