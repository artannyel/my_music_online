# Plano de Implementação - Feature: v1.1 UX Improvements

## 1. Visão Geral
A feature `v1.1_improvements` foca em aprimorar substancialmente a experiência do usuário (UX) e a gestão da biblioteca no app. Ela abrange persistência de estado do player, melhorias no gerenciamento de playlists, ordenação e gestos de arrasto nas listas, e um menu de contexto global unificado para as faixas.

## 2. Referência de Design (Stitch)
- Manter o padrão escuro e elegante estabelecido.
- Utilizar `BottomSheet` para menus de contexto globais e formulários rápidos de edição de playlist.
- Utilizar `Dismissible` para gestos de *Swipe to Delete*.
- Utilizar `ReorderableListView` para reordenação de itens.

## 3. Arquitetura da Feature
As modificações se espalharão entre as features existentes (`player`, `playlist`, `core`), mas o foco será consolidado neste plano para facilitar o rastreamento do progresso.

## 4. Divisão de Tasks
- [x] [Task 1: Core - Menu de Contexto Global (Long Press)](./task-1-global-context-menu.md)
- [x] [Task 2: Playlist & Album - Gerenciamento Avançado](./task-2-advanced-playlist-management.md)
- [x] [Task 3: UI/UX - Reordenação e Swipe to Delete nas Listas](./task-3-drag-drop-and-swipe.md)
- [x] [Task 4: Player - Persistência, Fila e Integrações](./task-4-player-queue-and-persistence.md)
