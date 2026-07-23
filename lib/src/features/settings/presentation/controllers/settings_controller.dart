import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_settings_repository.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FirestoreSettingsRepository();
});

final ytCookiesProvider = StreamProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchCookies();
});

class SettingsController extends StateNotifier<AsyncValue<void>> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(const AsyncData(null));

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
        throw const SettingsException('Não foi possível acessar o arquivo.');
      }

      final file = File(filePath);
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        throw const SettingsException('O arquivo está vazio.');
      }

      await _repository.saveCookies(content);
    });
  }

  Future<void> saveCookiesText(String text) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (text.trim().isEmpty) {
        throw const SettingsException('O texto dos cookies está vazio.');
      }
      await _repository.saveCookies(text);
    });
  }

  Future<void> removeCookies() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.removeCookies());
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

class SettingsException implements Exception {
  final String message;
  const SettingsException(this.message);

  @override
  String toString() => message;
}
