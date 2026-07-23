# Plano de Implementação - Feature: Auth (Autenticação)

## 1. Visão Geral
A feature `auth` gerencia a autenticação de usuários através do Firebase Auth. Ela é responsável pelo login, cadastro de novos usuários com email/senha, login social com Google, encerramento de sessão (logout) e proteção de rotas privadas do app através do `GoRouter`.

## 2. Referência de Design (Stitch)
- **Stitch Project**: [https://stitch.withgoogle.com/projects/16430281818792447633](https://stitch.withgoogle.com/projects/16430281818792447633)
- **Telas**: Login & Registro.
- **Aparência**: Campos de entrada estilizados em modo escuro (`#12141D`), bordas suaves, botões com gradiente Magenta/Violeta, botão dedicado para Login com Google e feedback visual de carregamento.

## 3. Arquitetura da Feature
```text
lib/src/features/auth/
├── domain/
│   ├── models/
│   │   └── user_model.dart
│   └── repositories/
│       └── auth_repository.dart
├── data/
│   └── repositories/
│       └── firebase_auth_repository.dart
└── presentation/
    ├── controllers/
    │   └── auth_controller.dart
    └── views/
        ├── login_screen.dart
        └── register_screen.dart
```

## 4. Divisão de Tasks
- [ ] [Task 1: Domain - Modelo User & Interface AuthRepository](./task-1-domain-models-and-repository.md)
- [ ] [Task 2: Data - Implementação FirebaseAuthRepository](./task-2-firebase-auth-repository.md)
- [ ] [Task 3: Presentation - Controller de Autenticação com Riverpod](./task-3-auth-riverpod-controller.md)
- [ ] [Task 4: Presentation - Interface de Login (LoginScreen)](./task-4-login-screen-ui.md)
- [ ] [Task 5: Presentation - Interface de Cadastro (RegisterScreen)](./task-5-register-screen-ui.md)
- [ ] [Task 6: Router AuthGuard - Proteção de Rotas no GoRouter](./task-6-auth-guard-router.md)
