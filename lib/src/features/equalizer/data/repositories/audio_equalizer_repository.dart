import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/equalizer_preset_model.dart';
import '../../domain/repositories/equalizer_repository.dart';

const String _prefsEqEnabledKey = 'equalizer_enabled';
const String _prefsEqPresetIdKey = 'equalizer_preset_id';
const String _prefsEqGainsKey = 'equalizer_band_gains';

/// Repositório concreto para gerenciamento e persistência da equalização de áudio.
class AudioEqualizerRepository implements EqualizerRepository {
  static final List<EqualizerPresetModel> defaultPresets = [
    EqualizerPresetModel(
      id: 'flat',
      name: 'Flat',
      bandGains: {60.0: 0.0, 230.0: 0.0, 910.0: 0.0, 3600.0: 0.0, 14000.0: 0.0},
    ),
    EqualizerPresetModel(
      id: 'bass_boost',
      name: 'Bass Boost',
      bandGains: {60.0: 6.0, 230.0: 4.0, 910.0: 0.0, 3600.0: -1.0, 14000.0: -2.0},
    ),
    EqualizerPresetModel(
      id: 'rock',
      name: 'Rock',
      bandGains: {60.0: 4.0, 230.0: 2.0, 910.0: -1.0, 3600.0: 3.0, 14000.0: 5.0},
    ),
    EqualizerPresetModel(
      id: 'pop',
      name: 'Pop',
      bandGains: {60.0: -1.0, 230.0: 2.0, 910.0: 4.0, 3600.0: 2.0, 14000.0: -1.0},
    ),
    EqualizerPresetModel(
      id: 'jazz',
      name: 'Jazz',
      bandGains: {60.0: 3.0, 230.0: 2.0, 910.0: -1.0, 3600.0: 2.0, 14000.0: 4.0},
    ),
    EqualizerPresetModel(
      id: 'eletronica',
      name: 'Eletrônica',
      bandGains: {60.0: 5.0, 230.0: 3.0, 910.0: 0.0, 3600.0: 2.0, 14000.0: 4.0},
    ),
  ];

  @override
  Future<List<EqualizerPresetModel>> getPresets() async {
    return defaultPresets;
  }

  @override
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsEqEnabledKey) ?? true;
    } catch (e) {
      debugPrint('[AudioEqualizerRepository] Erro ao obter status do equalizador: $e');
      return true;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsEqEnabledKey, enabled);
    } catch (e) {
      debugPrint('[AudioEqualizerRepository] Erro ao salvar status do equalizador: $e');
    }
  }

  @override
  Future<Map<double, double>> getBandGains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGains = prefs.getString(_prefsEqGainsKey);

      if (savedGains != null && savedGains.isNotEmpty) {
        final decoded = json.decode(savedGains) as Map<String, dynamic>;
        final map = <double, double>{};
        decoded.forEach((key, value) {
          final freq = double.tryParse(key);
          final gain = (value as num?)?.toDouble();
          if (freq != null && gain != null) {
            map[freq] = gain;
          }
        });
        if (map.isNotEmpty) return map;
      }
    } catch (e) {
      debugPrint('[AudioEqualizerRepository] Erro ao obter ganhos das bandas: $e');
    }

    return Map<double, double>.from(defaultPresets.first.bandGains);
  }

  @override
  Future<void> setBandGain(double frequencyHz, double gainDb) async {
    try {
      final currentGains = await getBandGains();
      final clampedGain = gainDb.clamp(-12.0, 12.0);
      currentGains[frequencyHz] = clampedGain;

      final prefs = await SharedPreferences.getInstance();
      final jsonGains = json.encode(
        currentGains.map((key, value) => MapEntry(key.toString(), value)),
      );
      await prefs.setString(_prefsEqGainsKey, jsonGains);
      await prefs.setString(_prefsEqPresetIdKey, 'custom');
    } catch (e) {
      debugPrint('[AudioEqualizerRepository] Erro ao definir ganho da banda: $e');
    }
  }

  @override
  Future<void> applyPreset(EqualizerPresetModel preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsEqPresetIdKey, preset.id);

      final jsonGains = json.encode(
        preset.bandGains.map((key, value) => MapEntry(key.toString(), value)),
      );
      await prefs.setString(_prefsEqGainsKey, jsonGains);
    } catch (e) {
      debugPrint('[AudioEqualizerRepository] Erro ao aplicar preset: $e');
    }
  }

  @override
  Future<void> resetToFlat() async {
    final flatPreset = defaultPresets.firstWhere(
      (p) => p.id == 'flat',
      orElse: () => defaultPresets.first,
    );
    await applyPreset(flatPreset);
  }
}
