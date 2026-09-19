# Task 2: Presentation - Controller de Letras e Sincronização em Tempo Real

## 📌 Descrição Aprofundada
Implementar o gerenciador de estado com Riverpod responsável por buscar as letras da música atualmente em execução e calcular a linha ativa em tempo real com base no progresso de reprodução do `PlayerController`.

## 🎯 Escopo da Task
1. **Controller de Letras (`lyrics_controller.dart`)**:
   - `LyricsNotifier` ou `lyricsProvider`:
     - Ouve o `currentTrack` do `playerControllerProvider`.
     - Dispara a busca de letras ao mudar de faixa (cancelando requisições anteriores caso o usuário pule rapidamente de música).
     - Fornece estado reativo (`AsyncValue<LyricsModel?>` ou estado customizado `LyricsState`).
2. **Cálculo da Linha Ativa**:
   - Fornecer provider/seletor (ex.: `currentLyricIndexProvider`) que cruza a posição atual do reprodutor (`playerState.position`) com as faixas de tempo (`startTime` e `endTime`) da lista de `LyricLineModel`.
   - Garantir atualização fluida sem renderizações desnecessárias da árvore de widgets inteira.
3. **Ações do Usuário**:
   - Método `seekToLine(int index)`: Permite que o usuário clique em uma estrofe/linha e o player avance/retorne imediatamente para o início daquele verso.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/presentation/controllers/lyrics_controller.dart` (Criar)

## ✅ Critérios de Aceite
- Ao trocar de música, o estado de letras é resetado e busca a letra da nova faixa automaticamente.
- O índice da linha atual reflete precisamente o tempo do reprodutor.
- Suporte para clique em uma linha sincronizada saltando para o tempo correspondente via `PlayerController.seek()`.
