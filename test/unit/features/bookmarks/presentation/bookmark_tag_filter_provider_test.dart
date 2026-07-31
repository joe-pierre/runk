import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_tag_filter_provider.dart';

void main() {
  test('vaut null par défaut, puis reflète select()/clear()', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(bookmarkTagFilterProvider), isNull);

    container.read(bookmarkTagFilterProvider.notifier).select('drole');
    expect(container.read(bookmarkTagFilterProvider), 'drole');

    container.read(bookmarkTagFilterProvider.notifier).clear();
    expect(container.read(bookmarkTagFilterProvider), isNull);
  });
}
