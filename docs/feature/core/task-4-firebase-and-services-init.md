# Task 4: Inicialização de Serviços Globais (Firebase & Audio Handler)

## 📌 Descrição Aprofundada
Garantir que a aplicação inicialize todos os serviços nativos assíncronos no arquivo `main.dart` antes de renderizar a interface gráfica do usuário. Isso inclui a inicialização dos serviços do Firebase (`Firebase.initializeApp`) e a configuração do handler de áudio para execução em primeiro/segundo plano.

## 🎯 Escopo da Task
1. Criar serviço utilitário para Firebase em `lib/src/core/services/firebase_service.dart`.
2. Configurar `WidgetsFlutterBinding.ensureInitialized()` e chamar inicializadores no `lib/main.dart`.
3. Envolver o aplicativo com o `ProviderScope` do Riverpod.

## 📋 Arquivos a Modificar / Criar
- `lib/src/core/services/firebase_service.dart`
- `lib/main.dart`

## ✅ Critérios de Aceite
- Aplicativo inicializa sem erros assíncronos ou exceções de binding.
- Riverpod configurado com `ProviderScope` no topo da árvore de widgets.
