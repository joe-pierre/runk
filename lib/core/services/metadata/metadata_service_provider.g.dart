// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [MetadataService] pour toute l'application.
///
/// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
/// de le recréer entre deux ouvertures de `AddBookmarkSheet`.

@ProviderFor(metadataService)
final metadataServiceProvider = MetadataServiceProvider._();

/// Instance unique de [MetadataService] pour toute l'application.
///
/// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
/// de le recréer entre deux ouvertures de `AddBookmarkSheet`.

final class MetadataServiceProvider
    extends
        $FunctionalProvider<MetadataService, MetadataService, MetadataService>
    with $Provider<MetadataService> {
  /// Instance unique de [MetadataService] pour toute l'application.
  ///
  /// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
  /// de le recréer entre deux ouvertures de `AddBookmarkSheet`.
  MetadataServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metadataServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metadataServiceHash();

  @$internal
  @override
  $ProviderElement<MetadataService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MetadataService create(Ref ref) {
    return metadataService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetadataService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetadataService>(value),
    );
  }
}

String _$metadataServiceHash() => r'35ab18b11024734186a9c6b286a0223bad29c0bc';

/// Récupère les métadonnées de la vidéo à [url] via [metadataServiceProvider].
///
/// Provider `family` `autoDispose` (par défaut) : chaque URL a son propre
/// résultat, libéré dès que plus aucun widget ne l'écoute (ex: fermeture de
/// `AddBookmarkSheet`).

@ProviderFor(videoMetadata)
final videoMetadataProvider = VideoMetadataFamily._();

/// Récupère les métadonnées de la vidéo à [url] via [metadataServiceProvider].
///
/// Provider `family` `autoDispose` (par défaut) : chaque URL a son propre
/// résultat, libéré dès que plus aucun widget ne l'écoute (ex: fermeture de
/// `AddBookmarkSheet`).

final class VideoMetadataProvider
    extends
        $FunctionalProvider<
          AsyncValue<VideoMetadata>,
          VideoMetadata,
          FutureOr<VideoMetadata>
        >
    with $FutureModifier<VideoMetadata>, $FutureProvider<VideoMetadata> {
  /// Récupère les métadonnées de la vidéo à [url] via [metadataServiceProvider].
  ///
  /// Provider `family` `autoDispose` (par défaut) : chaque URL a son propre
  /// résultat, libéré dès que plus aucun widget ne l'écoute (ex: fermeture de
  /// `AddBookmarkSheet`).
  VideoMetadataProvider._({
    required VideoMetadataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'videoMetadataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$videoMetadataHash();

  @override
  String toString() {
    return r'videoMetadataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VideoMetadata> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VideoMetadata> create(Ref ref) {
    final argument = this.argument as String;
    return videoMetadata(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoMetadataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$videoMetadataHash() => r'17b8c5f12bc47bbc2cf33ac9389c864c6372269e';

/// Récupère les métadonnées de la vidéo à [url] via [metadataServiceProvider].
///
/// Provider `family` `autoDispose` (par défaut) : chaque URL a son propre
/// résultat, libéré dès que plus aucun widget ne l'écoute (ex: fermeture de
/// `AddBookmarkSheet`).

final class VideoMetadataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VideoMetadata>, String> {
  VideoMetadataFamily._()
    : super(
        retry: null,
        name: r'videoMetadataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Récupère les métadonnées de la vidéo à [url] via [metadataServiceProvider].
  ///
  /// Provider `family` `autoDispose` (par défaut) : chaque URL a son propre
  /// résultat, libéré dès que plus aucun widget ne l'écoute (ex: fermeture de
  /// `AddBookmarkSheet`).

  VideoMetadataProvider call(String url) =>
      VideoMetadataProvider._(argument: url, from: this);

  @override
  String toString() => r'videoMetadataProvider';
}
