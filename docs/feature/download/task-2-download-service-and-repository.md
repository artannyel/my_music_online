# Task 2: Data - Serviço de Download (AudioDownloaderService) e Repositório Local

## 📌 Descrição Aprofundada
Implementar o serviço responsável por extrair a stream de áudio do YouTube, organizar a criação de pastas físicas por playlist e salvar os arquivos de áudio em formato `.m4a` (padrão) ou `.mp3` (conversão universal) no armazenamento do dispositivo.

## 🎯 Escopo da Task
1. Criar `lib/src/features/download/data/services/audio_downloader_service.dart`:
   - Utilizar `yt_extractor` / `http` para obter o fluxo de áudio da música.
   - **Gerenciamento de Pastas Físicas**:
     - Se o download for parte de uma playlist, criar a subpasta: `Music/MyMusicOnline/{Nome da Playlist}/`
     - Se for download avulso, salvar em: `Music/MyMusicOnline/Downloads/`
     - Sanitizar caracteres inválidos no sistema de arquivos (`/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`).
     - Nomear arquivo no formato: `{Nome da Música} - {Artista}.{ext}`.
   - **Formatos de Áudio**:
     - Gravador direto para `.m4a` (stream AAC nativa de alta velocidade).
     - Suporte a conversão/transcodificação para `.mp3` universal quando selecionado nas opções do usuário.
   - Notificar progresso de download em tempo real via `Stream<DownloadTaskModel>`.
   - Lidar com cancelamentos e tratamento de erros de rede de forma resiliente.
2. Criar `lib/src/features/download/data/repositories/local_download_repository.dart`:
   - Implementar `DownloadRepository`.
   - Persistir o índice de músicas baixadas e preferência de formato no `SharedPreferences` ou arquivo JSON indexador no diretório local.
   - Suportar remoção física do arquivo de áudio e da pasta vazia ao excluir uma faixa/playlist off-line.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/download/data/services/audio_downloader_service.dart`
- `lib/src/features/download/data/repositories/local_download_repository.dart`

## ✅ Critérios de Aceite
- Pastas físicas criadas com o nome da playlist na memória do dispositivo.
- Nome dos arquivos limpos no formato `{Música} - {Artista}.{ext}` acessíveis por outros tocadores de mídia e pendrives.
- Atualização precisa do progresso em porcentagem e exclusão do arquivo físico ao apagar.
