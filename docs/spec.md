# Software Design Document (SDD) - My Music Online

## 1. Visão Geral do Projeto
**My Music Online** é um aplicativo mobile de streaming de música com design moderno, clean e tema escuro (*Dark Theme*), inspirado no YouTube Music. O aplicativo permite a descoberta, busca, reprodução e organização de músicas, álbuns, artistas e playlists personalizadas.

### Regras de Acesso e Sessão (Atualizado)
- **Acesso Direto à Home (Modo Convidado)**: O aplicativo abre diretamente na tela principal (Home). Usuários **não logados** podem navegar, pesquisar e ouvir músicas livremente.
- **Autenticação Opcional/Necessária**: O cadastro/login via Firebase é exigido apenas no momento em que o usuário tentar criar, salvar ou gerenciar playlists personalizadas.
- **Gerenciamento de Cookies `.txt`**: O app possui uma área dedicada para upload/inserção do conteúdo do arquivo `cookies.txt`, que é persistido no Firebase e utilizado pela biblioteca `dart_ytmusic_api` para autenticação de streaming e buscas.

---

## 2. Tecnologias & Bibliotecas

| Categoria | Tecnologia / Biblioteca | Descrição |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK >= 3.0) | Desenvolvimento multi-plataforma móvel |
| **Backend & Autenticação** | Firebase (Auth & Cloud Firestore) | Autenticação opcional e armazenamento de playlists e cookies |
| **Gerenciamento de Estado** | Riverpod (`flutter_riverpod` / `riverpod_annotation`) | Gerenciamento de estado reativo, escopado e testável |
| **Roteamento** | `go_router` | Roteamento declarativo com rota inicial `/home` e guardas condicionais |
| **Fonte de Músicas / Busca** | `dart_ytmusic_api` | API para busca alimentada com cookies remotos do Firebase |
| **Player de Áudio** | `just_audio` + `audio_service` | Reprodução de áudio em primeiro e segundo plano |
| **Design / UI** | Custom Dark Theme (Stitch Design) | Estética moderna, limpa, cores escuras profundas e acentos vibrantes |

---

## 3. Arquitetura do Projeto

O projeto adota a arquitetura baseada em **Features (Feature-First)**, dividindo cada módulo do aplicativo em três camadas principais: `domain`, `data` e `presentation`.

```text
lib/
├── main.dart
├── src/
│   ├── app.dart
│   ├── core/
│   │   ├── constants/       # Cores, fontes, dimensões
│   │   ├── theme/           # Tema escuro customizado
│   │   ├── router/          # Configuração do GoRouter (Rota inicial /home)
│   │   ├── services/        # Serviços globais (AudioHandler, Firebase Init)
│   │   └── utils/           # Formatadores de tempo, extensões
│   └── features/
│       ├── auth/            # Login, Cadastro e modal de login compulsório para Playlists
│       ├── home/            # Tela inicial com acesso direto livre
│       ├── search/          # Busca de faixas usando cookies do Firebase
│       ├── player/          # Reprodução livre de músicas (MiniPlayer & FullPlayer)
│       ├── playlist/        # Criação e salvamento (Requer Login)
│       ├── album/           # Navegação de álbum
│       ├── artist/          # Navegação de artista
│       ├── equalizer/       # Controles de equalização de som
│       └── settings/        # Configurações & Upload do cookies.txt pro Firebase
```

---

## 4. Funcionalidades & Módulos Especificados

### 4.1 Autenticação & Sessão (`features/auth`)
- **Acesso Convidado**: Usuário navega sem obrigatoriedade de login.
- **Login / Cadastro**: Suporte a email/senha via Firebase Auth.
- **Prompt de Autenticação**: Exibido automaticamente se um usuário não logado tentar criar/salvar uma playlist.

### 4.2 Gerenciamento de Cookies `.txt` (`features/settings`)
- Tela de upload ou colagem manual do conteúdo de `cookies.txt`.
- Persistência e sincronização dos cookies no Cloud Firestore.
- Injeção automática dos cookies na instância do `dart_ytmusic_api`.

### 4.3 Home & Descoberta (`features/home`)
- Rota inicial do app (`/home`).
- Carrossel / Seções de sugestões de músicas e playlists.
- Seção de "Mais Tocadas" / Destaques da semana.

### 4.4 Busca (`features/search`)
- Campo de pesquisa em tempo real com `dart_ytmusic_api` (com cookies injetados).
- Filtros por Músicas, Álbuns, Artistas e Playlists.

### 4.5 Player de Áudio Estilo YouTube Music (`features/player`)
- Reprodução ilimitada sem necessidade de login.
- MiniPlayer persistente + Full Player expandível.

### 4.6 Gerenciamento de Playlists (`features/playlist`)
- **Requer Login**: Salvar playlists, criar nova playlist e adicionar músicas.

### 4.7 Páginas de Álbum e Artista (`features/album`, `features/artist`)
- Acesso aberto a detalhes de álbum e perfil do artista.

### 4.8 Equalizador de Áudio (`features/equalizer`)
- Controles de frequências e presets para todos os usuários.
