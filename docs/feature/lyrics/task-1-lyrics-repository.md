# Task 1: Domain & Data - Modelos e Repositório de Letras

## 📌 Descrição Aprofundada
Definir as entidades de domínio e a camada de dados responsável por interagir com o pacote `dart_ytmusic_api` para obter letras (tanto sincronizadas quanto estáticas) a partir do `videoId` do YouTube Music.

## 🎯 Escopo da Task
1. **Modelos de Domínio (`lyrics_model.dart`)**:
   - `LyricLineModel`: Representa uma linha de letra sincronizada contendo texto, `startTime` (Duration) e `endTime` (Duration).
   - `LyricsModel`: Representa o payload completo de letras da música, contendo:
     - `bool hasTimedLyrics`: Indica se há sincronização temporal disponível.
     - `List<LyricLineModel> timedLines`: Lista com as linhas e tempos de início/fim.
     - `String? plainLyrics`: Letra integral em formato de texto simples (quando não houver tempos ou como fallback textual).
     - `String? sourceMessage`: Mensagem com créditos/fonte da letra fornecida pela API.

2. **Repositório de Letras (`lyrics_repository.dart` e implementação)**:
   - Método `Future<LyricsModel?> getLyrics(String videoId)`:
     - Tenta obter letras sincronizadas primeiro através de `ytMusic.getTimedLyrics(videoId)`.
     - Caso não haja timed lyrics ou retorne nulo/vazio, faz fallback chamando `ytMusic.getLyrics(videoId)`.
     - Se nenhuma letra for encontrada, retorna `null` de maneira segura e tratada.
     - Suporte a cache em memória (`Map<String, LyricsModel>`) para evitar requisições redundantes na mesma música.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/domain/models/lyrics_model.dart` (Criar)
- `lib/src/features/player/domain/repositories/lyrics_repository.dart` (Criar)
- `lib/src/features/player/data/repositories/ytmusic_lyrics_repository.dart` (Criar)

## ✅ Critérios de Aceite
- Mapeamento correto dos dados retornados por `TimedLyricsRes` e `TimedLyricsData` da biblioteca `dart_ytmusic_api`.
- Fallback automático para letra estática quando a música não tiver carimbos de tempo.
- Tratamento resiliente de exceções de rede e respostas vazias sem propagar erro fatal.
