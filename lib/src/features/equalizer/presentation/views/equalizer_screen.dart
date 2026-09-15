import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/equalizer_controller.dart';

/// EqualizerScreen exibe uma interface gráfica elegante no estilo mesa de som digital (Stitch Design)
/// com controle Mestre ON/OFF, seletor de presets e sliders verticais de ganho por frequência.
class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  static const List<double> _frequencies = [60.0, 230.0, 910.0, 3600.0, 14000.0];

  String _formatFrequency(double freqHz) {
    if (freqHz >= 1000) {
      final khz = freqHz / 1000;
      return '${khz.toStringAsFixed(khz % 1 == 0 ? 0 : 1)}kHz';
    }
    return '${freqHz.toInt()}Hz';
  }

  String _formatGain(double gainDb) {
    if (gainDb > 0) return '+${gainDb.toStringAsFixed(1)} dB';
    if (gainDb < 0) return '${gainDb.toStringAsFixed(1)} dB';
    return '0.0 dB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerControllerProvider);
    final eqNotifier = ref.read(equalizerControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Equalizador de Áudio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textSecondary),
            tooltip: 'Restaurar Padrão',
            onPressed: eqState.isEnabled
                ? () {
                    eqNotifier.resetToFlat();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Equalizador restaurado para Flat (0 dB)'),
                        backgroundColor: AppColors.surface,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: eqState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Mestre ON/OFF
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: eqState.isEnabled ? AppColors.primary.withValues(alpha: 0.6) : AppColors.divider,
                          width: eqState.isEnabled ? 1.5 : 0.5,
                        ),
                        boxShadow: eqState.isEnabled
                            ? [
                                BoxShadow(
                                  color: AppColors.accentGlow.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: eqState.isEnabled
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.cardBackground,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  color: eqState.isEnabled ? AppColors.primary : AppColors.textMuted,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Equalizador Mestre',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    eqState.isEnabled ? 'Ativado' : 'Desativado (Bypass)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: eqState.isEnabled ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: eqState.isEnabled,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                            inactiveThumbColor: AppColors.textMuted,
                            inactiveTrackColor: AppColors.cardBackground,
                            onChanged: (val) => eqNotifier.toggleEnabled(val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Seção de Presets (Chips Horizontais)
                    const Text(
                      'PRESETS DE SOM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ...eqState.availablePresets.map((preset) {
                            final isSelected = eqState.selectedPreset?.id == preset.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(preset.name),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surface,
                                disabledColor: AppColors.cardBackground,
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.divider,
                                  ),
                                ),
                                onSelected: eqState.isEnabled
                                    ? (_) => eqNotifier.selectPreset(preset)
                                    : null,
                              ),
                            );
                          }),

                          // Chip do estado "Personalizado" caso nenhuma combinação bata
                          if (eqState.selectedPreset == null)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: const Text('Personalizado'),
                                selected: true,
                                selectedColor: AppColors.secondary,
                                backgroundColor: AppColors.surface,
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: AppColors.secondary),
                                ),
                                onSelected: null,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Seção de Sliders de Frequência Verticais
                    const Text(
                      'FAIXAS DE FREQUÊNCIA (dB)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _frequencies.map((freq) {
                            final gain = eqState.bandGains[freq] ?? 0.0;
                            return _FrequencyBandColumn(
                              frequencyLabel: _formatFrequency(freq),
                              gainValue: gain,
                              formattedGain: _formatGain(gain),
                              isEnabled: eqState.isEnabled,
                              onChanged: (newGain) {
                                eqNotifier.setBandGain(freq, newGain);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FrequencyBandColumn extends StatelessWidget {
  final String frequencyLabel;
  final double gainValue;
  final String formattedGain;
  final bool isEnabled;
  final ValueChanged<double> onChanged;

  const _FrequencyBandColumn({
    required this.frequencyLabel,
    required this.gainValue,
    required this.formattedGain,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isEnabled ? AppColors.primary : AppColors.textMuted;

    return Column(
      children: [
        // Indicador numérico de Decibéis (+6.0 dB, 0.0 dB, etc.)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Text(
            formattedGain,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Slider Vertical Rotacionado (de +12.0dB no topo a -12.0dB na base)
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Linha central indicadora de 0dB
              Container(
                width: 28,
                height: 1.5,
                color: AppColors.divider,
              ),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  activeTrackColor: activeColor,
                  inactiveTrackColor: isEnabled
                      ? AppColors.cardBackground
                      : AppColors.cardBackground.withValues(alpha: 0.5),
                  thumbColor: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                  overlayColor: activeColor.withValues(alpha: 0.2),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: gainValue,
                    min: -12.0,
                    max: 12.0,
                    divisions: 48, // Passos de 0.5 dB
                    onChanged: isEnabled ? onChanged : null,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Rótulo da Frequência (60Hz, 230Hz, etc.)
        Text(
          frequencyLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isEnabled ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
