import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme.dart';
import '../providers/provider_config_provider.dart';

/// Status provider aktif di sidebar Explorer (gaya list item VS Code).
class ProviderStatusCard extends ConsumerWidget {
  const ProviderStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(providerConfigProvider);
    final active = asyncState.value?.activeProvider;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideBarListItem(
            leading: Icon(
              Icons.cloud_outlined,
              size: 14,
              color: active == null
                  ? AppColors.textDisabled
                  : AppColors.statusSuccess,
            ),
            title: active?.name ?? 'No active provider',
            subtitle: active?.model ?? 'Configure a BYOK provider',
            trailing: const Icon(Icons.settings_outlined, size: 14),
            onTap: () => context.push('/provider-config'),
          ),
        ],
      ),
    );
  }
}

class _SideBarListItem extends StatefulWidget {
  const _SideBarListItem({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<_SideBarListItem> createState() => _SideBarListItemState();
}

class _SideBarListItemState extends State<_SideBarListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _hovered ? AppColors.hoverBg : Colors.transparent,
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.uiSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.monoSmall,
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
