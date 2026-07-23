# Task 3: UI/UX - Reordenação e Swipe to Delete nas Listas

## 📌 Descrição Aprofundada
Substituir o modelo atual baseado apenas em botões para remover músicas e incluir suporte nativo para ordenação (`ReorderableListView`) e remoção por gesto (`Dismissible`). 

## 🎯 Escopo da Task
1. **Swipe to Delete (Deslizar para Remover)**:
   - Implementar o componente `Dismissible` nas faixas em Playlists do Usuário e na Fila de Reprodução do Player.
   - Quando deslizado, remover a música da lista local/Fila, e caso seja uma Playlist no banco, atualizar no repositório correspondente.
   - Mostrar background de cor vermelha com ícone de lixeira durante o arraste.
   - *Exceção:* A música que estiver tocando atualmente na Fila do Player não poderá ser removida.
2. **Reordenação (Drag and Drop)**:
   - Trocar a ListView padrão por uma `ReorderableListView` nas Playlists criadas e na Fila do Player.
   - Adicionar o manipulador visual (ícone "drag_handle") no final do `ListTile` dessas listas.
   - Atualizar a ordem da lista subjacente (State/Provider e Banco) quando o arrasto for concluído.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/playlist/presentation/views/playlist_detail_screen.dart`
- `lib/src/features/player/presentation/views/full_player_screen.dart` (Seção da Fila)
- Atualizar a UI do `AudioTrackListTile` ou criar wrappers customizados.

## ✅ Critérios de Aceite
- Músicas podem ser deslizadas para exclusão com animação fluída.
- Fila de reprodução e playlists pessoais podem ser reordenadas segurando o ícone de drag.
- Estado atualizado corretamente no backend e no Riverpod sem bugs visuais.
