# Task 8: Otimização de Performance - High-Speed Downloads, Throttling de Progresso & Concorrência Paralela

## 📌 Descrição Aprofundada
Otimizar a velocidade de download de faixas e playlists eliminando o gargalo de processamento do evento de progresso no ciclo do Dart (Event Loop) e permitindo o download simultâneo de até 2 faixas em paralelo em playlists.

## 🎯 Escopo da Task
1. **Throttling no Loop de Stream (`AudioDownloaderService.downloadTrack`)**:
   - Reduzir a emissão de eventos `yield` no stream de download.
   - Em vez de disparar `yield` a cada pequeno bloco de 8KB (que sobrecarregava o aplicativo com ~1.000 chamadas por música), acumular a gravação em disco na velocidade total do socket TCP.
   - Disparar `yield` apenas quando o progresso avançar pelo menos **2%** ou a cada **250 milissegundos**, além da conclusão (100%).

2. **Download Paralelo de Playlists (`DownloadController.downloadPlaylist`)**:
   - Implementar um pool de execução concorrente controlada para baixar **2 faixas simultaneamente**.
   - Assim que uma música termina de baixar, a próxima da fila inicia automaticamente em paralelo.

3. **Persistência de Conexão (HTTP Pool & Keep-Alive)**:
   - Reutilizar a instância do `http.Client` mantendo conexões TCP abertas com os servidores de mídia.

## 📋 Arquivos a Criar / Modificar
- `lib/src/features/download/data/services/audio_downloader_service.dart`
- `lib/src/features/download/presentation/controllers/download_controller.dart`
- `docs/feature/download/plan.md`
- `docs/feature/download/task-8-speed-and-concurrency-optimizations.md` (Novo)

## ✅ Critérios de Aceite
- Downloads de faixas individuais concluem em tempo recorde aproveitando toda a largura de banda da rede.
- Playlists são baixadas com processamento de 2 faixas em paralelo.
- Consumo de CPU e travamentos durante o download são reduzidos drasticamente.
