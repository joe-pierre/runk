import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/share_intent_service.dart';
import '../../../core/services/share_intent_service_provider.dart';
import 'add_bookmark_sheet.dart';
import 'share_intent_processing_provider.dart';

/// Connecte `ShareIntentService` à `AddBookmarkSheet` pour tout le reste de
/// l'application.
///
/// Doit être placé comme contenu de la route initiale de l'app (ex:
/// `MaterialApp.home`), pour que son `context` soit déjà un descendant du
/// `Navigator` — nécessaire pour `showModalBottomSheet`.
///
/// Ouvre automatiquement la modale d'ajout pour chaque URL reçue via un
/// partage natif. En cas de partages multiples rapides, les URLs
/// supplémentaires sont mises en file d'attente (`Queue<String>`) : une
/// seule modale est affichée à la fois, la suivante ne s'ouvre qu'à la
/// fermeture de la précédente (voir SPEC.md section 13). Ne contient aucune
/// logique métier propre : délègue entièrement la récupération de
/// métadonnées et la sauvegarde à `AddBookmarkSheet`.
///
/// Publie son état de traitement dans `shareIntentProcessingProvider` (vrai
/// tant qu'une URL est en attente ou en cours d'affichage), consulté par la
/// suggestion clipboard pour respecter la priorité Share Intent > clipboard
/// (SPEC.md section 13, voir DECISIONS.md Tâche 6.5).
class ShareIntentGate extends ConsumerStatefulWidget {
  /// Crée le gate au-dessus de [child], le contenu applicatif normal.
  const ShareIntentGate({super.key, required this.child});

  /// Contenu applicatif au-dessus duquel la modale se superpose.
  final Widget child;

  @override
  ConsumerState<ShareIntentGate> createState() => _ShareIntentGateState();
}

class _ShareIntentGateState extends ConsumerState<ShareIntentGate> {
  final Queue<String> _pendingUrls = Queue<String>();
  bool _isProcessingQueue = false;
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    final service = ref.read(shareIntentServiceProvider);
    _subscription = service.sharedUrlStream.listen(_enqueueUrl);
    unawaited(_initialize(service));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Démarre l'écoute des partages natifs sans jamais bloquer le démarrage
  /// de l'app si le canal natif est indisponible (ex: Share Extension iOS
  /// pas encore configurée dans Xcode, voir DECISIONS.md Tâche 3, ou build
  /// sur une plateforme desktop sans support du plugin) — dégradation
  /// propre (SPEC.md section 4 règle 3), journalisée explicitement, jamais
  /// un `catch` silencieux.
  Future<void> _initialize(ShareIntentService service) async {
    try {
      await service.initialize();
    } on Exception catch (error) {
      debugPrint('ShareIntentService.initialize a échoué : $error');
    }
  }

  void _enqueueUrl(String url) {
    _pendingUrls.add(url);
    ref.read(shareIntentProcessingProvider.notifier).set(true);
    unawaited(_processQueue());
  }

  /// Affiche une modale par URL en attente, dans l'ordre de réception,
  /// jamais deux en même temps : `AddBookmarkSheet.show` n'est rappelé
  /// qu'une fois la précédente refermée.
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    try {
      while (_pendingUrls.isNotEmpty) {
        final url = _pendingUrls.removeFirst();
        if (!mounted) return;
        await AddBookmarkSheet.show(context, url: url);
      }
    } finally {
      _isProcessingQueue = false;
      if (mounted) {
        ref.read(shareIntentProcessingProvider.notifier).set(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
