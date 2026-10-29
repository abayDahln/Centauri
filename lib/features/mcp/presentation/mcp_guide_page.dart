import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_palette.dart';
import '../../../app/config/theme.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../app/widgets/stitch_widgets.dart';
import '../data/mcp_bridge.dart';
import '../data/mcp_server.dart';

/// Screen mandiri untuk Panduan Koneksi MCP Server (Local Agent Bridge).
///
/// Dirancang sebagai dedicated screen yang bersih, terstruktur, responsif,
/// dan nyaman dilihat di berbagai ukuran layar.
class McpGuidePage extends ConsumerStatefulWidget {
  const McpGuidePage({super.key, this.endpoint});

  /// Endpoint aktif opsional. Jika null, membaca dari server.
  final String? endpoint;

  @override
  ConsumerState<McpGuidePage> createState() => _McpGuidePageState();
}

class _McpGuidePageState extends ConsumerState<McpGuidePage> {
  static const String _defaultEndpoint = 'http://127.0.0.1:8765/mcp';

  int _selectedClient = 0;
  bool _starting = false;

  String get _endpoint => widget.endpoint ?? _defaultEndpoint;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref.read(mcpServerProvider).start(bridge: McpBridge(ref.container));
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final server = ref.watch(mcpServerProvider);
    final endpoint = server.endpoint ?? _endpoint;
    final clients = _clients(endpoint);
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      backgroundColor: context.palette.bgBase,
      appBar: AppBar(
        title: Text(l10n.mcpGuideTitle),
        leading: const BackButton(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.palette.borderSubtle),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 32,
          vertical: compact ? 20 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _HeaderBanner(subtitle: l10n.mcpGuideSubtitle),
                const SizedBox(height: 24),

                // Step 1: Jalankan MCP Server
                _GuideCard(
                  stepNumber: 1,
                  title: l10n.mcpGuideStepStart,
                  description: l10n.mcpGuideStepStartDesc,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          StatusPill(
                            label: server.isRunning
                                ? l10n.mcpRunning
                                : l10n.mcpStopped,
                            color: server.isRunning
                                ? context.palette.statusSuccess
                                : context.palette.textDisabled,
                          ),
                          if (!server.isRunning)
                            FilledButton.icon(
                              onPressed: _starting ? null : _start,
                              icon: _starting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow, size: 16),
                              label: Text(
                                _starting ? l10n.mcpStarting : l10n.mcpStart,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _EndpointTile(
                        label: l10n.mcpGuideEndpoint,
                        value: endpoint,
                        badge: 'JSON-RPC',
                      ),
                      const SizedBox(height: 8),
                      _EndpointTile(
                        label: 'SSE Events',
                        value: endpoint.replaceFirst('/mcp', '/events'),
                        badge: 'Stream',
                      ),
                      const SizedBox(height: 8),
                      _EndpointTile(
                        label: 'Health Check',
                        value: endpoint.replaceFirst('/mcp', '/status'),
                        badge: 'GET',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 2: Hubungkan Agent Favorit
                _GuideCard(
                  stepNumber: 2,
                  title: l10n.mcpGuideStepConnect,
                  description: l10n.mcpGuideStepConnectDesc,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < clients.length; i++)
                            _AgentSelectorChip(
                              name: clients[i].name,
                              selected: i == _selectedClient,
                              onTap: () => setState(() => _selectedClient = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _CodeSnippetCard(
                        headerTitle:
                            l10n.mcpGuideWhere(clients[_selectedClient].path),
                        code: clients[_selectedClient].json,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 3: Verifikasi Koneksi
                _GuideCard(
                  stepNumber: 3,
                  title: l10n.mcpGuideStepTest,
                  description: l10n.mcpGuideStepTestDesc,
                  content: const _CodeSnippetCard(
                    headerTitle: 'POST /mcp (JSON-RPC Request)',
                    code: _testPayload,
                  ),
                ),
                const SizedBox(height: 20),

                // Step 4: Tool yang Tersedia
                _GuideCard(
                  stepNumber: 4,
                  title: l10n.mcpGuideStepTools,
                  description: l10n.mcpGuideStepToolsDesc,
                  content: _ToolsSection(l10n: l10n),
                ),
                const SizedBox(height: 20),

                // Catatan / Troubleshooting Tips
                _TroubleshootingCard(l10n: l10n),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_GuideClient> _clients(String endpoint) => [
        _GuideClient(
          name: 'Claude Code · CodeBuddy',
          path: '.mcp.json',
          json: '''{
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
          json: '''{
  "mcpServers": {
    "centauri": { "url": "$endpoint" }
  }
}''',
        ),
        _GuideClient(
          name: 'OpenCode',
          path: 'opencode.jsonc',
          json: '''{
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
          json: '''{
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
          json: '''{
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
          json: '''{
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
}

// ────────────────────────────────────────────────────────────────────────────
// Header banner di bagian atas screen
// ────────────────────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.primarySoft,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.palette.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.palette.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hub_outlined,
              size: 22,
              color: context.palette.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Context Protocol (MCP)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.palette.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.text.uiSmall.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Kartu per langkah (Step Card)
// ────────────────────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.content,
  });

  final int stepNumber;
  final String title;
  final String description;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palette.primarySoft,
                    borderRadius: AppRadius.sm,
                    border: Border.all(
                      color: context.palette.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontFamily: AppFonts.monoFamily,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.palette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.panelTitle),
                      const SizedBox(height: 3),
                      Text(description, style: context.text.uiSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.palette.borderSubtle),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: content,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Endpoint URL Tile
// ────────────────────────────────────────────────────────────────────────────

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({
    required this.label,
    required this.value,
    required this.badge,
  });

  final String label;
  final String value;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.bgSunken,
        borderRadius: AppRadius.sm,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              borderRadius: AppRadius.sm,
              border: Border.all(color: context.palette.borderSubtle),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: context.text.caption),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppFonts.monoFamily,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 15),
            tooltip: context.l10n.mcpCopyAddress,
            onPressed: () => _copy(context, value),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Agent Selector Chip
// ────────────────────────────────────────────────────────────────────────────

class _AgentSelectorChip extends StatelessWidget {
  const _AgentSelectorChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.palette.primarySoft : context.palette.bgSurface,
      borderRadius: AppRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected
                  ? context.palette.primary
                  : context.palette.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: context.text.label.copyWith(
              color: selected
                  ? context.palette.primary
                  : context.palette.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Code Snippet Card
// ────────────────────────────────────────────────────────────────────────────

class _CodeSnippetCard extends StatelessWidget {
  const _CodeSnippetCard({
    required this.headerTitle,
    required this.code,
  });

  final String headerTitle;
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
          // Snippet topbar
          Container(
            color: context.palette.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.palette.statusError,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.palette.statusWarning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.palette.statusSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headerTitle,
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
                TextButton.icon(
                  onPressed: () => _copy(context, code),
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  label: Text(context.l10n.mcpGuideCopy),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.palette.borderSubtle),
          // Snippet content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              code,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 12,
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

// ────────────────────────────────────────────────────────────────────────────
// Tools section (Daftar tool dengan cards modern)
// ────────────────────────────────────────────────────────────────────────────

class _ToolsSection extends StatelessWidget {
  const _ToolsSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final descriptions = _toolDescriptions(l10n);
    final tools = McpServer.toolSchemas();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 80,
          ),
          itemBuilder: (context, index) {
            final schema = tools[index];
            final name = schema['name'] as String;
            final desc = descriptions[name] ?? '';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.bgSunken,
                borderRadius: AppRadius.sm,
                border: Border.all(color: context.palette.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 14,
                        color: context.palette.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: AppFonts.monoFamily,
                            fontFamilyFallback: AppFonts.monoFallback,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.palette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.uiSmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, String> _toolDescriptions(AppLocalizations l10n) => {
        'list_sessions': l10n.mcpToolListSessions,
        'get_session': l10n.mcpToolGetSession,
        'get_page_html': l10n.mcpToolGetPageHtml,
        'write_page': l10n.mcpToolWritePage,
        'delete_page': l10n.mcpToolDeletePage,
        'post_to_chat': l10n.mcpToolPostToChat,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Troubleshooting Card
// ────────────────────────────────────────────────────────────────────────────

class _TroubleshootingCard extends StatelessWidget {
  const _TroubleshootingCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: context.palette.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.mcpGuideTipTitle,
                  style: context.text.panelTitle.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TipItem(text: l10n.mcpGuideTipAppClosed),
          _TipItem(text: l10n.mcpGuideTipPort),
          _TipItem(text: l10n.mcpGuideTipLocal),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, end: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: context.palette.primary,
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

// ────────────────────────────────────────────────────────────────────────────
// Helpers & Models
// ────────────────────────────────────────────────────────────────────────────

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

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showAppToast(
    context,
    context.l10n.mcpGuideCopied,
    kind: AppToastKind.success,
  );
}
