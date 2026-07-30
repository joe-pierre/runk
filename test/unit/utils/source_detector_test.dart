import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/utils/source_detector.dart';

void main() {
  group('SourceDetector', () {
    test('détecte YouTube (domaine principal et youtu.be)', () {
      expect(
        SourceDetector.detect('https://www.youtube.com/watch?v=abc123'),
        VideoSource.youtube,
      );
      expect(SourceDetector.detect('https://youtu.be/abc123'), VideoSource.youtube);
    });

    test('détecte TikTok', () {
      expect(
        SourceDetector.detect('https://www.tiktok.com/@user/video/123'),
        VideoSource.tiktok,
      );
    });

    test('détecte Instagram, Facebook, X/Twitter et Threads', () {
      expect(
        SourceDetector.detect('https://www.instagram.com/reel/abc/'),
        VideoSource.instagram,
      );
      expect(
        SourceDetector.detect('https://www.facebook.com/watch/?v=123'),
        VideoSource.facebook,
      );
      expect(
        SourceDetector.detect('https://fb.watch/abc123/'),
        VideoSource.facebook,
      );
      expect(
        SourceDetector.detect('https://twitter.com/user/status/123'),
        VideoSource.twitter,
      );
      expect(
        SourceDetector.detect('https://x.com/user/status/123'),
        VideoSource.twitter,
      );
      expect(
        SourceDetector.detect('https://www.threads.net/@user/post/123'),
        VideoSource.threads,
      );
    });

    test('retourne unknown pour un domaine non supporté ou une URL malformée', () {
      expect(
        SourceDetector.detect('https://example.com/video'),
        VideoSource.unknown,
      );
      expect(SourceDetector.detect('pas une url'), VideoSource.unknown);
      expect(SourceDetector.detect(''), VideoSource.unknown);
    });
  });
}
