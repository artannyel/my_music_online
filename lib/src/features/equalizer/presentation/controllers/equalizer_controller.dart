import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/audio_equalizer_repository.dart';
import '../../domain/models/equalizer_preset_model.dart';
import '../../domain/repositories/equalizer_repository.dart';
import '../../../player/presentation/controllers/player_controller.dart';

/// Provider do repositório de equalização.
final equalizerRepositoryProvider = Provider<EqualizerRepository>((ref) {
  final audioService = ref.watch(audioPlayerServiceProvider);
  return AudioEqualizerRepository(audioPlayerService: audioService);
});

/// Estado reativo do Equalizador.
@immutable
class EqualizerState {
  final bool isEnabled;
  final EqualizerPresetModel? selectedPreset;
  final Map<double, double> bandGains;
  final List<EqualizerPresetModel> availablePresets;
  final bool isLoading;

  const EqualizerState({
    this.isEnabled = true,
    this.selectedPreset,
    this.bandGains = const {},
    this.availablePresets = const [],
    this.isLoading = false,
  });

  EqualizerState copyWith({
    bool? isEnabled,
    EqualizerPresetModel? selectedPreset,
    bool clearSelectedPreset = false,
    Map<double, double>? bandGains,
    List<EqualizerPresetModel>? availablePresets,
    bool? isLoading,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedPreset: clearSelectedPreset ? null : (selectedPreset ?? this.selectedPreset),
      bandGains: bandGains ?? Map<double, double>.from(this.bandGains),
      availablePresets: availablePresets ?? this.availablePresets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller reativo do Equalizador de Áudio.
class EqualizerController extends StateNotifier<EqualizerState> {
  final EqualizerRepository _repository;

  EqualizerController(this._repository) : super(const EqualizerState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final presets = await _repository.getPresets();
      final enabled = await _repository.isEnabled();
      final gains = await _repository.getBandGains();

      if (_repository is AudioEqualizerRepository) {
        await _repository.initAudioEffects();
      }

      EqualizerPresetModel? matchedPreset;
      for (final preset in presets) {
        if (_areGainsMatching(preset.bandGains, gains)) {
          matchedPreset = preset;
          break;
        }
      }

      state = EqualizerState(
        isEnabled: enabled,
        selectedPreset: matchedPreset,
        bandGains: gains,
        availablePresets: presets,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[EqualizerController] Erro na inicialização: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  bool _areGainsMatching(Map<double, double> pGains, Map<double, double> cGains) {
    if (pGains.length != cGains.length) return false;
    for (final entry in pGains.entries) {
      final cVal = cGains[entry.key];
      if (cVal == null || (cVal - entry.value).abs() > 0.01) {
        return false;
      }
    }
    return true;
  }

  /// Liga / Desliga o equalizador mestre.
  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _repository.setEnabled(enabled);
  }

  /// Ajusta o ganho dB de uma banda de frequência específica.
  Future<void> setBandGain(double frequencyHz, double gainDb) async {
    final newGains = Map<double, double>.from(state.bandGains);
    newGains[frequencyHz] = gainDb.clamp(-12.0, 12.0);

    EqualizerPresetModel? matchedPreset;
    for (final preset in state.availablePresets) {
      if (_areGainsMatching(preset.bandGains, newGains)) {
        matchedPreset = preset;
        break;
      }
    }

    state = state.copyWith(
      bandGains: newGains,
      selectedPreset: matchedPreset,
      clearSelectedPreset: matchedPreset == null,
    );

    await _repository.setBandGain(frequencyHz, gainDb);
  }

  /// Aplica um preset pré-configurado.
  Future<void> selectPreset(EqualizerPresetModel preset) async {
    final newGains = Map<double, double>.from(preset.bandGains);
    state = state.copyWith(
      selectedPreset: preset,
      bandGains: newGains,
    );
    await _repository.applyPreset(preset);
  }

  /// Reseta todas as bandas para Flat (0 dB).
  Future<void> resetToFlat() async {
    final flatPreset = state.availablePresets.firstWhere(
      (p) => p.id == 'flat',
      orElse: () => EqualizerPresetModel(
        id: 'flat',
        name: 'Flat',
        bandGains: {60.0: 0.0, 230.0: 0.0, 910.0: 0.0, 3600.0: 0.0, 14000.0: 0.0},
      ),
    );
    await selectPreset(flatPreset);
  }
}

/// Provider global para a instância do EqualizerController.
final equalizerControllerProvider =
    StateNotifierProvider<EqualizerController, EqualizerState>((ref) {
  final repository = ref.watch(equalizerRepositoryProvider);
  return EqualizerController(repository);
});
