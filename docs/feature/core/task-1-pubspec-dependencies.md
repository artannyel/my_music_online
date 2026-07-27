# Task 1: Configuração do `pubspec.yaml` e Dependências do Projeto

## 📌 Descrição Aprofundada
Adicionar e configurar as dependências essenciais do ecossistema Flutter no arquivo `pubspec.yaml`. Garantir que todas as bibliotecas necessárias para gerenciamento de estado (Riverpod), roteamento (GoRouter), backend (Firebase), busca de áudio (`dart_ytmusic_api`), player (`just_audio`) e imagens em cache estejam devidamente especificadas.

## 🎯 Escopo da Task
1. Atualizar o `pubspec.yaml` com as versões adequadas das dependências:
   - `flutter_riverpod` / `riverpod_annotation`
   - `go_router`
   - `dart_ytmusic_api`
   - `firebase_core`, `firebase_auth`, `cloud_firestore`
   - `just_audio`, `audio_service`
   - `cached_network_image`, `google_fonts`
2. Executar `flutter pub get`.

## 📋 Arquivos a Modificar / Criar
- `pubspec.yaml`

## ✅ Critérios de Aceite
- Execução do `flutter pub get` concluída com sucesso e sem conflitos de versão.
- Todas as dependências prontas para importação nos módulos do aplicativo.
