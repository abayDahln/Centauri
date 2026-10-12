import 'dart:typed_data';

import 'package:centauri/features/prompt_editor/data/attachment_service.dart';
import 'package:centauri/features/prompt_editor/domain/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AttachmentService();
  Uint8List bytes() => Uint8List.fromList(List.filled(16, 7));

  group('AttachmentFormats', () {
    test('resolves raster images', () {
      final jpg = AttachmentFormats.resolve('photo.jpg');
      expect(jpg?.mime, 'image/jpeg');
      expect(jpg?.isText, isFalse);

      final png = AttachmentFormats.resolve('shot.PNG');
      expect(png?.mime, 'image/png');
      expect(png?.isText, isFalse);
    });

    test('resolves text-based formats', () {
      expect(AttachmentFormats.resolve('icon.svg')?.isText, isTrue);
      expect(AttachmentFormats.resolve('page.html')?.isText, isTrue);
      expect(AttachmentFormats.resolve('style.css')?.isText, isTrue);
    });

    test('rejects unsupported formats', () {
      expect(AttachmentFormats.isSupported('archive.zip'), isFalse);
      expect(AttachmentFormats.resolve('noext'), isNull);
    });
  });

  group('AttachmentService', () {
    test('builds a raster attachment', () {
      final attachment = service.fromBytes('hero.png', bytes());
      expect(attachment.mimeType, 'image/png');
      expect(attachment.isText, isFalse);
      expect(attachment.dataUrl, startsWith('data:image/png;base64,'));
      expect(attachment.sizeBytes, 16);
    });

    test('builds a text attachment', () {
      final attachment = service.fromBytes('icon.svg', bytes());
      expect(attachment.isText, isTrue);
    });

    test('throws for unsupported format', () {
      expect(
        () => service.fromBytes('data.bin', bytes()),
        throwsA(isA<AttachmentException>()),
      );
    });

    test('throws when file is too large', () {
      final big = Uint8List(AttachmentService.maxBytes + 1);
      expect(
        () => service.fromBytes('big.png', big),
        throwsA(isA<AttachmentException>()),
      );
    });

    test('throws for empty file', () {
      expect(
        () => service.fromBytes('empty.png', Uint8List(0)),
        throwsA(isA<AttachmentException>()),
      );
    });
  });

  group('Attachment serialization', () {
    test('round-trips through JSON', () {
      final original = service.fromBytes('hero.png', bytes());
      final restored = Attachment.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.mimeType, original.mimeType);
      expect(restored.bytes, original.bytes);
      expect(restored.isText, original.isText);
    });
  });
}
