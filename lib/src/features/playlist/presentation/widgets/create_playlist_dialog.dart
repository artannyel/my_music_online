import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/playlist_controller.dart';

/// Modal dialog estilizado para criar uma nova playlist personalizada.
class CreatePlaylistDialog extends ConsumerStatefulWidget {
  final String userId;

  const CreatePlaylistDialog({
    super.key,
    required this.userId,
  });

  static Future<dynamic> show(BuildContext context, {required String userId}) {
    return showDialog(
      context: context,
      builder: (context) => CreatePlaylistDialog(userId: userId),
    );
  }

  @override
  ConsumerState<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final playlist = await ref.read(playlistMutationsProvider.notifier).createPlaylist(
          userId: widget.userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (playlist != null) {
        Navigator.of(context).pop(playlist);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "${playlist.title}" criada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar playlist. Tente novamente.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.playlist_add, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Nova Playlist',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Título da Playlist *',
                  hintText: 'Minhas Músicas Favoritas',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe um título para a playlist';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Músicas para relaxar no fim de semana...',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.textPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Criar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
