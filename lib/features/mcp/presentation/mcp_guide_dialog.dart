import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_dialog.dart';
import '../../../../app/widgets/app_toast.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../data/mcp_server.dart';

/// Panduan koneksi MCP server lokal untuk agent eksternal.
///
/// Dialog lebar di desktop, sheet penuh di layar sempit. Isinya mengikuti
/// [McpServer.toolSchemas] supaya daftar tool tidak pernah basi.
void showMcpGuide(BuildContext context, {String? endpoint}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 760) {
    showAppDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: dialogContext.palette.bgSurface,
        insetPadding: const EdgeInsets.all(48),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xl,
          side: BorderSide(color: dialogContext.palette.borderSubtle),
        ),
        child: SizedBox(
          width: math.min(780, size.width - 96),
          height: math.min(700, size.height - 96),
          child: McpGuideView(endpoint: endpoint),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      side: BorderSide(color: context.palette.borderSubtle),
    ),
    builder: (_) => SizedBox(
      height: size.height * 0.92,
      child: McpGuideView(endpoint: endpoint),
    ),
  );
}

class McpGuideView extends ConsumerStatefulWidget {
  const McpGuideView({super.key, this.endpoint});

  /// Endpoint aktif; kalau server belum menyala, dipakai alamat bawaan.
  final String? endpoint;

  @override
  ConsumerState<McpGuideView> createState() => _McpGuideViewState();
}

class _McpGuideViewState extends ConsumerState<McpGuideView> {
  static const String _defaultEndpoint = 'http://127.0.0.1:8765/mcp';

  int _client = 0;

  String get _endpoint => widget.endpoint ?? _defaultEndpoint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final server = ref.watch(mcpServerProvider);
    final endpoint = server.endpoint ?? _endpoint;
    final clients = _clients(endpoint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mcpGuideTitle, style: context.text.panelTitle),
                    const SizedBox(height: 4),
                    Text(l10n.mcpGuideSubtitle, style: context.text.uiSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.palette.borderSubtle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              _Step(
                index: 1,
                title: l10n.mcpGuideStepStart,
                children: [
                  Text(l10n.mcpGuideStepStartDesc, style: context.text.uiSmall),
                  const SizedBox(height: 10),
                  _StatusLine(
                    running: server.isRunning,
                    label: server.isRunning ? l10n.mcpRunning : l10n.mcpStopped,
                  ),
                  const SizedBox(height: 10),
                  _EndpointLine(label: l10n.mcpGuideEndpoint, value: endpoint),
                  const SizedBox(height: 6),
                  _EndpointLine(
                    label: 'SSE',
                    value: endpoint.replaceFirst('/mcp', '/events'),
                  ),
                  const SizedBox(height: 6),
                  _EndpointLine(
                    label: 'Status',
                    value: endpoint.replaceFirst('/mcp', '/status'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Step(
                index: 2,
                title: l10n.mcpGuideStepConnect,
                children: [
                  Text(
                    l10n.mcpGuideStepConnectDesc,
                    style: context.text.uiSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < clients.length; i++)
                        _ClientChip(
                          label: clients[i].name,
                          selected: i == _client,
                          onTap: () => setState(() => _client = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Snippet(
                    label: l10n.mcpGuideWhere(clients[_client].path),
                    code: clients[_client].json,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Step(
                index: 3,
                title: l10n.mcpGuideStepTest,
                children: [
                  Text(l10n.mcpGuideStepTestDesc, style: context.text.uiSmall),
                  const SizedBox(height: 10),
                  const _Snippet(label: 'POST /mcp', code: _testPayload),
                ],
              ),
              const SizedBox(height: 22),
              _Step(
                index: 4,
                title: l10n.mcpGuideStepTools,
                children: [
                  Text(l10n.mcpGuideStepToolsDesc, style: context.text.uiSmall),
                  const SizedBox(height: 8),
                  for (final schema in McpServer.toolSchemas())
                    _ToolRow(
                      name: schema['name'] as String,
                      description:
                          _toolDescriptions(l10n)[schema['name']] ?? '',
                    ),
                ],
              ),
              const SizedBox(height: 22),
              SoftPanel(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mcpGuideTipTitle,
                      style: context.text.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Tip(text: l10n.mcpGuideTipAppClosed),
                    _Tip(text: l10n.mcpGuideTipPort),
                    _Tip(text: l10n.mcpGuideTipLocal),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Satu preset per agent. Semua contoh JSON; nama file dan nama agent
  /// adalah istilah teknis yang tidak diterjemahkan.
  List<_GuideClient> _clients(String endpoint) => [
    _GuideClient(
      name: 'Claude Code · CodeBuddy',
      path: '.mcp.json',
      json:
          '''{
  "mcpServers": {
    "centauri": {
      "type": "http",
      "url": "$endpoint"
    }
  }
}''',
    ),
    _GuideClient(
      name: 'Cursor',
      path: '.cursor/mcp.json',
      json:
          '''{
  "mcpServers": {
    "centauri": { "url": "$endpoint" }
  }
}''',
    ),
    _GuideClient(
      name: 'OpenCode',
      path: 'opencode.jsonc',
      json:
          '''{
  "mcp": {
    "servers": {
      "centauri": {
        "type": "remote",
        "url": "$endpoint",
        "disabled": false
      }
    }
  }
}''',
    ),
    _GuideClient(
      name: 'Qoder',
      path: '.qoder/settings.json',
      json:
          '''{
  "mcpServers": {
    "centauri": {
      "type": "http",
      "url": "$endpoint",
      "disabled": false
    }
  }
}''',
    ),
    _GuideClient(
      name: 'Antigravity',
      path: '.agents/mcp_config.json',
      json:
          '''{
  "mcpServers": {
    "centauri": {
      "serverUrl": "$endpoint",
      "disabled": false
    }
  }
}''',
    ),
    _GuideClient(
      name: 'Cline',
      path: 'cline_mcp_settings.json',
      json:
          '''{
  "mcpServers": {
    "centauri": {
      "type": "streamableHttp",
      "url": "$endpoint",
      "disabled": false
    }
  }
}''',
    ),
  ];

  static const String _testPayload = '''{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": { "name": "list_sessions", "arguments": {} }
}''';

  Map<String, String> _toolDescriptions(AppLocalizations l10n) => {
    'list_sessions': l10n.mcpToolListSessions,
    'get_session': l10n.mcpToolGetSession,
    'get_page_html': l10n.mcpToolGetPageHtml,
    'write_page': l10n.mcpToolWritePage,
    'delete_page': l10n.mcpToolDeletePage,
    'post_to_chat': l10n.mcpToolPostToChat,
  };
}

class _GuideClient {
  const _GuideClient({
    required this.name,
    required this.path,
    required this.json,
  });

  final String name;
  final String path;
  final String json;
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.children,
  });

  final int index;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.palette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: context.text.label.copyWith(
                  color: context.palette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: context.text.panelTitle)),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.running, required this.label});

  final bool running;
  final String label;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: label,
      color: running
          ? context.palette.statusSuccess
          : context.palette.textDisabled,
    );
  }
}

class _EndpointLine extends StatelessWidget {
  const _EndpointLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 78, child: Text(label, style: context.text.caption)),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 12,
              color: context.palette.textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 15),
          tooltip: context.l10n.mcpCopyAddress,
          onPressed: () => _copy(context, value),
        ),
      ],
    );
  }
}

class _ClientChip extends StatelessWidget {
  const _ClientChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? context.palette.primarySoft
            : context.palette.bgSurface,
        borderRadius: AppRadius.pill,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: selected
                    ? context.palette.primary
                    : context.palette.borderSubtle,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: context.text.label.copyWith(
                color: selected
                    ? context.palette.primary
                    : context.palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Snippet extends StatelessWidget {
  const _Snippet({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.palette.bgSunken,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: AppFonts.monoFamily,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 11,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 15),
                  tooltip: context.l10n.mcpGuideCopy,
                  onPressed: () => _copy(context, code),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.palette.borderSubtle),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 11.5,
                height: 1.6,
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.name, required this.description});

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              name,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 11,
                height: 1.5,
                color: context.palette.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: context.text.uiSmall.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, end: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.textDisabled,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.text.uiSmall.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showAppToast(
    context,
    context.l10n.mcpGuideCopied,
    kind: AppToastKind.success,
  );
}
