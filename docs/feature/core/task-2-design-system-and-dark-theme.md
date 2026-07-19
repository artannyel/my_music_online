# Task 2: Design System & Tema Escuro (Stitch Design)

## 📌 Descrição Aprofundada
Desenvolver o sistema de design visual baseado nas especificações e protótipos do **Stitch Google Design** ([Stitch Project](https://stitch.withgoogle.com/projects/16430281818792447633)). O tema deve ser predominantemente escuro, limpo e moderno, trazendo uma experiência imersiva para um aplicativo de música.

## 🎯 Escopo da Task
1. Criar `lib/src/core/theme/app_colors.dart`:
   - `background`: `#090A0F` (Obsidian Deep)
   - `surface`: `#12141D`
   - `cardBackground`: `#1A1D2B` (com suporte a bordas suaves e translucidez)
   - `primary`: `#FF0055` (Neon Magenta Red)
   - `secondary`: `#7C4DFF` (Electric Violet)
   - `textPrimary`: `#FFFFFF`
   - `textSecondary`: `#A0A5B5`
2. Criar `lib/src/core/theme/app_theme.dart`:
   - Configuração de `ThemeData.dark(useMaterial3: true)`
   - Customização de `AppBarTheme`, `BottomNavigationBarTheme`, `SliderTheme` e `CardTheme`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/core/theme/app_colors.dart`
- `lib/src/core/theme/app_theme.dart`

## ✅ Critérios de Aceite
- Aplicação rodando em tema escuro moderno e clean sem cores genéricas de fábrica.
- Cores e fontes alinhadas com a estética do Stitch.
