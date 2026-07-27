# Task 2: Data - Implementação FirebaseAuthRepository

## 📌 Descrição Aprofundada
Conectar o aplicativo ao SDK nativo do Firebase Auth, implementando o repositório definido na camada de domínio.

## 🎯 Escopo da Task
1. Criar `lib/src/features/auth/data/repositories/firebase_auth_repository.dart`.
2. Implementar a lógica de `signInWithGoogle` utilizando o pacote `google_sign_in`.
3. Mapear retornos de `firebase_auth.User` para `UserModel`.
4. Tratar exceções conhecidas (`FirebaseAuthException` e erros do Google SignIn) com mensagens amigáveis em português (ex: senha fraca, email já cadastrado, credenciais inválidas, cancelamento de fluxo).

## 📋 Arquivos a Modificar / Criar
- `lib/src/features/auth/data/repositories/firebase_auth_repository.dart`

## ✅ Critérios de Aceite
- Operações de autenticação capturando exceções e retornando `UserModel` válido.
