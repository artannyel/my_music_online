# Task 1: Domain - Modelo User & Interface AuthRepository

## 📌 Descrição Aprofundada
Definir as abstrações e o modelo de entidade `UserModel` independente de qualquer framework no módulo de domínio da feature de autenticação.

## 🎯 Escopo da Task
1. Criar `lib/src/features/auth/domain/models/user_model.dart`:
   - Campos: `id`, `email`, `displayName`, `photoUrl`.
2. Criar `lib/src/features/auth/domain/repositories/auth_repository.dart`:
   - Assinaturas de métodos: `signInWithEmailAndPassword`, `signUpWithEmailAndPassword`, `signOut`, `get currentUser`, `Stream<UserModel?> get authStateChanges`.

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/auth/domain/models/user_model.dart`
- `lib/src/features/auth/domain/repositories/auth_repository.dart`

## ✅ Critérios de Aceite
- Código sem dependência direta do pacote `firebase_auth` na camada de domínio.
