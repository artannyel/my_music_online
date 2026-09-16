# Plano de Implementação - Feature: Download & Reprodução Off-line

## 1. Visão Geral
A feature `download` permite baixar faixas individuais ou playlists inteiras para o armazenamento do dispositivo, possibilitando a escuta de músicas sem conexão com a internet (*Modo Off-line*). 

### Estrutura de Arquivos e Formatos:
- **Organização por Pastas Físicas**:
  - Playlists são salvas em diretórios dedicados: `Music/MyMusicOnline/{Nome da Playlist}/`
  - Downloads avulsos são salvos em: `Music/MyMusicOnline/Downloads/`
  - Nomenclatura padronizada de arquivos: `{Nome da Música} - {Artista}.{ext}` para fácil identificação em outros players de mídia, gerenciadores de arquivos ou pendrives.
- **Formatos de Áudio Configuráveis**:
  - **Padrão (`.m4a`)**: Download rápido da stream AAC original, ideal para uso no smartphone sem gasto extra de bateria/processamento.
  - **Opção Universal (`.mp3`)**: Conversão/codificação para MP3 universal, ideal para cópia para pendrives e reprodução em som de carro ou tocadores antigos.

## 2. Referência de Design & UX (Stitch & YouTube Music)
- **Visual**: Tema escuro com ícones de estado de download (Pendente ⏳, Baixando 🔄 com porcentagem circular, Concluído 🟢 e Erro ⚠️).
- **Ações**:
  - Central de Downloads em Andamento na `DownloadsScreen`: Exibe em tempo real faixas baixando, fila pendente, barras de progresso lineares e botões para cancelar downloads individualmente ou limpar toda a fila.
  - Botão de "Baixar Playlist" no cabeçalho da página de detalhes de playlist (`PlaylistDetailScreen`), atualizando em tempo real os ícones adaptativos de cada faixa da lista.
  - Opção "Baixar para ouvir off-line" no menu contextual das músicas (`SongContextMenuBottomSheet`) e player expandido (`FullPlayerScreen`).
  - Opção de escolha de formato (`.m4a` ou `.mp3`) nas Configurações (`CookiesSettingsScreen`).
  - Tela dedicada de "Downloads & Off-line" (`DownloadsScreen`) com suporte a limpeza completa de armazenamento e agrupamento por pastas físicas.

## 3. Arquitetura da Feature
```text
lib/src/features/download/
├── domain/
│   ├── models/
│   │   ├── download_task_model.dart
│   │   └── offline_track_model.dart
│   └── repositories/
│       └── download_repository.dart
├── data/
│   ├── services/
│   │   └── audio_downloader_service.dart
│   └── repositories/
│       └── local_download_repository.dart
└── presentation/
    ├── controllers/
    │   └── download_controller.dart
    ├── views/
    │   └── downloads_screen.dart
    └── widgets/
        ├── download_button_widget.dart
        └── download_progress_indicator_widget.dart
```

## 4. Divisão de Tasks
- [x] [Task 1: Domain - Modelos DownloadTaskModel, OfflineTrackModel e Interface DownloadRepository](./task-1-domain-models.md)
- [x] [Task 2: Data - Serviço de Download (AudioDownloaderService com suporte a pastas e formato MP3/M4A) e Repositório Local](./task-2-download-service-and-repository.md)
- [x] [Task 3: Presentation - Controller Riverpod (DownloadController & Providers)](./task-3-download-riverpod-controller.md)
- [x] [Task 4: Presentation - UI de Downloads, Botões, Seletor de Formato e Tela de Músicas Off-line](./task-4-download-ui-and-offline-library.md)
- [x] [Task 5: Integration - Notificações Nativas de Progresso de Download (Background & Cortina de Notificações)](./task-5-download-notifications.md)
- [x] [Task 6: Resiliência - Persistência da Fila de Downloads & Retomada Automática (Auto-Resume)](./task-6-download-queue-persistence.md)
- [x] [Task 7: Visibilidade Global - Armazenamento Público e Indexação no MediaScanner do Android](./task-7-public-storage-and-mediascanner.md)

