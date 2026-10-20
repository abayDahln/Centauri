import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../data/mcp_bridge.dart';
import '../data/mcp_server.dart';

/// Status + info koneksi MCP server lokal (Fase 4: Desktop Full).
/// Ditampilkan di halaman konfigurasi provider agar agent eksternal
/// (Claude Code, Cursor) tahu cara terhubung.
class McpStatusSection extends ConsumerStatefulWidget {
  const McpStatusSection({super.key});

  @override
  ConsumerState<McpStatusSection> createState() => _McpStatusSectionState();
}

class _McpStatusSectionState extends ConsumerState<McpStatusSection> {
  bool _starting = false;

  static bool get _supported =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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
    if (!_supported) {
      return _McpCard(
        children: [
          Text(
            l10n.mcpDesktopTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mcpDesktopOnlyDesc,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    final server = ref.watch(mcpServerProvider);
    final running = server.isRunning;
    final endpoint = server.endpoint;

    return _McpCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.mcpDesktopTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            StatusPill(
              label: running ? l10n.mcpRunning : l10n.mcpStopped,
              color: running
                  ? context.palette.statusSuccess
                  : context.palette.textDisabled,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.mcpDescription,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (running && endpoint != null) ...[
          const SizedBox(height: 12),
          _EndpointRow(label: 'JSON-RPC', value: endpoint),
          const SizedBox(height: 6),
          _EndpointRow(
            label: 'SSE',
            value: endpoint.replaceFirst('/mcp', '/events'),
          ),
          const SizedBox(height: 6),
          _EndpointRow(
            label: 'Status',
            value: endpoint.replaceFirst('/mcp', '/status'),
          ),
          const SizedBox(height: 8),
          Text(
            'Tools: get_canvas_structure, get_selected_node, get_node_html, '
            'add_node, update_node, delete_node, rearrange_layout.',
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 11,
              height: 1.6,
              color: context.palette.textSecondary,
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _starting ? null : _start,
              child: Text(_starting ? l10n.mcpStarting : l10n.mcpStart),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mcpAutoStartNote,
            style: TextStyle(fontSize: 12, color: context.palette.textDisabled),
          ),
        ],
      ],
    );
  }
}

class _McpCard extends StatelessWidget {
  const _McpCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border.all(color: context.palette.borderSubtle),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label, style: context.text.caption)),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.mcpAddressCopied),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          },
        ),
      ],
    );
  }
}
