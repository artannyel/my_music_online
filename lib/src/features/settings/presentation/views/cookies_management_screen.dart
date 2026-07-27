import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/settings_controller.dart';

class CookiesManagementScreen extends ConsumerStatefulWidget {
  const CookiesManagementScreen({super.key});

  @override
  ConsumerState<CookiesManagementScreen> createState() => _CookiesManagementScreenState();
}

class _CookiesManagementScreenState extends ConsumerState<CookiesManagementScreen> {
  late final TextEditingController _textController;
  bool _hasEdited = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cookiesAsync = ref.watch(ytCookiesProvider);
    final saveState = ref.watch(settingsControllerProvider);
    final isLoading = saveState.isLoading;
    final cookiesText = cookiesAsync.valueOrNull;

    if (!_hasEdited && cookiesText != null && _textController.text.isEmpty) {
      _textController.text = cookiesText;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cookies do YouTube',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(cookiesText),
            const SizedBox(height: 24),
            _buildSectionTitle('Arquivo cookies.txt'),
            const SizedBox(height: 8),
            _buildFilePickerButton(isLoading),
            const SizedBox(height: 24),
            _buildSectionTitle('Editar Manualmente'),
            const SizedBox(height: 8),
            _buildCookiesTextField(isLoading),
            const SizedBox(height: 16),
            _buildSaveButton(isLoading),
            const SizedBox(height: 12),
            if (cookiesText != null) _buildRemoveButton(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String? cookiesText) {
    final hasCookies = cookiesText != null && cookiesText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCookies ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasCookies
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasCookies ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: hasCookies ? AppColors.success : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCookies ? 'Cookies Ativos' : 'Nenhum Cookie Configurado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCookies
                      ? '${cookiesText.length} caracteres salvos no Firebase'
                      : 'Adicione cookies para acessar o YouTube Music',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildFilePickerButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => ref.read(settingsControllerProvider.notifier).uploadCookiesFile(),
        icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
        label: const Text(
          'Selecionar Arquivo cookies.txt',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }

  Widget _buildCookiesTextField(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: _textController,
        enabled: !isLoading,
        maxLines: 10,
        minLines: 6,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText:
              'Cole ou digite aqui o conteúdo\ndo arquivo cookies.txt...',
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        onChanged: (_) => _hasEdited = true,
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                final text = _textController.text;
                if (text.trim().isEmpty) {
                  _showError('O texto dos cookies está vazio.');
                  return;
                }
                await ref
                    .read(settingsControllerProvider.notifier)
                    .saveCookiesText(text);
                if (!context.mounted) return;
                final state = ref.read(settingsControllerProvider);
                if (state.hasError) {
                  _showError(state.error.toString());
                } else {
                  _showSuccess('Cookies salvos com sucesso!');
                }
              },
        icon: const Icon(Icons.save_rounded, color: Colors.white),
        label: const Text(
          'Salvar no Firebase',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text(
                      'Remover Cookies',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    content: const Text(
                      'Tem certeza? Os cookies salvos serão apagados do Firebase.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Remover',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                await ref
                    .read(settingsControllerProvider.notifier)
                    .removeCookies();
                if (!context.mounted) return;
                final state = ref.read(settingsControllerProvider);
                if (state.hasError) {
                  _showError(state.error.toString());
                } else {
                  _textController.clear();
                  _hasEdited = false;
                  _showSuccess('Cookies removidos.');
                }
              },
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        label: const Text(
          'Remover Cookies',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
