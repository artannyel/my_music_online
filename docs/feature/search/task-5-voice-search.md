# Task 5: Integration & UI - Pesquisa por Voz com SpeechToText e Modal Animado (Stitch Design)

## 📌 Descrição Aprofundada
Implementar o recurso de pesquisa por comando de voz (*Voice Search*) na tela de busca (`SearchScreen`), permitindo aos usuários ditar nomes de músicas, artistas, álbuns e gêneros através do microfone do aparelho. A funcionalidade processa a fala em tempo real utilizando a biblioteca `speech_to_text`, exibe um modal inferior moderno com animação de ondas sonoras no estilo Stitch Design e submete a busca automaticamente ao detectar a conclusão da fala.

## 🎯 Escopo da Task
1. **Configuração de Dependência & Permissões Nativas**:
   - Adicionar o pacote `speech_to_text` ao `pubspec.yaml`.
   - **Android**: Adicionar a permissão `android.permission.RECORD_AUDIO` e registrar a tag `<queries>` para o serviço nativo `android.speech.RecognitionService` no `android/app/src/main/AndroidManifest.xml`.
   - **iOS**: Configurar as descrições de privacidade `NSMicrophoneUsageDescription` e `NSSpeechRecognitionUsageDescription` no `ios/Runner/Info.plist`.

2. **Serviço de Reconhecimento de Fala (`lib/src/features/search/data/services/speech_to_text_service.dart`)**:
   - Encapsular a inicialização e controle do motor de reconhecimento do dispositivo (`SpeechToText`).
   - Gerenciamento de status em tempo real:
     - Disponibilidade do serviço nativo de fala.
     - Detecção e requisição de permissão de microfone em runtime.
     - Notificação das palavras transcritas parciais e finais (`recognizedWords`).
     - Notificação do nível sonoro (`soundLevelListener`) para animação de pulso/ondas na interface.
   - Suporte a detecção automática do idioma do dispositivo (com fallback padrão para `pt_BR`).

3. **Interação com Reprodução em Andamento (Audio Pausing)**:
   - Ao iniciar a escuta por voz, pausar temporariamente a música que estiver tocando via `AudioPlayerService` para evitar que o som dos alto-falantes contamine a captura do microfone.

4. **Interface Gráfica do Modal Animado (`lib/src/features/search/presentation/widgets/voice_search_bottom_sheet.dart`)**:
   - Modal inferior (`showModalBottomSheet`) com fundo escuro (`AppColors.surface`), cantos arredondados e acabamento elegante.
   - Ícone de microfone centralizado cercado por ondas/círculos concêntricos pulsantes reativos ao som da voz.
   - Feedback textual contextual:
     - Estado inicial: *"Ouvindo... Fale o nome de uma música ou artista"*.
     - Durante a fala: exibição do texto transcrito em tempo real com destaque visual.
     - Estado de silêncio/erro: mensagem orientando tocar para tentar novamente.
   - Botão discreto para fechar/cancelar o modal.

5. **Integração com a `SearchScreen` (`lib/src/features/search/presentation/views/search_screen.dart`)**:
   - Inclusão do botão de microfone (`Icons.mic_rounded`) na barra de busca (visível no campo de texto).
   - Ao concluir a captura da fala:
     - Injeta o texto transcrito no `_textController`.
     - Atualiza o `searchQueryProvider`.
     - Dispara a busca (`isSearchSubmittedProvider = true`).
     - Fecha o modal e exibe os resultados na lista instantaneamente.

## 📋 Arquivos a Criar / Modificar
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/src/features/search/data/services/speech_to_text_service.dart` (Novo)
- `lib/src/features/search/presentation/widgets/voice_search_bottom_sheet.dart` (Novo)
- `lib/src/features/search/presentation/views/search_screen.dart`
- `docs/feature/search/plan.md`
- `docs/feature/search/task-5-voice-search.md` (Novo)

## ✅ Critérios de Aceite
- Ícone de microfone acessível e intuitivo na barra de busca.
- Abertura rápida do modal com animação fluida de escuta sonora.
- Transcrição precisa das palavras faladas em português (e suporte ao idioma do sistema).
- Preenchimento e submissão automática da pesquisa assim que o usuário termina de falar.
- Pausa segura do player de áudio para captura sem interferências sonoras.
- Tratamento amigável caso a permissão do microfone seja negada.
