# Task 7: Visibilidade Global - Armazenamento Público e Indexação no MediaScanner do Android

## 📌 Descrição Aprofundada
Garantir que as músicas baixadas sejam salvas no diretório público de música do dispositivo (`/storage/emulated/0/Music/MyMusicOnline/`) e indexadas no banco de dados de mídia do sistema Android via `MediaScannerConnection`. Isso torna os arquivos `.mp3` e `.m4a` imediatamente visíveis no explorador de arquivos "Meus Arquivos" e em outros aplicativos reprodutores de mídia (Samsung Music, VLC, tocadores de carro, pendrives, etc.).

## 🎯 Escopo da Task
1. **Permissões no Manifest (`android/app/src/main/AndroidManifest.xml`)**:
   - Adicionar permissões de armazenamento externo `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` e `READ_MEDIA_AUDIO` (Android 13+).

2. **MethodChannel Nativo do MediaScanner (`android/app/src/main/kotlin/com/arttecsoftware/my_music_online/MainActivity.kt`)**:
   - Registrar o canal de plataforma `com.arttecsoftware.my_music_online/media_scanner`.
   - Executar `MediaScannerConnection.scanFile()` ao receber o caminho do arquivo baixado.

3. **Diretório Público & Indexação (`lib/src/features/download/data/services/audio_downloader_service.dart`)**:
   - Atualizar `_getBaseDirectory()` para salvar na pasta pública `/storage/emulated/0/Music/MyMusicOnline/` (com fallback gracioso).
   - Invocação do `MethodChannel` para indexar o arquivo via `MediaScannerConnection` assim que o download for concluído com sucesso.

## 📋 Arquivos a Criar / Modificar
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/arttecsoftware/my_music_online/MainActivity.kt`
- `lib/src/features/download/data/services/audio_downloader_service.dart`
- `docs/feature/download/plan.md`
- `docs/feature/download/task-7-public-storage-and-mediascanner.md` (Novo)

## ✅ Critérios de Aceite
- Músicas salvas na pasta pública `Armazenamento Interno > Music > MyMusicOnline > {Playlist}/`.
- Arquivos visíveis no aplicativo "Meus Arquivos" (File Explorer) do Android.
- Indexação imediata no banco do sistema Android para exibição em outros players de mídia (Samsung Music, VLC, etc.).
