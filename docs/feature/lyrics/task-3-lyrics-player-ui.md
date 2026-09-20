# Task 3: UI/UX - Integração de Letras no FullPlayerScreen e Visualização

## 📌 Descrição Aprofundada
Integrar o visualizador de letras na tela completa de reprodução (`FullPlayerScreen`). A experiência deve seguir a identidade visual do app (Dark/Neon), permitindo alternar de maneira elegante entre a capa da música e as letras, ou acessá-las através de um painel/aba dedicada estilo YouTube Music.

## 🎯 Escopo da Task
1. **Ponto de Entrada no Player**:
   - Adicionar botão de alternância (ex.: ícone de microfone/letra `Icons.lyrics_rounded` na barra superior ou sob a capa).
   - Alternativamente, disponibilizar abas ou visualizador expansível ("Música" / "Letra" / "A Seguir") mantendo a consistência do design.
2. **Visualizador de Letras (`LyricsViewWidget`)**:
   - **Modo Sincronizado**:
     - Lista com rolagem vertical automática mantendo o verso ativo centralizado ou em foco.
     - Destaque visual no verso atual (tipografia em negrito, cor `AppColors.primary` ou branco contrastante com efeito glow sutil; versos passados/futuros com opacidade reduzida).
     - Toque no verso aciona o seek para o tempo correspondente.
   - **Modo Estático (Fallback)**:
     - Exibição do texto formatado com scroll livre quando não houver sincronismo.
   - **Estado Vazio / Indisponível**:
     - Mensagem amigável com ícone e visual condizente com a paleta do app caso a música não possua letra.
   - **Créditos da Letra**:
     - Exibir no rodapé da letra a fonte/crédito caso retornado pela API (`sourceMessage`).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/presentation/widgets/lyrics_view_widget.dart` (Criar)
- `lib/src/features/player/presentation/views/full_player_screen.dart` (Modificar)

## ✅ Critérios de Aceite
- Transição fluida entre visualização de capa e visualização de letra.
- Linhas sincronizadas acompanham o playback em tempo real sem saltos bruscos.
- Feedback visual agradável e responsivo ao tocar em um verso para pular o áudio.
- Tratamento limpo quando a letra não estiver disponível, sem travar o player.
