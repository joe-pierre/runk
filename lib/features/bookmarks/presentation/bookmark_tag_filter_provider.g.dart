// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_tag_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tag actuellement sélectionné pour filtrer `HomeScreen`, ou `null` si
/// aucun filtre n'est actif (voir SPEC.md section 11 — écran Tags : "tap sur
/// un tag filtre HomeScreen").
///
/// État de présentation partagé entre `TagsScreen` (qui le fixe) et
/// `HomeScreen` (qui le lit pour filtrer sa liste) — ni l'un ni l'autre
/// écran ne recalcule lui-même la liste filtrée à partir d'une source
/// différente, `HomeScreen` continue de réutiliser [bookmarkListProvider]
/// tel quel.

@ProviderFor(BookmarkTagFilter)
final bookmarkTagFilterProvider = BookmarkTagFilterProvider._();

/// Tag actuellement sélectionné pour filtrer `HomeScreen`, ou `null` si
/// aucun filtre n'est actif (voir SPEC.md section 11 — écran Tags : "tap sur
/// un tag filtre HomeScreen").
///
/// État de présentation partagé entre `TagsScreen` (qui le fixe) et
/// `HomeScreen` (qui le lit pour filtrer sa liste) — ni l'un ni l'autre
/// écran ne recalcule lui-même la liste filtrée à partir d'une source
/// différente, `HomeScreen` continue de réutiliser [bookmarkListProvider]
/// tel quel.
final class BookmarkTagFilterProvider
    extends $NotifierProvider<BookmarkTagFilter, String?> {
  /// Tag actuellement sélectionné pour filtrer `HomeScreen`, ou `null` si
  /// aucun filtre n'est actif (voir SPEC.md section 11 — écran Tags : "tap sur
  /// un tag filtre HomeScreen").
  ///
  /// État de présentation partagé entre `TagsScreen` (qui le fixe) et
  /// `HomeScreen` (qui le lit pour filtrer sa liste) — ni l'un ni l'autre
  /// écran ne recalcule lui-même la liste filtrée à partir d'une source
  /// différente, `HomeScreen` continue de réutiliser [bookmarkListProvider]
  /// tel quel.
  BookmarkTagFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkTagFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkTagFilterHash();

  @$internal
  @override
  BookmarkTagFilter create() => BookmarkTagFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$bookmarkTagFilterHash() => r'fb94e0274969b48fee7e7f0a526669abf4392670';

/// Tag actuellement sélectionné pour filtrer `HomeScreen`, ou `null` si
/// aucun filtre n'est actif (voir SPEC.md section 11 — écran Tags : "tap sur
/// un tag filtre HomeScreen").
///
/// État de présentation partagé entre `TagsScreen` (qui le fixe) et
/// `HomeScreen` (qui le lit pour filtrer sa liste) — ni l'un ni l'autre
/// écran ne recalcule lui-même la liste filtrée à partir d'une source
/// différente, `HomeScreen` continue de réutiliser [bookmarkListProvider]
/// tel quel.

abstract class _$BookmarkTagFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
