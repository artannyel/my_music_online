# Task 3: Integração - Rastreador de Reprodução no Player

## 📌 Descrição Aprofundada
Fazer a ponte entre a feature de áudio (`player`) e a nova feature de `history`. O controller do player será responsável por acionar o log no momento adequado para não gerar falsos positivos (pular músicas rápido).

## 🎯 Escopo da Task
1. **Lógica de Threshold (Tempo Mínimo)**:
   - Adicionar uma verificação no `player_controller.dart` ou `audio_player_service.dart`.
   - Quando uma música começar a tocar, iniciar um contador ou escutar o stream de posição.
   - Se a posição atingir **30 segundos** (ou 30% da música caso ela seja muito curta), disparar um chamado assíncrono para o `history_controller.logPlay()`.
   - Garantir que um boleano (`_hasLoggedCurrentTrack`) previna que a mesma música seja logada duas vezes caso o usuário volte no meio do playback.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/presentation/controllers/player_controller.dart` 
- (ou criar um Provider separado `playback_tracker_provider.dart` que apenas observa o estado do player).

## ✅ Critérios de Aceite
- Músicas puladas antes de 30s não aparecem no banco de dados.
- Músicas tocadas por mais de 30s são inseridas perfeitamente.
- Não há duplicação de log caso o usuário pause e dê play repetidas vezes na mesma música.
