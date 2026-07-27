# Task 6: Router AuthGuard & Suporte ao Modo Convidado

## 📌 Descrição Aprofundada
Configurar o `GoRouter` para abrir por padrão na tela Home (`/home`). Permitir que usuários convidados (não autenticados) naveguem e escutem músicas livremente, redirecionando para `/login` apenas se tentarem acessar rotas restritas ou exibindo um dialog de autenticação ao tentar salvar playlists.

## 🎯 Escopo da Task
1. Atualizar `lib/src/core/router/app_router.dart`:
   - Rota inicial definida para `/home`.
   - Permitir navegação livre por `/home`, `/search`, `/player`, `/album/:id`, `/artist/:id`, `/settings`.
   - Se o usuário tentar acessar a rota de criação/edição de playlist sem estar autenticado, exibir o modal de autenticação ou redirecionar para `/login`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/core/router/app_router.dart`

## ✅ Critérios de Aceite
- Aplicativo inicia direto na Home sem travar na tela de login.
- Experiência fluida para usuários não logados.
