import 'package:flutter/foundation.dart';

/// Modelo de domínio que representa um Preset do Equalizador com os ganhos de cada frequência (em dB).
@immutable
class EqualizerPresetModel {
  final String id;
  final String name;
  final Map<double, double> bandGains;
  final bool isCustom;

  const EqualizerPresetModel({
    required this.id,
    required this.name,
    required this.bandGains,
    this.isCustom = false,
  });

  /// Frequências padrão suportadas pelo Equalizador (em Hz).
  static const List<double> defaultFrequencies = [60.0, 230.0, 910.0, 3600.0, 14000.0];

  EqualizerPresetModel copyWith({
    String? id,
    String? name,
    Map<double, double>? bandGains,
    bool? isCustom,
  }) {
    return EqualizerPresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bandGains: bandGains ?? Map<double, double>.from(this.bandGains),
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bandGains': bandGains.map((key, value) => MapEntry(key.toString(), value)),
      'isCustom': isCustom,
    };
  }

  factory EqualizerPresetModel.fromJson(Map<String, dynamic> json) {
    final rawGains = json['bandGains'] as Map<String, dynamic>? ?? {};
    final parsedGains = <double, double>{};
    rawGains.forEach((key, value) {
      final freq = double.tryParse(key);
      final gain = (value as num?)?.toDouble();
      if (freq != null && gain != null) {
        parsedGains[freq] = gain;
      }
    });

    return EqualizerPresetModel(
      id: json['id'] as String? ?? 'custom',
      name: json['name'] as String? ?? 'Personalizado',
      bandGains: parsedGains,
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqualizerPresetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isCustom == other.isCustom &&
          mapEquals(bandGains, other.bandGains);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ isCustom.hashCode ^ bandGains.hashCode;
}
