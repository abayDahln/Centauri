import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'dom_tree.dart';

/// Satu frame/kartu di dalam board, mewakili satu hasil generasi UI.
/// Analog dengan "frame" di Figma / "screen" di Stitch.
@immutable
class BoardFrame {
  const BoardFrame({
    required this.id,
    required this.title,
    required this.html,
    required this.offset,
    required this.size,
    this.domTree,
    this.isActive = false,
  });

  final String id;

  /// Judul frame (mis. "Stitch Studio", "Landing Page").
  final String title;

  /// HTML self-contained hasil AI (sudah di-stamp id untuk layers).
  final String html;

  /// Posisi frame pada koordinat board (bukan layar).
  final Offset offset;

  /// Ukuran frame pada koordinat board.
  final Size size;

  /// DOM tree frame ini (untuk panel Layers).
  final DomTreeResult? domTree;

  /// Frame yang sedang aktif/dipilih.
  final bool isActive;

  BoardFrame copyWith({
    String? title,
    String? html,
    Offset? offset,
    Size? size,
    DomTreeResult? domTree,
    bool? isActive,
  }) {
    return BoardFrame(
      id: id,
      title: title ?? this.title,
      html: html ?? this.html,
      offset: offset ?? this.offset,
      size: size ?? this.size,
      domTree: domTree ?? this.domTree,
      isActive: isActive ?? this.isActive,
    );
  }
}
