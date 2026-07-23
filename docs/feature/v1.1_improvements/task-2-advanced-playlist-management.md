# Task 2: Playlist & Album - Gerenciamento Avançado

## 📌 Descrição Aprofundada
Tornar o ecossistema de Playlists criado pelo usuário mais robusto, possibilitando editar metadados, criar pre-sets a partir de álbuns, e aprimorar o fluxo de cópia de playlist.

## 🎯 Escopo da Task
1. **Editar Playlist Pessoal**: Adicionar ação no menu da playlist para editar (Nome e Descrição) via BottomSheet ou Dialog (apenas para playlists próprias criadas ou copiadas pelo usuário).
2. **Copiar Playlist**: Ao acionar a ação "Copiar", abrir o formulário (`CreatePlaylistBottomSheet` ou Dialog) preenchido com `{Nome da Playlist original} (Cópia)` para o usuário validar/editar antes de submeter a criação.
3. **Salvar Álbum**: Adicionar um botão no `AlbumDetailScreen` para "Salvar Álbum na Biblioteca". O álbum será salvo utilizando a estrutura atual do `PlaylistModel`, possivelmente com um metadado indicando que se trata de um álbum completo.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/playlist/presentation/controllers/playlist_controller.dart`
- `lib/src/features/playlist/presentation/views/playlist_detail_screen.dart`
- `lib/src/features/album/presentation/views/album_detail_screen.dart`
- Novos Widgets/Dialogs para edição e confirmação.

## ✅ Critérios de Aceite
- Fluxo de edição funcionando e atualizando local/Firebase de acordo com o Repositório de Playlist.
- Cópia passando pelo passo de edição de nome.
- Álbuns salvos aparecendo normalmente junto com as Playlists criadas.
