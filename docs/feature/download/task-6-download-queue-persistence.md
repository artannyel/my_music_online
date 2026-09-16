# Task 6: Resiliência - Persistência da Fila de Downloads & Retomada Automática (Auto-Resume)

## 📌 Descrição Aprofundada
Garantir que a fila de downloads em andamento e pendentes não seja perdida quando o aplicativo for fechado ou encerrado pelo sistema operacional. Ao abrir o aplicativo novamente, a fila é carregada do armazenamento local e os downloads não concluídos são retomados automaticamente.

## 🎯 Escopo da Task
1. **Repositório Local (`DownloadRepository` & `LocalDownloadRepository`)**:
   - `saveActiveQueue(Map<String, DownloadTaskModel> activeDownloads)`: Serializa a fila ativa em JSON e salva no `SharedPreferences` sob a chave `'active_download_queue'`.
   - `getActiveQueue()`: Carrega e desserializa a fila salva no `SharedPreferences`.

2. **Controller de Downloads (`DownloadController`)**:
   - Na inicialização (`_init`), carregar `getActiveQueue()`.
   - Caso existam tarefas salvas (com status `pending` ou `downloading`), converter seus estados para `pending` e atualizar `state.activeDownloads`.
   - Disparar automaticamente o método `_resumePendingDownloads()` para processar a fila sem intervenção do usuário.
   - Sincronizar o estado da fila com o disco (`saveActiveQueue`) sempre que uma faixa for adicionada, concluída, falhar ou for cancelada.

3. **Validação & Testes Unitários**:
   - Adicionar testes de unidade para `saveActiveQueue` e `getActiveQueue` em `test/features/download/download_test.dart`.

## 📋 Arquivos a Criar / Modificar
- `lib/src/features/download/domain/repositories/download_repository.dart`
- `lib/src/features/download/data/repositories/local_download_repository.dart`
- `lib/src/features/download/presentation/controllers/download_controller.dart`
- `test/features/download/download_test.dart`
- `docs/feature/download/plan.md`
- `docs/feature/download/task-6-download-queue-persistence.md` (Novo)

## ✅ Critérios de Aceite
- Ao fechar e reabrir o app durante um download, a fila ativa é preservada na totalidade.
- Downloads interrompidos continuam automaticamente da faixa pendente ao iniciar o app.
- Downloads concluídos ou cancelados são removidos corretamente da persistência local.
