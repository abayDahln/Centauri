import 'package:flutter/foundation.dart';

import '../../canvas_preview/domain/page_slug.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';
import '../../prompt_editor/domain/attachment.dart';

/// Versi skema proyek tersimpan. v2 menggantikan `frames` (board) dengan
/// `pages` (UI & prototype builder).
const int kProjectSchemaVersion = 2;

/// Satu halaman tersimpan: HTML self-contained + nama file untuk link.
@immutable
class ProjectPage {
  const ProjectPage({
    required this.id,
    required this.name,
    required this.slug,
    required this.html,
  });

  final String id;
  final String name;
  final String slug;
  final String html;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'html': html,
  };

  static ProjectPage fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? json['title'] as String? ?? 'Untitled';
    final slug = json['slug'] as String? ?? slugify(name);
    return ProjectPage(
      id: json['id'] as String? ?? 'page',
      name: name,
      slug: slug,
      html: json['html'] as String? ?? '',
    );
  }
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

/// Proyek tersimpan (satu percakapan + halaman-halamannya).
@immutable
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.messages,
    required this.pages,
    required this.activePageId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<ProjectMessage> messages;
  final List<ProjectPage> pages;
  final String? activePageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project copyWith({
    String? title,
    List<ProjectMessage>? messages,
    List<ProjectPage>? pages,
    String? activePageId,
    bool clearActivePage = false,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      pages: pages ?? this.pages,
      activePageId: clearActivePage
          ? null
          : (activePageId ?? this.activePageId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ringkasan untuk daftar: teks pesan user pertama, dipakai bila judul kosong.
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
    'pages': pages.map((p) => p.toJson()).toList(),
    'activePageId': activePageId,
    'schemaVersion': kProjectSchemaVersion,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Project fromJson(Map<String, dynamic> json) {
    final pagesJson = json['pages'] as List<dynamic>?;
    final List<ProjectPage> pages;
    if (pagesJson != null) {
      pages = pagesJson
          .map((p) => ProjectPage.fromJson(p as Map<String, dynamic>))
          .toList();
    } else {
      // Migrasi v1: `frames` (board) -> `pages` (koordinat dibuang, HTML tetap).
      pages = _migrateFrames(json['frames'] as List<dynamic>?);
    }

    final activePageId =
        json['activePageId'] as String? ?? json['activeFrameId'] as String?;

    return Project(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Percakapan baru',
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => ProjectMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      pages: pages,
      activePageId: activePageId,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Migrasi proyek skema lama (`frames` berkoordinat) ke `pages`.
  static List<ProjectPage> _migrateFrames(List<dynamic>? frames) {
    if (frames == null || frames.isEmpty) return const [];
    final used = <String>[];
    final pages = <ProjectPage>[];
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      if (frame is! Map<String, dynamic>) continue;
      final name = frame['title'] as String? ?? 'Halaman ${i + 1}';
      final slug = uniqueSlug(slugify(name), used);
      used.add(slug);
      pages.add(
        ProjectPage(
          id: frame['id'] as String? ?? 'page_$i',
          name: name,
          slug: slug,
          html: frame['html'] as String? ?? '',
        ),
      );
    }
    return pages;
  }

  /// Bangun dari state workspace yang sedang aktif.
  static Project fromCanvas({
    required String id,
    required String title,
    required WorkspaceState state,
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
      pages: state.pages
          .map(
            (p) => ProjectPage(
              id: p.id,
              name: p.name,
              slug: p.slug,
              html: p.html,
            ),
          )
          .toList(),
      activePageId: state.activePageId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
