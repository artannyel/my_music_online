import 'package:flutter/material.dart';

/// AppColors contém a paleta de cores oficial do My Music Online,
/// alinhada ao design limpo e escuro (Stitch Google Design).
class AppColors {
  AppColors._();

  /// Fundo principal do app (Obsidian Deep)
  static const Color background = Color(0xFF090A0F);

  /// Superfícies secundárias e cards de navegação
  static const Color surface = Color(0xFF12141D);

  /// Cards de conteúdo e botões flutuantes (Glassmorphism Dark)
  static const Color cardBackground = Color(0xFF1A1D2B);

  /// Cor Primária (Neon Magenta Red)
  static const Color primary = Color(0xFFFF0055);

  /// Cor Secundária (Electric Violet)
  static const Color secondary = Color(0xFF7C4DFF);

  /// Cor de Acento / Brilho Neon
  static const Color accentGlow = Color(0x66FF0055);

  /// Texto Principal (100% Opacidade)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Texto Secundário (70% Opacidade)
  static const Color textSecondary = Color(0xFFA0A5B5);

  /// Texto Muted / Desabilitado
  static const Color textMuted = Color(0xFF636A7E);

  /// Linhas de divisão e bordas suaves
  static const Color divider = Color(0xFF222636);

  /// Cor de erro / alerta
  static const Color error = Color(0xFFFF453A);

  /// Cor de sucesso
  static const Color success = Color(0xFF30D158);
}
