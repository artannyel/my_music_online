# Task 3: Presentation - Controller de Configurações em Riverpod

## 📌 Descrição Aprofundada
Desenvolver os providers Riverpod para expor o estado dos cookies ativos e alimentar a inicialização das bibliotecas `dart_ytmusic_api`, `youtube_explode_dart` e `newpipeextractor_dart`.

## 🎯 Escopo da Task
1. Criar `lib/src/features/settings/presentation/controllers/settings_controller.dart`.
2. Expor `ytCookiesProvider`: `StreamProvider<String?>`.
3. Método `uploadCookiesFile()` utilizando `file_picker` para ler o arquivo `.txt` local do dispositivo do usuário e enviar o texto para o Firestore.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/settings/presentation/controllers/settings_controller.dart`

## ✅ Critérios de Aceite
- Leitura do arquivo `.txt` local e injeção reativa do valor no Firebase e no Riverpod.
