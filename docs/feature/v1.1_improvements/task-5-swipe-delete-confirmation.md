# Task 5: UI/UX - Confirmação de Exclusão e Prevenção de Swipe Acidental

## 📌 Descrição Aprofundada
Melhoria de UX nas listas do aplicativo que utilizam o gesto de arrasto horizontal (`Dismissible`) para remover faixas. Em dispositivos móveis, durante a rolagem vertical ou diagonal do scroll, o gesto era frequentemente interpretado pelo framework como um swipe horizontal, resultando na exclusão acidental e imediata de músicas sem consentimento explícito do usuário.

Esta task introduz um diálogo modal de confirmação prévia (`confirmDismiss`) e restringe o gesto para direção única (`DismissDirection.endToStart`), prevenindo exclusões involuntárias durante a navegação.

## 🎯 Escopo da Task
1. **Diálogo Modal de Confirmação (`confirmDismiss`)**:
   - Interceptar o término do arraste através do callback `confirmDismiss` do `Dismissible`.
   - Exibir um diálogo de confirmação estilizado com o design escuro do app (`AppColors.surface`, `AppColors.error`, etc.):
     - Título contextual (ex.: *"Remover da playlist?"*, *"Remover da fila?"*, *"Excluir download?"*).
     - Mensagem explicativa contendo o título da faixa a ser removida.
     - Botão **"Cancelar"** (fecha o diálogo, retorna `false` e o item retorna suavemente à posição original).
     - Botão **"Remover" / "Excluir"** com destaque visual de ação destrutiva (`AppColors.error`), retornando `true` e efetivando a exclusão.
2. **Refinamento do Gesto e Prevenção de Falsos Positivos**:
   - Alterar a direção do `Dismissible` de `DismissDirection.horizontal` (ambos os lados) para `DismissDirection.endToStart` (apenas da direita para a esquerda).
   - Eliminar conflitos com o gesto nativo de retorno de tela do Android e iOS (swipe da borda esquerda).
3. **Telas Abrangidas**:
   - **Playlists do Usuário** (`lib/src/features/playlist/presentation/views/playlist_detail_screen.dart`): Proteção na remoção de faixas em playlists criadas pelo usuário no Firestore.
   - **Fila do Player** (`lib/src/features/player/presentation/views/full_player_screen.dart`): Proteção na remoção de faixas da fila ativa do reprodutor (mantendo o bloqueio de remoção para a faixa que está tocando no momento).
   - **Downloads Offline** (`lib/src/features/download/presentation/views/downloads_screen.dart`): Proteção na remoção de faixas baixadas, evitando perda acidental do arquivo físico no armazenamento do dispositivo.

## 📋 Arquivos a Modificar / Criar
- `docs/feature/v1.1_improvements/task-5-swipe-delete-confirmation.md` (Documentação da task)
- `docs/feature/v1.1_improvements/plan.md` (Atualização da listagem de tasks)
- `lib/src/features/playlist/presentation/views/playlist_detail_screen.dart`
- `lib/src/features/player/presentation/views/full_player_screen.dart`
- `lib/src/features/download/presentation/views/downloads_screen.dart`

## ✅ Critérios de Aceite
- Ao arrastar uma faixa nas 3 telas contempladas, a remoção só ocorre após a confirmação no modal.
- Caso o usuário clique em "Cancelar" ou toque fora do modal, o item retorna suavemente para a lista sem sofrer alteração.
- Confirmar no modal executa a remoção e atualiza imediatamente a UI e os repositórios/banco correspondentes.
- O gesto funciona exclusivamente da direita para a esquerda (`endToStart`), não interferindo no scroll vertical padrão.
