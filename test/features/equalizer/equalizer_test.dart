import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_music_online/src/features/equalizer/domain/models/equalizer_preset_model.dart';
import 'package:my_music_online/src/features/equalizer/data/repositories/audio_equalizer_repository.dart';
import 'package:my_music_online/src/features/equalizer/presentation/controllers/equalizer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EqualizerPresetModel Tests', () {
    test('criação e cópia de modelo', () {
      final preset = EqualizerPresetModel(
        id: 'test',
        name: 'Test Preset',
        bandGains: {60.0: 2.0, 230.0: 1.0},
      );

      expect(preset.id, 'test');
      expect(preset.name, 'Test Preset');
      expect(preset.bandGains[60.0], 2.0);

      final copy = preset.copyWith(name: 'Updated Test');
      expect(copy.name, 'Updated Test');
      expect(copy.id, 'test');
    });

    test('toJson e fromJson', () {
      final preset = EqualizerPresetModel(
        id: 'rock',
        name: 'Rock',
        bandGains: {60.0: 4.0, 14000.0: 5.0},
      );

      final jsonMap = preset.toJson();
      final restored = EqualizerPresetModel.fromJson(jsonMap);

      expect(restored.id, 'rock');
      expect(restored.name, 'Rock');
      expect(restored.bandGains[60.0], 4.0);
      expect(restored.bandGains[14000.0], 5.0);
    });
  });

  group('AudioEqualizerRepository Tests', () {
    test('getPresets retorna lista padrão de presets', () async {
      final repo = AudioEqualizerRepository();
      final presets = await repo.getPresets();

      expect(presets.length, 6);
      expect(presets.any((p) => p.id == 'flat'), isTrue);
      expect(presets.any((p) => p.id == 'bass_boost'), isTrue);
      expect(presets.any((p) => p.id == 'rock'), isTrue);
    });

    test('setEnabled e isEnabled persistem corretamente', () async {
      final repo = AudioEqualizerRepository();
      expect(await repo.isEnabled(), isTrue);

      await repo.setEnabled(false);
      expect(await repo.isEnabled(), isFalse);
    });

    test('setBandGain altera o ganho no repositório', () async {
      final repo = AudioEqualizerRepository();
      await repo.setBandGain(60.0, 6.0);

      final gains = await repo.getBandGains();
      expect(gains[60.0], 6.0);
    });

    test('resetToFlat restaura para Flat 0 dB', () async {
      final repo = AudioEqualizerRepository();
      await repo.setBandGain(60.0, 6.0);
      await repo.resetToFlat();

      final gains = await repo.getBandGains();
      expect(gains[60.0], 0.0);
    });
  });

  group('EqualizerController Tests', () {
    test('inicializa estado do equalizador', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(equalizerControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(equalizerControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.isEnabled, isTrue);
      expect(state.availablePresets.length, 6);
    });

    test('toggleEnabled atualiza estado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(equalizerControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.toggleEnabled(false);
      expect(container.read(equalizerControllerProvider).isEnabled, isFalse);
    });

    test('selectPreset altera preset selecionado e ganhos', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(equalizerControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final presets = container.read(equalizerControllerProvider).availablePresets;
      final bassBoost = presets.firstWhere((p) => p.id == 'bass_boost');

      await controller.selectPreset(bassBoost);
      final updatedState = container.read(equalizerControllerProvider);

      expect(updatedState.selectedPreset?.id, 'bass_boost');
      expect(updatedState.bandGains[60.0], 6.0);
    });
  });
}
