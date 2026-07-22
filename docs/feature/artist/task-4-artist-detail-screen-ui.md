# Task 4: Presentation - Interface de Usuário ArtistDetailScreen (Stitch Design)

## 📌 Descrição Aprofundada
Desenvolver a interface gráfica da tela do artista baseada no protótipo do [Stitch](https://stitch.withgoogle.com/projects/16430281818792447633).

## 🎯 Escopo da Task
1. Criar `lib/src/features/artist/presentation/views/artist_detail_screen.dart`:
   - Header com foto grande do artista e efeito parallax / fading app bar.
   - Botões "Tocar Rádio do Artista" e "Seguir".
   - Seção "Músicas Populares" (Top 5 mais tocadas) com botão de ícone `>` para ir à tela "Ver Todas" (que lista todas as músicas usando `getArtistSongs`).
   - Carrossel horizontal de "Álbuns" e "Singles". Se a lista tiver o tamanho máximo padrão (ex: 10), exibir o botão de ícone `>` para abrir uma tela de Grid ("Ver Todos"), passando a lista inicial como estado de *fallback*.
   - Carrossel horizontal de "Incluído em" (`featuredOn`), com botão `>` se houver mais itens a carregar.
   - Carrossel horizontal de "Os fãs também podem gostar de..." (`similarArtists`), exibindo imagens circulares para os artistas relacionados, com botão `>` se necessário.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/artist/presentation/views/artist_detail_screen.dart`

## ✅ Critérios de Aceite
- Design envolvente, responsivo com navegação fluida para as faixas e álbuns.
