# Task 4: Presentation - Interface de Busca SearchScreen (Stitch Design)

## 📌 Descrição Aprofundada
Desenvolver a interface gráfica da tela de pesquisa em conformidade com o protótipo do [Stitch](https://stitch.withgoogle.com/projects/16430281818792447633).

## 🎯 Escopo da Task
1. Criar `lib/src/features/search/presentation/views/search_screen.dart`:
   - Barra de busca fixa com ícone de pesquisa, campo de texto e botão para limpar input.
   - Lista instantânea de sugestões de autocompletar de texto (via `getSearchSuggestions`) exibida enquanto o usuário digita.
   - Ao tocar em uma sugestão ou pressionar Enter, exibe a visão de resultados completos.
   - Chips horizontais selecionáveis para filtro: *Tudo*, *Músicas*, *Álbuns*, *Artistas*, *Playlists*.
   - Lista de resultados formatada com thumbnails arredondadas e badges do tipo de resultado.
   - Ação ao clicar em uma música: ativa o **Rádio Automix** (`playTrackWithRadio`) e abre a tela do player em tela cheia (`FullPlayerScreen.show(context)`).
   - Ação ao clicar em um álbum (navega para a tela de álbum) ou artista (navega para artista).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/search/presentation/views/search_screen.dart`

## ✅ Critérios de Aceite
- Autocompletar dinâmico e responsivo ao digitar.
- Integração transparente com o modo Rádio Automix ao tocar em faixas individuais.
