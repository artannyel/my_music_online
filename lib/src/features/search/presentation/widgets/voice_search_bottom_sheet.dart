import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/services/speech_to_text_service.dart';

/// VoiceSearchBottomSheet exibe um modal inferior moderno com feedback visual reativo
/// e animações em ondas sonoras para pesquisa por comando de voz.
class VoiceSearchBottomSheet extends ConsumerStatefulWidget {
  const VoiceSearchBottomSheet({super.key});

  /// Exibe o modal de busca por voz e retorna o texto reconhecido (ou null caso cancelado).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceSearchBottomSheet(),
    );
  }

  @override
  ConsumerState<VoiceSearchBottomSheet> createState() => _VoiceSearchBottomSheetState();
}

class _VoiceSearchBottomSheetState extends ConsumerState<VoiceSearchBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  String _transcribedText = '';
  String _statusMessage = 'Ouvindo... Fale agora';
  bool _isListening = false;
  bool _hasError = false;
  double _soundLevel = 0.0;
  Timer? _autoSubmitTimer;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _pausePlayerIfPlaying();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceRecognition();
    });
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// Pausa o player de áudio temporariamente para o som não vazar no microfone
  void _pausePlayerIfPlaying() {
    try {
      final audioService = ref.read(audioPlayerServiceProvider);
      if (audioService.player.playing) {
        audioService.pause();
      }
    } catch (e) {
      debugPrint('[VoiceSearchBottomSheet] Aviso ao pausar player: $e');
    }
  }

  Future<void> _startVoiceRecognition() async {
    final speechService = ref.read(speechToTextServiceProvider);

    setState(() {
      _isListening = true;
      _hasError = false;
      _transcribedText = '';
      _statusMessage = 'Ouvindo... Fale o nome de uma música ou artista';
    });

    final started = await speechService.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _transcribedText = words;
          if (words.isNotEmpty) {
            _statusMessage = 'Ouvindo...';
          }
        });

        if (isFinal && words.trim().isNotEmpty) {
          _scheduleAutoSubmit(words.trim());
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          // Normaliza o nível de som (geralmente entre -2 e 10 no Android)
          _soundLevel = (level.clamp(0.0, 10.0) / 10.0);
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        debugPrint('[VoiceSearchBottomSheet] Status recebido: $status');
        if (status == 'notListening' || status == 'done') {
          setState(() {
            _isListening = false;
          });
          if (_transcribedText.trim().isNotEmpty) {
            _scheduleAutoSubmit(_transcribedText.trim());
          } else {
            setState(() {
              _statusMessage = 'Não ouvi nada. Toque no microfone para tentar novamente.';
            });
          }
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _hasError = true;
          _statusMessage = 'Não foi possível reconhecer a fala. Toque para tentar de novo.';
        });
      },
    );

    if (!started && mounted) {
      final hasPermission = await speechService.hasPermission;
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _hasError = true;
        _statusMessage = hasPermission
            ? 'Serviço de voz indisponível no momento.'
            : 'Permissão de microfone necessária para pesquisar por voz.';
      });
    }
  }

  void _scheduleAutoSubmit(String query) {
    _autoSubmitTimer?.cancel();
    _autoSubmitTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(query);
      }
    });
  }

  void _manualSubmit() {
    final query = _transcribedText.trim();
    if (query.isNotEmpty) {
      _autoSubmitTimer?.cancel();
      Navigator.of(context).pop(query);
    }
  }

  @override
  void dispose() {
    _autoSubmitTimer?.cancel();
    _pulseController.dispose();
    try {
      ref.read(speechToTextServiceProvider).cancelListening();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle central superior
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Cabeçalho com título e botão de fechar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pesquisa por Voz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(null),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botão central animado de Microfone
            GestureDetector(
              onTap: () {
                if (!_isListening) {
                  _startVoiceRecognition();
                } else {
                  final speechService = ref.read(speechToTextServiceProvider);
                  speechService.stopListening();
                }
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final effectiveScale = _isListening
                      ? (_pulseAnimation.value + (_soundLevel * 0.25))
                      : 1.0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Onda externa translúcida
                      if (_isListening)
                        Transform.scale(
                          scale: effectiveScale * 1.3,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ),

                      // Onda média com glow
                      if (_isListening)
                        Transform.scale(
                          scale: effectiveScale * 1.15,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGlow.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Círculo central com ícone de microfone
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [AppColors.primary, AppColors.secondary]
                                : [AppColors.cardBackground, AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: _isListening ? AppColors.primary : AppColors.divider,
                            width: 2,
                          ),
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _isListening ? Colors.white : AppColors.textSecondary,
                          size: 38,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Texto transcrito dinâmico ou status
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _transcribedText.isNotEmpty
                  ? Padding(
                      key: const ValueKey('transcribed_text'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '"$_transcribedText"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    )
                  : Padding(
                      key: const ValueKey('status_message'),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _hasError ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Ações inferiores
            if (_transcribedText.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _manualSubmit,
                icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Pesquisar agora',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              )
            else if (!_isListening)
              OutlinedButton.icon(
                onPressed: _startVoiceRecognition,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                label: const Text(
                  'Tentar novamente',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
