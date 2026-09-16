import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço responsável por gerenciar as notificações nativas de progresso de download
/// na cortina do Android e iOS em tempo real.
class DownloadNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  static const String _channelId = 'download_channel';
  static const String _channelName = 'Downloads de Áudio';
  static const String _channelDescription =
      'Exibe o progresso dos downloads em tempo real em segundo plano';

  DownloadNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Inicializa as configurações de notificação e registra os canais nativos.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Solicita permissão no Android 13+ (POST_NOTIFICATIONS)
      if (!kIsWeb) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[DownloadNotificationService] Erro ao inicializar notificações: $e');
    }
  }

  /// Exibe ou atualiza a notificação contínua (`ongoing`) de progresso de um download.
  Future<void> showDownloadProgress({
    required int id,
    required String title,
    required String body,
    required double progress,
  }) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return;

    final percent = (progress * 100).toInt().clamp(0, 100);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: percent,
      ongoing: true,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[DownloadNotificationService] Erro ao exibir progresso: $e');
    }
  }

  /// Cancela a notificação de progresso e exibe uma notificação de sucesso descartável.
  Future<void> showDownloadCompleted({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'download_completed_channel',
      'Downloads Concluídos',
      channelDescription: 'Alertas de conclusão de download de faixas e playlists',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.cancel(id);
      await _notificationsPlugin.show(
        id + 10000,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[DownloadNotificationService] Erro ao exibir conclusão: $e');
    }
  }

  /// Cancela uma notificação específica pelo ID.
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('[DownloadNotificationService] Erro ao cancelar notificação $id: $e');
    }
  }

  /// Cancela todas as notificações de download ativas.
  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('[DownloadNotificationService] Erro ao cancelar todas as notificações: $e');
    }
  }
}
