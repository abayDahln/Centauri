import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../canvas_preview/domain/board_frame.dart';
import '../../canvas_preview/presentation/provider/canvas_provider.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

/// State daftar proyek + proyek aktif.
class HistoryState {
  const HistoryState({
    this.projects = const [],
    this.activeProjectId,
    this.query = '',
  });

  /// Semua proyek, terurut terbaru di atas.
  final List<Project> projects;
  final String? activeProjectId;
  final String query;

  List<Project> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return projects;
    return projects
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.preview.toLowerCase().contains(q),
        )
        .toList();
  }

  bool get isEmpty => projects.isEmpty;

  HistoryState copyWith({
    List<Project>? projects,
    String? activeProjectId,
    bool clearActive = false,
    String? query,
  }) {
    return HistoryState(
      projects: projects ?? this.projects,
      activeProjectId: clearActive
          ? null
          : (activeProjectId ?? this.activeProjectId),
      query: query ?? this.query,
    );
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<HistoryState> {
  final _uuid = const Uuid();
  DateTime _createdAt = DateTime.now();

  @override
  HistoryState build() {
    final repo = ref.read(projectRepositoryProvider);
    final projects = _sorted(repo.getAll());
    return HistoryState(
      projects: projects,
      activeProjectId: repo.activeProjectId,
    );
  }

  List<Project> _sorted(List<Project> projects) {
    final copy = [...projects]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// Mulai sesi baru yang kosong (belum disimpan sampai ada aktivitas).
  void startNew() {
    state = state.copyWith(clearActive: true);
    ref.read(canvasProvider.notifier).clearBoard();
    _createdAt = DateTime.now();
  }

  /// Simpan state board saat ini menjadi proyek (auto-save).
  /// Bila belum ada proyek aktif, buat baru.
  void persistCurrent({String? title}) {
    final canvas = ref.read(canvasProvider);
    // Jangan simpan sesi yang benar-benar kosong.
    if (canvas.messages.isEmpty && canvas.frames.isEmpty) return;

    final repo = ref.read(projectRepositoryProvider);
    final id = state.activeProjectId ?? _uuid.v4();
    final isNew = state.activeProjectId == null;

    final project = Project.fromCanvas(
      id: id,
      title: title ?? _deriveTitle(canvas),
      state: canvas,
      createdAt: isNew ? _createdAt : _existingCreatedAt(id),
    );

    repo.save(project);
    repo.setActiveProjectId(id);

    final updated = _sorted([
      ...state.projects.where((p) => p.id != id),
      project,
    ]);
    state = state.copyWith(projects: updated, activeProjectId: id);
  }

  DateTime _existingCreatedAt(String id) {
    for (final project in state.projects) {
      if (project.id == id) return project.createdAt;
    }
    return _createdAt;
  }

  String _deriveTitle(CanvasState canvas) {
    // Judul dari prompt user pertama; fallback judul frame pertama.
    for (final message in canvas.messages) {
      if (message.role == ChatRole.user && message.text.trim().isNotEmpty) {
        final cleaned = message.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        return cleaned.length > 48 ? '${cleaned.substring(0, 48)}...' : cleaned;
      }
    }
    if (canvas.frames.isNotEmpty) return canvas.frames.first.title;
    return 'Percakapan baru';
  }

  /// Buka proyek tersimpan: muat pesan + frame ke board.
  Future<void> open(String id) async {
    final repo = ref.read(projectRepositoryProvider);
    Project? project;
    for (final p in state.projects) {
      if (p.id == id) project = p;
    }
    if (project == null) return;

    await repo.setActiveProjectId(id);
    _createdAt = project.createdAt;
    state = state.copyWith(activeProjectId: id);

    final messages = project.messages
        .map(
          (m) => CanvasMessage(
            role: _roleFromName(m.role),
            text: m.text,
            displayText: m.displayText,
            kind: m.kind == 'ui' ? ChatMessageKind.ui : ChatMessageKind.chat,
            attachmentNames: m.attachmentNames,
            attachments: m.attachments,
          ),
        )
        .toList();

    final frames = project.frames
        .map(
          (f) => BoardFrame(
            id: f.id,
            title: f.title,
            html: f.html,
            offset: f.offset,
            size: f.size,
            isActive: f.id == project!.activeFrameId,
          ),
        )
        .toList();

    await ref
        .read(canvasProvider.notifier)
        .loadSession(
          messages: messages,
          frames: frames,
          activeFrameId: project.activeFrameId,
        );
  }

  ChatRole _roleFromName(String name) => switch (name) {
    'assistant' => ChatRole.assistant,
    'error' => ChatRole.error,
    _ => ChatRole.user,
  };

  Future<void> delete(String id) async {
    final repo = ref.read(projectRepositoryProvider);
    await repo.delete(id);
    final remaining = state.projects.where((p) => p.id != id).toList();
    final wasActive = state.activeProjectId == id;
    state = HistoryState(
      projects: remaining,
      activeProjectId: wasActive ? null : state.activeProjectId,
      query: state.query,
    );
    if (wasActive) {
      ref.read(canvasProvider.notifier).clearBoard();
      _createdAt = DateTime.now();
    }
  }

  Future<void> rename(String id, String title) async {
    final repo = ref.read(projectRepositoryProvider);
    final updatedProjects = <Project>[];
    for (final project in state.projects) {
      if (project.id == id) {
        final renamed = project.copyWith(
          title: title.trim().isEmpty ? project.title : title.trim(),
          updatedAt: DateTime.now(),
        );
        repo.save(renamed);
        updatedProjects.add(renamed);
      } else {
        updatedProjects.add(project);
      }
    }
    state = state.copyWith(projects: _sorted(updatedProjects));
  }
}
