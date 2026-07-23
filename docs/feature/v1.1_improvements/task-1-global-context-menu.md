# Task 1: Core - Menu de Contexto Global (Long Press)

## 📌 Descrição Aprofundada
Desenvolver um componente reutilizável (`SongContextMenuBottomSheet`) que pode ser acionado ao segurar longamente sobre qualquer música do app (seja em listas, álbuns, playlists ou busca).

## 🎯 Escopo da Task
1. Criar o componente visual em `lib/src/core/presentation/widgets/`.
2. O Menu deve ter as opções:
   - **Tocar**: Substitui a fila e toca a música (comportamento padrão atual de clique curto).
   - **Adicionar à Fila**: Insere a música no final da lista de reprodução ativa.
   - **Tocar a Seguir**: Insere a música na lista de reprodução, logo após a faixa que está tocando no momento.
   - **Salvar na Playlist**: Abre a BottomSheet existente (`AddToPlaylistBottomSheet`).
   - **Ir para o Artista**: Navega para a tela do artista.
   - **Ir para o Álbum**: Navega para a tela do álbum (se houver ID do álbum na música).
   - **Remover da Fila** (Condicional): Opção que só aparece se o menu for acionado de dentro da Fila do Player atual.
3. Integrar esse menu em todas as listas de músicas do app usando o `onLongPress` dos tiles.

## 📋 Arquivos a Modificar / Criar
- `lib/src/core/presentation/widgets/song_context_menu_bottom_sheet.dart` (Criar)
- Atualizar os `ListTile` em diversas telas (`ArtistDetailScreen`, `PlaylistDetailScreen`, `AlbumDetailScreen`, `SearchScreen`, `FullPlayerScreen`) para incluir o `onLongPress`.

## ✅ Critérios de Aceite
- Menu acessível via Long Press em todos os locais onde uma música é listada.
- Todas as ações fluindo corretamente e o "Remover da Fila" sendo condicional.
