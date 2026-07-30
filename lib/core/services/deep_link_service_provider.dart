import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'deep_link_service.dart';

part 'deep_link_service_provider.g.dart';

/// Instance unique de [DeepLinkService] pour toute l'application.
///
/// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
/// de le recréer entre deux taps sur `BookmarkCard`.
@Riverpod(keepAlive: true)
DeepLinkService deepLinkService(Ref ref) => DeepLinkService();
