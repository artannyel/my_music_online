# Task 2: Data - Repositório FirestoreSettingsRepository (Cookies)

## 📌 Descrição Aprofundada
Conectar com o Cloud Firestore no documento `config/ytmusic_cookies` para salvar e recuperar o texto do arquivo `cookies.txt`.

## 🎯 Escopo da Task
1. Criar `lib/src/features/settings/data/repositories/firestore_settings_repository.dart`.
2. Métodos: `saveCookies(String cookiesText)`, `getCookies()`, `Stream<String?> watchCookies()`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/settings/data/repositories/firestore_settings_repository.dart`

## ✅ Critérios de Aceite
- Sincronização e salvamento do texto dos cookies no Firebase com sucesso.
