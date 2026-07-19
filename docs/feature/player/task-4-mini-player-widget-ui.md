# Task 4: Presentation - Componente MiniPlayer (UI Bar Persistente)

## 📌 Descrição Aprofundada
Desenvolver a barra inferior flutuante do `MiniPlayer` que é exibida fixamente acima da barra de navegação em todas as telas principais do aplicativo.

## 🎯 Escopo da Task
1. Criar `lib/src/features/player/presentation/widgets/mini_player_widget.dart`:
   - Thumbnail miniatura da música com bordas arredondadas.
   - Nome da música e Artista com scroll em texto longo (*Marquee*).
   - Botão Play/Pause e botão Próxima Música.
   - Barra fina de progresso linear na borda inferior do widget.
   - Gesto de toque no widget para abrir a tela `FullPlayerScreen` (estilo YouTube Music).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/presentation/widgets/mini_player_widget.dart`

## ✅ Critérios de Aceite
- MiniPlayer visível, funcional e integrado ao `ShellRoute` do GoRouter.
