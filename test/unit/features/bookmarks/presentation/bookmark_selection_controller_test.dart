import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_selection_controller.dart';

void main() {
  group('BookmarkSelectionController', () {
    test('vide et inactif par défaut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(
        bookmarkSelectionControllerProvider(BookmarkSelectionScope.home),
      );

      expect(state.isSelectionModeActive, isFalse);
      expect(state.selectedIds, isEmpty);
    });

    test('toggleSelectionMode() active le mode, puis le désactive et vide '
        'la sélection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        bookmarkSelectionControllerProvider(
          BookmarkSelectionScope.home,
        ).notifier,
      );

      notifier.toggleSelectionMode();
      notifier.toggleSelected('1');
      expect(
        container
            .read(bookmarkSelectionControllerProvider(BookmarkSelectionScope.home))
            .isSelectionModeActive,
        isTrue,
      );

      notifier.toggleSelectionMode();
      final state = container.read(
        bookmarkSelectionControllerProvider(BookmarkSelectionScope.home),
      );
      expect(state.isSelectionModeActive, isFalse);
      expect(state.selectedIds, isEmpty);
    });

    test('toggleSelected() ajoute puis retire un identifiant', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        bookmarkSelectionControllerProvider(
          BookmarkSelectionScope.home,
        ).notifier,
      );

      notifier.toggleSelected('1');
      notifier.toggleSelected('2');
      expect(
        container
            .read(bookmarkSelectionControllerProvider(BookmarkSelectionScope.home))
            .selectedIds,
        {'1', '2'},
      );

      notifier.toggleSelected('1');
      expect(
        container
            .read(bookmarkSelectionControllerProvider(BookmarkSelectionScope.home))
            .selectedIds,
        {'2'},
      );
    });

    test('clearSelection() vide la sélection sans désactiver le mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        bookmarkSelectionControllerProvider(
          BookmarkSelectionScope.home,
        ).notifier,
      );

      notifier.toggleSelectionMode();
      notifier.toggleSelected('1');
      notifier.clearSelection();

      final state = container.read(
        bookmarkSelectionControllerProvider(BookmarkSelectionScope.home),
      );
      expect(state.isSelectionModeActive, isTrue);
      expect(state.selectedIds, isEmpty);
    });

    test('les scopes home et search ont un état totalement indépendant', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(
            bookmarkSelectionControllerProvider(
              BookmarkSelectionScope.home,
            ).notifier,
          )
          .toggleSelected('1');

      expect(
        container
            .read(bookmarkSelectionControllerProvider(BookmarkSelectionScope.home))
            .selectedIds,
        {'1'},
      );
      expect(
        container
            .read(
              bookmarkSelectionControllerProvider(BookmarkSelectionScope.search),
            )
            .selectedIds,
        isEmpty,
      );
    });
  });
}
