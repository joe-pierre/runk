import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:runk/core/services/share_intent_service.dart';

void main() {
  group('ShareIntentService', () {
    test(
      'rejette silencieusement les chaînes qui ne sont pas des URLs http/https',
      () async {
        final mediaStreamController =
            StreamController<List<SharedMediaFile>>();
        ReceiveSharingIntent.setMockValues(
          initialMedia: const [],
          mediaStream: mediaStreamController.stream,
        );

        final service = ShareIntentService();
        final emittedUrls = <String>[];
        service.sharedUrlStream.listen(emittedUrls.add);

        await service.initialize();

        mediaStreamController.add(<SharedMediaFile>[
          SharedMediaFile(path: 'texte sans lien', type: SharedMediaType.text),
          SharedMediaFile(
            path: 'ftp://exemple.com/video',
            type: SharedMediaType.text,
          ),
          SharedMediaFile(path: '', type: SharedMediaType.text),
          SharedMediaFile(
            path: 'https://www.youtube.com/watch?v=abc123',
            type: SharedMediaType.url,
          ),
        ]);

        // Laisse le microtask du StreamTransformer se propager.
        await Future<void>.delayed(Duration.zero);

        expect(emittedUrls, <String>['https://www.youtube.com/watch?v=abc123']);

        await mediaStreamController.close();
        service.dispose();
      },
    );
  });
}
