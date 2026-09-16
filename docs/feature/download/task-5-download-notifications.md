# Task 5: Integration - Notificações Nativas de Progresso de Download (Background & Cortina de Notificações)

## 📌 Descrição Aprofundada
Implementar o serviço de notificações nativas (`DownloadNotificationService`) utilizando `flutter_local_notifications` para exibir o progresso em tempo real dos downloads na cortina de notificações do Android e iOS, mesmo quando o aplicativo estiver minimizado ou em segundo plano.

## 🎯 Escopo da Task
1. **Configuração de Dependência & Permissões**:
   - Adicionar o pacote `flutter_local_notifications` ao `pubspec.yaml`.
   - Garantir a permissão `android.permission.POST_NOTIFICATIONS` no `AndroidManifest.xml` (Android 13+).
   - Configurar o ícone padrão de notificação nativa.

2. **Serviço de Notificação (`lib/src/features/download/data/services/download_notification_service.dart`)**:
   - **Inicialização (`init`)**: Criar o canal de notificação dedicado `download_channel` com som desativado (`importance: Importance.low`) para evitar alertas sonoros a cada 1% de progresso.
   - **Notificação de Progresso em Tempo Real (`showDownloadProgress`)**:
     - Notificação `ongoing: true` (fixa na cortina do SO durante o download).
     - Exibição de barra de progresso nativa (`showProgress: true`, `maxProgress: 100`, `progress: percentage`).
     - Título: `Baixando "Nome da Música"` ou `Baixando Playlist "Nome" (3/10)`.
     - Subtítulo/Corpo: `Progresso: 45% • Formato MP3`.
     - Ação nativa (Opcional): Botão "Cancelar Download" direto na notificação.
   - **Notificação de Conclusão (`showDownloadCompleted`)**:
     - Remove a notificação ongoing e exibe um alerta de sucesso (`ongoing: false`, `autoCancel: true`).
     - Título: `🟢 Download Concluído`.
     - Corpo: `Sua música "Nome da Música" está pronta para ouvir off-line.`.
   - **Cancelamento (`cancelNotification` / `cancelAll`)**:
     - Cancela a notificação quando o download é abortado pelo usuário.

3. **Integração com `DownloadController`**:
   - Disparar `showDownloadProgress` no callback de progresso de `AudioDownloaderService` / `DownloadController`.
   - Otimizar atualizações de notificação (throttle) para atualizar o progresso a cada 5% ou 500ms, evitando sobrecarga no SO.
   - Chamar `showDownloadCompleted` assim que a faixa ou playlist for salva no repositório local.

## 📋 Arquivos a Criar / Modificar
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `lib/src/features/download/data/services/download_notification_service.dart` (Novo)
- `lib/src/features/download/presentation/controllers/download_controller.dart`
- `docs/feature/download/plan.md`
- `docs/feature/download/task-5-download-notifications.md` (Novo)

## ✅ Critérios de Aceite
- Notificação fixa com barra de progresso nativa visível na barra de status do sistema durante os downloads.
- Atualização contínua do percentual (ex: 15%, 40%, 80%) mesmo com o aplicativo minimizado.
- Notificação de sucesso ao concluir o download.
- Cancelamento imediato da notificação caso o download seja interrompido pelo usuário.
