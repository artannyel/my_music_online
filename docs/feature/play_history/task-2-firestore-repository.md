# Task 2: Data - Repositório do Firestore

## 📌 Descrição Aprofundada
Implementar o contrato do repositório utilizando o Firebase Firestore para leitura e gravação, otimizando as consultas para gerar as listas de Mais Tocadas e Histórico Recente.

## 🎯 Escopo da Task
1. **Implementar `FirestoreHistoryRepository`**:
   - Conectar com a coleção `/users/{userId}/play_history`.
   - `logPlay`: Insere um novo documento gerando um timestamp automático.
   - `getRecentHistory`: Realiza uma query `orderBy('playedAt', descending: true).limit(50)`.
   - **Agregação (Top 20 e Mensal)**: Devido às limitações de agregação do Firestore (group by), o sistema buscará os logs do usuário (filtrados por mês, no caso do mensal), contará a frequência localmente no app através de um `Map<String, TopTrackModel>` e retornará a lista ordenada por `playCount` (descendente). Para evitar custos altíssimos de leitura com usuários hardcore, pode ser implementado um documento auxiliar `stats` que incrementa via FieldValue.increment no momento do `logPlay`. O dev decide a melhor abordagem (leitura em massa vs incremento em stats).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/history/data/repositories/firestore_history_repository.dart`

## ✅ Critérios de Aceite
- Os métodos gravam corretamente no banco.
- Recuperação das últimas 50 músicas funcionando e ordenadas por tempo.
- Função de gerar as Top 20 Geral e Top do Mês agrupando e contando os registros com sucesso.
