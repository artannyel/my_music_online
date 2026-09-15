import '../models/equalizer_preset_model.dart';

/// Interface do repositório para controle de equalização de áudio.
abstract class EqualizerRepository {
  /// Retorna os presets pré-definidos do equalizador (Flat, Bass Boost, Rock, Pop, etc.)
  Future<List<EqualizerPresetModel>> getPresets();

  /// Retorna se o equalizador está ativado ou desativado.
  Future<bool> isEnabled();

  /// Liga ou desliga o equalizador.
  Future<void> setEnabled(bool enabled);

  /// Retorna os ganhos das frequências atuais (frequência em Hz -> ganho em dB).
  Future<Map<double, double>> getBandGains();

  /// Define o ganho de uma frequência específica (em dB, limite -12.0 a +12.0).
  Future<void> setBandGain(double frequencyHz, double gainDb);

  /// Aplica um preset pré-configurado de equalização.
  Future<void> applyPreset(EqualizerPresetModel preset);

  /// Reseta todas as bandas para 0 dB (Flat).
  Future<void> resetToFlat();
}
