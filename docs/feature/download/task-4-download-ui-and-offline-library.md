# Task 4: Presentation - UI de Downloads, Botões, Seletor de Formato e Tela de Músicas Off-line

## 📌 Descrição Aprofundada
Construir os componentes visuais para iniciar downloads, acompanhar o progresso em tempo real, escolher o formato de saída (`.m4a` ou `.mp3`) e navegar pelas pastas de playlists e músicas baixadas.

## 🎯 Escopo da Task
1. Componentes visuais (`lib/src/features/download/presentation/widgets/`):
   - `DownloadButtonWidget`: Botão adaptativo com ícones de estado:
     - ⬇️ **Disponível para download**: Ícone de seta para baixo.
     - 🔄 **Baixando**: Indicador circular de progresso com porcentagem.
     - ✅ **Baixado**: Ícone de verificação em destaque.
2. Seletor de Formato de Áudio nas Configurações (`CookiesSettingsScreen`):
   - Chave de alternância ou modal para escolher o formato padrão:
     - 🎵 **M4A (AAC)**: Recomendado (Download ultrarrápido).
     - 🚗 **MP3 Universal**: Para pendrives e tocadores de carro antigos.
3. Tela de Músicas e Playlists Off-line (`lib/src/features/download/presentation/views/downloads_screen.dart`):
   - Header com indicação do espaço ocupado em MB/GB.
   - Aba **Playlists Baixadas**: Visualização por pastas físicas (`Music/MyMusicOnline/{Nome da Playlist}/`).
   - Aba **Músicas Avulsas**: Lista de faixas avulsas baixadas.
   - Botões "Tocar Tudo Off-line" e "Modo Aleatório Off-line".
   - Opção de excluir pastas de playlists completas ou faixas individuais.
4. Integração com telas existentes:
   - Adicionar botão "Baixar Playlist" no cabeçalho de `PlaylistDetailScreen`.
   - Adicionar botão de download na `FullPlayerScreen` e atalho no menu principal.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/download/presentation/views/downloads_screen.dart`
- `lib/src/features/download/presentation/widgets/download_button_widget.dart`
- Modificações de integração em:
  - `lib/src/features/playlist/presentation/views/playlist_detail_screen.dart`
  - `lib/src/features/player/presentation/views/full_player_screen.dart`
  - `lib/src/features/settings/presentation/views/cookies_settings_screen.dart`
  - `lib/src/core/router/app_router.dart`

## ✅ Critérios de Aceite
- Download de playlist inteira criando pasta física com o nome da playlist.
- Arquivos de áudio salvos com nomes limpos `{Música} - {Artista}.{ext}` acessíveis por pendrives e outros players.
- Seletor de formato `.m4a` / `.mp3` nas configurações funcionando corretamente.
- Reprodução fluída sem internet de todas as faixas salvas.
