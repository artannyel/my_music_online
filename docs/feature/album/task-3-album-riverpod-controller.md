# Task 3: Presentation - Controller em Riverpod

## 📌 Descrição Aprofundada
Criar o `FamilyFutureProvider` para carregar dados de um álbum específico a partir do seu `albumId` passado via parâmetro de rota do GoRouter.

## 🎯 Escopo da Task
1. Criar `lib/src/features/album/presentation/controllers/album_controller.dart`.
2. Expor `albumDetailsProvider(String albumId)`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/album/presentation/controllers/album_controller.dart`

## ✅ Critérios de Aceite
- Estado de carregamento por ID de álbum sem colisão de cache entre diferentes álbuns.
