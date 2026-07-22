# Task 1: Domain - Modelo ArtistModel

## 📌 Descrição Aprofundada
Definir o modelo de dados para o perfil do artista, top faixas e discografia.

## 🎯 Escopo da Task
1. Criar `lib/src/features/artist/domain/models/artist_model.dart`:
   - Campos: `id`, `name`, `bannerUrl`, `avatarUrl`, `description`, `topSongs` (List<SongModel>), `albums` (List<AlbumModel>), `singles` (List<AlbumModel>), `featuredOn` (List<PlaylistModel> ou List<AlbumModel>), `similarArtists` (List<ArtistModel>).
2. Criar `lib/src/features/artist/domain/repositories/artist_repository.dart`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/artist/domain/models/artist_model.dart`
- `lib/src/features/artist/domain/repositories/artist_repository.dart`

## ✅ Critérios de Aceite
- Modelos estruturados e sem erros de tipagem.
