import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_online/src/core/widgets/confirm_delete_dialog.dart';

void main() {
  group('showConfirmDeleteDialog Widget Tests', () {
    testWidgets('exibe título, mensagem e botões padrão corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showConfirmDeleteDialog(
                    context: context,
                    title: 'Remover da Playlist?',
                    message: 'Deseja remover "Bohemian Rhapsody" desta playlist?',
                  );
                },
                child: const Text('Abrir Dialog'),
              ),
            ),
          ),
        ),
      );

      // Abre o diálogo
      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Remover da Playlist?'), findsOneWidget);
      expect(find.text('Deseja remover "Bohemian Rhapsody" desta playlist?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Remover'), findsOneWidget);
    });

    testWidgets('retorna false ao clicar em Cancelar', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showConfirmDeleteDialog(
                    context: context,
                    title: 'Remover da Fila?',
                    message: 'Deseja remover a música da fila?',
                  );
                },
                child: const Text('Abrir Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Remover da Fila?'), findsNothing);
    });

    testWidgets('retorna true ao clicar em Confirmar/Remover', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showConfirmDeleteDialog(
                    context: context,
                    title: 'Excluir Download?',
                    message: 'Tem certeza que deseja excluir o download?',
                    confirmLabel: 'Excluir',
                  );
                },
                child: const Text('Abrir Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir'), findsOneWidget);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Excluir Download?'), findsNothing);
    });
  });
}
