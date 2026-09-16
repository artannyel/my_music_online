import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/domain/models/player_state_model.dart';
import '../../domain/models/download_task_model.dart';
import '../controllers/download_controller.dart';

/// DownloadButtonWidget exibe um botão adaptativo para iniciar o download de uma faixa,
/// indicando o progresso em tempo real ou se o arquivo já se encontra salvo off-line.
class DownloadButtonWidget extends ConsumerWidget {
  final AudioTrackModel track;
  final String? playlistName;
  final double iconSize;

  const DownloadButtonWidget({
    super.key,
    required this.track,
    this.playlistName,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded = ref.watch(isTrackDownloadedProvider(track.id));
    final activeTask = ref.watch(trackDownloadTaskProvider(track.id));

    if (isDownloaded) {
      return IconButton(
        icon: Icon(Icons.check_circle_rounded, color: AppColors.success, size: iconSize),
        tooltip: 'Música salva off-line',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta faixa já está salva no seu dispositivo.'),
              backgroundColor: AppColors.surface,
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    if (activeTask != null) {
      if (activeTask.status == DownloadStatus.pending) {
        return IconButton(
          icon: Icon(Icons.schedule_rounded, color: AppColors.secondary, size: iconSize),
          tooltip: 'Na fila de download (Aguardando...)',
          onPressed: () {
            ref.read(downloadControllerProvider.notifier).cancelDownload(track.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download da faixa cancelado.'),
                backgroundColor: AppColors.surface,
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      }

      if (activeTask.status == DownloadStatus.downloading) {
        final progress = activeTask.progress;
        final percentStr = (progress * 100).toInt();

        return Tooltip(
          message: 'Baixando ($percentStr%) - Toque para cancelar',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              ref.read(downloadControllerProvider.notifier).cancelDownload(track.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download da faixa cancelado.'),
                  backgroundColor: AppColors.surface,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                      backgroundColor: AppColors.cardBackground,
                    ),
                    Text(
                      '$percentStr%',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return IconButton(
      icon: Icon(Icons.download_for_offline_rounded, color: AppColors.textSecondary, size: iconSize),
      tooltip: 'Baixar música off-line',
      onPressed: () {
        ref.read(downloadControllerProvider.notifier).downloadTrack(
              track,
              playlistName: playlistName,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Iniciando download de "${track.title}"...'),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
