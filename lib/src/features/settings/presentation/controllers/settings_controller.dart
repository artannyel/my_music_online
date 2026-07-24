import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_settings_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FirestoreSettingsRepository();
});

/// Provider que escuta cookies do usuário atual (ou null se não logado).
final ytCookiesProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;
  if (userId == null) return Stream.value(null);
  return ref.watch(settingsRepositoryProvider).watchCookies(userId: userId);
});

class SettingsController extends StateNotifier<AsyncValue<void>> {
  final SettingsRepository _repository;
  final Ref _ref;

  SettingsController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> uploadCookiesFile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null || result.files.isEmpty) {
        throw const SettingsException('Nenhum arquivo selecionado.');
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        throw const SettingsException('Nao foi possivel acessar o arquivo.');
      }

      final file = File(filePath);
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        throw const SettingsException('O arquivo esta vazio.');
      }

      await _repository.saveCookies(content, userId: _userId());
    });
  }

  Future<void> saveCookiesText(String text) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (text.trim().isEmpty) {
        throw const SettingsException('O texto dos cookies esta vazio.');
      }
      await _repository.saveCookies(text, userId: _userId());
    });
  }

  Future<void> removeCookies() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.removeCookies(userId: _userId()));
  }

  String _userId() {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw const SettingsException('Usuário não autenticado.');
    return user.id;
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider), ref);
});

class SettingsException implements Exception {
  final String message;
  const SettingsException(this.message);

  @override
  String toString() => message;
}
