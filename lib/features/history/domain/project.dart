import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../canvas_preview/presentation/provider/canvas_provider.dart';
import '../../prompt_editor/domain/attachment.dart';

/// Satu percakapan/proyek yang tersimpan: berisi riwayat pesan dan frame UI
/// di board. Analog dengan "chat" di Gemini.
@immutable
class ProjectFrame {
  const ProjectFrame({
    required this.id,
    required this.title,
    required this.html,
    required this.offset,
    required this.size,
  });

  final String id;
  final String title;
  final String html;
  final Offset offset;
  final Size size;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'html': html,
    'dx': offset.dx,
    'dy': offset.dy,
    'w': size.width,
    'h': size.height,
  };

  static ProjectFrame fromJson(Map<String, dynamic> json) => ProjectFrame(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled',
    html: json['html'] as String? ?? '',
    offset: Offset(
      (json['dx'] as num?)?.toDouble() ?? 0,
      (json['dy'] as num?)?.toDouble() ?? 0,
    ),
    size: Size(
      (json['w'] as num?)?.toDouble() ?? 390,
      (json['h'] as num?)?.toDouble() ?? 844,
    ),
  );
}

@immutable
class ProjectMessage {
  const ProjectMessage({
    required this.role,
    required this.text,
    required this.kind,
    this.displayText,
    this.attachmentNames = const [],
    this.attachments = const [],
  });

  final String role; // user | assistant | error
  final String text; // chat | ui
  final String kind;

  /// Teks bersih untuk ditampilkan (tanpa konteks internal). Boleh null.
  final String? displayText;
  final List<String> attachmentNames;
  final List<Attachment> attachments;

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'kind': kind,
    if (displayText != null) 'displayText': displayText,
    'attachmentNames': attachmentNames,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  static ProjectMessage fromJson(Map<String, dynamic> json) => ProjectMessage(
    role: json['role'] as String? ?? 'user',
    text: json['text'] as String? ?? '',
    kind: json['kind'] as String? ?? 'chat',
    displayText: json['displayText'] as String?,
    attachmentNames:
        (json['attachmentNames'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
    attachments: (json['attachments'] as List<dynamic>? ?? [])
        .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}

/// Proyek tersimpan (satu percakapan + board-nya).
@immutable
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.messages,
    required this.frames,
    required this.activeFrameId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<ProjectMessage> messages;
  final List<ProjectFrame> frames;
  final String? activeFrameId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project copyWith({
    String? title,
    List<ProjectMessage>? messages,
    List<ProjectFrame>? frames,
    String? activeFrameId,
    bool clearActiveFrame = false,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      frames: frames ?? this.frames,
      activeFrameId: clearActiveFrame
          ? null
          : (activeFrameId ?? this.activeFrameId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ringkasan untuk daftar: teks pesan user pertama, dipakai bila judul kosong.
  /// Pakai `displayText` (teks asli user) bila ada agar konteks internal seperti
  /// `[CANVAS TARGET]` / design token tidak ikut tampil.
  String get preview {
    for (final message in messages) {
      if (message.role != 'user') continue;
      final raw = (message.displayText ?? message.text).trim();
      if (raw.isEmpty) continue;
      final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      return cleaned.length > 60 ? '${cleaned.substring(0, 60)}...' : cleaned;
    }
    return 'Percakapan kosong';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'frames': frames.map((f) => f.toJson()).toList(),
    'activeFrameId': activeFrameId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Project fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Percakapan baru',
    messages: (json['messages'] as List<dynamic>? ?? [])
        .map((m) => ProjectMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    frames: (json['frames'] as List<dynamic>? ?? [])
        .map((f) => ProjectFrame.fromJson(f as Map<String, dynamic>))
        .toList(),
    activeFrameId: json['activeFrameId'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
        DateTime.now(),
  );

  /// Bangun dari state board yang sedang aktif.
  static Project fromCanvas({
    required String id,
    required String title,
    required CanvasState state,
    required DateTime createdAt,
  }) {
    return Project(
      id: id,
      title: title,
      messages: state.messages
          .map(
            (m) => ProjectMessage(
              role: m.role.name,
              text: m.text,
              kind: m.kind.name,
              displayText: m.displayText,
              attachmentNames: m.attachmentNames,
              attachments: m.attachments,
            ),
          )
          .toList(),
      frames: state.frames
          .map(
            (f) => ProjectFrame(
              id: f.id,
              title: f.title,
              html: f.html,
              offset: f.offset,
              size: f.size,
            ),
          )
          .toList(),
      activeFrameId: state.activeFrameId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
