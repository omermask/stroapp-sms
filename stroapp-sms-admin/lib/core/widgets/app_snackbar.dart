import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../localization/app_localizations.dart';

enum SnackType { success, error, info }

void showAppSnack(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
}) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  final colors = switch (type) {
    SnackType.success => (
      bg: const Color(0xFF16A34A),
      icon: QasehIcons.tickSquareFilled,
    ),
    SnackType.error => (
      bg: const Color(0xFFDC2626),
      icon: QasehIcons.dangerTriangleCurved,
    ),
    SnackType.info => (
      bg: const Color(0xFF2563EB),
      icon: QasehIcons.infoSquareFilled,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(colors.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: colors.bg,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, isRtl ? 80 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
}

void showSuccessSnack(BuildContext context, String key) {
  final t = AppLocalizations.of(context)!.t;
  showAppSnack(context, t(key), type: SnackType.success);
}

void showErrorSnack(BuildContext context, String key) {
  final t = AppLocalizations.of(context)!.t;
  showAppSnack(context, t(key), type: SnackType.error);
}

void showServerErrorSnack(BuildContext context) {
  final t = AppLocalizations.of(context)!.t;
  showAppSnack(context, t('serverError'), type: SnackType.error);
}
