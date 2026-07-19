# Task 2: Data - Implementação FirebaseAuthRepository

## 📌 Descrição Aprofundada
Conectar o aplicativo ao SDK nativo do Firebase Auth, implementando o repositório definido na camada de domínio.

## 🎯 Escopo da Task
1. Criar `lib/src/features/auth/data/repositories/firebase_auth_repository.dart`.
2. Mapear retornos de `firebase_auth.User` para `UserModel`.
3. Tratar exceções conhecidas (`FirebaseAuthException`) com mensagens amigáveis em português (ex: senha fraca, email já cadastrado, credenciais inválidas).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/auth/data/repositories/firebase_auth_repository.dart`

## ✅ Critérios de Aceite
- Operações de autenticação capturando exceções e retornando `UserModel` válido.
