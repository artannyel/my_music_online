# Task 4: Player - Persistência, Fila e Integrações

## 📌 Descrição Aprofundada
O cérebro do reprodutor ganhará habilidades essenciais de salvamento automático (persistência de sessão) e conversão de filas ativas em Playlists.

## 🎯 Escopo da Task
1. **Persistência de Sessão**:
   - Implementar uso do `SharedPreferences` ou `Hive` (dependendo da preferência de cache do projeto) no Service/Controller do Player.
   - Toda vez que a `queue` ou `currentIndex` for alterado, serializar a lista em JSON e gravar localmente.
   - No `init` do app (ou do controller), carregar o JSON salvo, restaurar a `queue`, definir o `currentIndex` em estado "Pause" para que o player apareça com a música pausada e pronta pra tocar, de onde o usuário parou na última sessão.
2. **Salvar Fila como Playlist**:
   - Adicionar um botão no header (ou num menu suspenso) da Fila de Reprodução do Player: "Salvar como Playlist".
   - Encaminhar todas as faixas ativas (a lista atual) para o Modal/Fluxo de Criação de Playlist.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/player/data/services/audio_player_service.dart` (Para escutar e restaurar a persistência)
- `lib/src/features/player/presentation/controllers/player_controller.dart`
- `lib/src/features/player/presentation/views/full_player_screen.dart`

## ✅ Critérios de Aceite
- Fechar e reabrir o app mantém o player e fila preenchidos exatamente com a última música e estado.
- Transformar a rádio atual em uma playlist deve funcionar de forma fluída.
