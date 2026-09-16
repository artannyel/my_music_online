import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../download/domain/models/download_task_model.dart';
import '../../../download/presentation/controllers/download_controller.dart';

class CookiesSettingsScreen extends ConsumerWidget {
  const CookiesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authControllerProvider);
    final isLoggingOut = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? _buildGuestView(context)
          : _buildUserSettings(context, ref, user, isLoggingOut),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Entre na sua conta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Faça login para salvar suas playlists, sincronizar entre dispositivos e aproveitar todos os recursos.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(RouteNames.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fazer Login ou Cadastrar-se',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildUserSettings(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    bool isLoggingOut,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildUserCard(user),
          const SizedBox(height: 24),
          _buildMenuSection(context, ref),
          const SizedBox(height: 32),
          _buildLogoutButton(ref, isLoggingOut),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.cardBackground,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Usuário',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadControllerProvider);
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.download_for_offline_rounded,
            title: 'Downloads & Músicas Off-line',
            subtitle: '${downloadState.offlineTracks.length} faixas salvas',
            onTap: () => context.push(RouteNames.downloads),
          ),
          const Divider(color: AppColors.divider, height: 1, indent: 56),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.audio_file_rounded, color: AppColors.primary, size: 22),
            ),
            title: const Text(
              'Formato dos Downloads',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              downloadState.preferredFormat.label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: DropdownButton<AudioFormat>(
              value: downloadState.preferredFormat,
              dropdownColor: AppColors.surface,
              underline: const SizedBox.shrink(),
              items: AudioFormat.values.map((fmt) {
                return DropdownMenuItem<AudioFormat>(
                  value: fmt,
                  child: Text(
                    fmt.name.toUpperCase(),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (newFmt) {
                if (newFmt != null) {
                  downloadNotifier.setPreferredFormat(newFmt);
                }
              },
            ),
          ),
          const Divider(color: AppColors.divider, height: 1, indent: 56),
          _buildMenuItem(
            icon: Icons.graphic_eq_rounded,
            title: 'Equalizador de Áudio',
            subtitle: 'Controles de som e presets',
            onTap: () => context.push(RouteNames.equalizer),
          ),
          const Divider(color: AppColors.divider, height: 1, indent: 56),
          _buildMenuItem(
            icon: Icons.cookie_outlined,
            title: 'Cookies do YouTube',
            subtitle: 'Gerenciar arquivo de cookies',
            onTap: () => context.push(RouteNames.cookiesManagement),
          ),
          const Divider(color: AppColors.divider, height: 1, indent: 56),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Versão',
            subtitle: '1.0.0+1',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(WidgetRef ref, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => ref.read(authControllerProvider.notifier).logout(),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : const Icon(Icons.logout_rounded, color: AppColors.error),
        label: Text(
          isLoading ? 'Saindo...' : 'Sair da Conta',
          style: const TextStyle(
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
}
