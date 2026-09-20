# Task 4: Presentation - Controllers e Telas de UI

## 📌 Descrição Aprofundada
Criar os Providers do Riverpod que fornecem as listas e construir as interfaces gráficas na seção da Biblioteca para o usuário interagir.

## 🎯 Escopo da Task
1. **Riverpod Providers**:
   - `historyProvider`: Stream/Future que puxa o Histórico Recente.
   - `topTracksProvider`: Future que gera a lista das Top 20 Geral.
   - `monthlyTopTracksProvider`: Future que gera a lista das Mais Tocadas do Mês (recebendo mês/ano).
2. **Telas e Componentes**:
   - Modificar a `HomeScreen` ou criar uma aba na Biblioteca para incluir carrosseis/listas de atalho para "Recentes" e "Suas Mais Tocadas".
   - Criar `HistoryScreen` para exibir a lista completa com histórico infinito.
   - Criar `TopTracksScreen` com duas abas: "Geral" (Top 20) e "Deste Mês".

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/history/presentation/controllers/history_controller.dart`
- `lib/src/features/history/presentation/views/history_screen.dart`
- `lib/src/features/history/presentation/views/top_tracks_screen.dart`
- `lib/src/features/home/presentation/views/home_screen.dart` (Para adicionar atalhos)

## ✅ Critérios de Aceite
- UI fluída utilizando os componentes padronizados do app (AudioTrackListTile).
- As listas refletem fielmente o que está persistido no Firestore.
- A tela de "Mais Tocadas" tem design atraente enfatizando os rankings (1º, 2º, 3º lugar...).
