import 'package:flutter/foundation.dart';

/// Jenis rujukan yang bisa ditempel ke prompt.
enum PromptMentionKind { element, page, allPages }

/// Rujukan konteks yang menempel di prompt berikutnya: satu elemen di halaman
/// aktif, satu halaman tertentu, atau seluruh halaman.
@immutable
class PromptMention {
  const PromptMention({
    required this.kind,
    required this.label,
    this.nodeId,
    this.pageId,
    this.pageName,
  });

  final PromptMentionKind kind;

  /// Teks chip di prompt bar, mis. `button · Masukkan Keranjang`.
  final String label;

  /// Id node DOM (khusus [PromptMentionKind.element]).
  final String? nodeId;

  /// Halaman asal rujukan (null untuk [PromptMentionKind.allPages]).
  final String? pageId;
  final String? pageName;

  bool get isElement => kind == PromptMentionKind.element;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromptMention &&
        other.kind == kind &&
        other.nodeId == nodeId &&
        other.pageId == pageId &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(kind, nodeId, pageId, label);

  @override
  String toString() => 'PromptMention(${kind.name}, $label)';
}
