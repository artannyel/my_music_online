# Task 3: Configuração do `GoRouter` e `ShellRoute` (MiniPlayer Global)

## 📌 Descrição Aprofundada
Estruturar o roteamento declarativo do aplicativo utilizando a biblioteca `go_router`. É fundamental incluir a funcionalidade de `ShellRoute` para garantir que o `MiniPlayer` (barra inferior de reprodução de música) permaneça fixo e visível no rodapé durante a navegação entre a Home, Busca, Playlists e Perfil.

## 🎯 Escopo da Task
1. Definir as constantes de rotas em `lib/src/core/router/route_names.dart`:
   - `/login`, `/register`, `/home`, `/search`, `/playlists`, `/player`, `/album/:id`, `/artist/:id`, `/equalizer`.
2. Criar o arquivo `lib/src/core/router/app_router.dart`:
   - Configurar `GoRouter` com `ShellRoute` encapsulando a Bottom Navigation Bar e o `MiniPlayer`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/core/router/route_names.dart`
- `lib/src/core/router/app_router.dart`

## ✅ Critérios de Aceite
- Troca de telas via `GoRouter` funcionando sem recarregar o widget pai da aplicação.
- Estrutura pronta para acoplar o `MiniPlayer` flutuante.
