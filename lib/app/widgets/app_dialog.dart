import 'package:flutter/material.dart';

import '../config/app_motion.dart';

/// Dialog dengan transisi fade yang konsisten di seluruh aplikasi.
///
/// Memakai [showGeneralDialog] agar tidak ada efek scale bawaan Material;
/// barrier tetap memudar dan tetap bisa ditutup dengan klik di luar dialog.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    transitionDuration: reduceMotion ? Duration.zero : AppMotion.dialog,
    pageBuilder: (dialogContext, _, _) =>
        SafeArea(child: builder(dialogContext)),
    transitionBuilder: (_, animation, _, child) {
      if (reduceMotion) return child;
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: AppMotion.dialogCurve)),
        child: child,
      );
    },
  );
}
