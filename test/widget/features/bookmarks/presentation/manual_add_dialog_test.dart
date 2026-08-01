import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/bookmarks/presentation/manual_add_dialog.dart';

void main() {
  Future<void> pumpDialogHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (context) => const ManualAddDialog(),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'affiche une erreur inline sans se fermer si la chaîne n\'est pas une '
    'URL valide',
    (tester) async {
      await pumpDialogHost(tester);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'pas un lien');
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.text('Ce n\'est pas un lien valide.'), findsOneWidget);
      expect(find.byType(ManualAddDialog), findsOneWidget);
    },
  );

  testWidgets(
    'referme la popup en retournant l\'URL validée quand la saisie est une '
    'URL exploitable',
    (tester) async {
      await pumpDialogHost(tester);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'https://youtube.com/watch?v=abc',
      );
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualAddDialog), findsNothing);
    },
  );

  testWidgets(
    'extrait la meilleure URL exploitable si la saisie contient du texte '
    'libre autour du lien',
    (tester) async {
      await pumpDialogHost(tester);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'regarde ça : https://www.tiktok.com/@user/video/123 trop drôle',
      );
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualAddDialog), findsNothing);
    },
  );

  testWidgets('l\'annulation referme la popup sans URL', (tester) async {
    await pumpDialogHost(tester);
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualAddDialog), findsNothing);
  });

  testWidgets(
    'efface l\'erreur affichée dès que l\'utilisateur modifie la saisie',
    (tester) async {
      await pumpDialogHost(tester);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'pas un lien');
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      expect(find.text('Ce n\'est pas un lien valide.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'p');
      await tester.pump();

      expect(find.text('Ce n\'est pas un lien valide.'), findsNothing);
    },
  );
}
