# Task 6: Feature - Modo Rádio Automix / Autoplay Infinito (`getUpNexts`)

## Objetivo
Implementar o comportamento de **Rádio Automix / Autoplay Infinito** no `PlayerController` utilizando o método `getUpNexts(videoId)` do `dart_ytmusic_api`.

## Especificação de Negócio & Fluxos de Fila
1. **Origem: Playlist ou Álbum (`isRadioMode = false`)**:
   - A fila é estática e contida estritamente nas faixas da playlist/álbum selecionado.
   - Não consulta músicas recomendadas automaticamente ao chegar ao fim.
2. **Origem: Música Avulsa (Busca, Home, Recomendação) (`isRadioMode = true`)**:
   - A música selecionada inicia a reprodução **instantaneamente**.
   - Em segundo plano (sem bloquear a UI ou a reprodução do áudio), o controller chama `_ytMusic.getUpNexts(track.videoId)`.
   - As faixas retornadas são convertidas em `AudioTrackModel` e adicionadas dinamicamente à fila (`state.queue`).
   - Conforme a execução avança e a lista se aproxima do fim (ex: restam 2 faixas na fila), o sistema dispara um novo `getUpNexts(ultimaMúsica.videoId)` appendando mais faixas recomendadas à fila, garantindo uma experiência de rádio ilimitada estilo YouTube Music.

## Passos de Implementação
1. **No `PlayerStateModel`**:
   - Adicionar a propriedade `final bool isRadioMode;` (padrão `false`).
2. **No `PlayerController`**:
   - Criar o método `Future<void> playTrackWithRadio(AudioTrackModel track)`.
   - Criar o método interno `Future<void> _fetchAndAppendUpNexts(String videoId)`.
   - Conectar no listener de avanço de faixas (`_onTrackEnded` ou `nextTrack`) para verificar se `isRadioMode == true` e se a fila precisa de novos itens.
3. **Arquivos Impactados**:
   - `lib/src/features/player/domain/models/player_state_model.dart`
   - `lib/src/features/player/presentation/controllers/player_controller.dart`
