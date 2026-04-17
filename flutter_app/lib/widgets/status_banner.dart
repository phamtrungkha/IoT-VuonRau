import 'package:flutter/material.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

class StatusBanner extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool? mqttConnected;
  final bool deviceStale;
  final String lastStateAgeLabel;
  final String baseUrl;
  final VoidCallback? onRetry;

  const StatusBanner({
    super.key,
    required this.loading,
    required this.error,
    required this.mqttConnected,
    required this.deviceStale,
    required this.lastStateAgeLabel,
    required this.baseUrl,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Priority: app-level error (Backend unreachable) > MQTT disconnected > device stale > ok
    String title;
    String subtitle;
    Color bg;
    Color fg;

    if (error != null) {
      title = l10n.statusCannotReachBackendTitle;
      subtitle = l10n.statusCannotReachBackendSubtitle(baseUrl, error!);
      bg = Colors.red.shade50;
      fg = Colors.red.shade900;
    } else if (mqttConnected == false) {
      title = l10n.statusBackendCannotReachMqttTitle;
      subtitle = l10n.statusBackendCannotReachMqttSubtitle(baseUrl);
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    } else if (deviceStale) {
      title = l10n.statusDeviceNotReportingTitle;
      subtitle = l10n.statusDeviceNotReportingSubtitle(baseUrl, lastStateAgeLabel);
      bg = Colors.amber.shade50;
      fg = Colors.brown.shade900;
    } else {
      title = l10n.statusAllSystemsOkTitle;
      subtitle = l10n.statusAllSystemsOkSubtitle(baseUrl);
      bg = Colors.green.shade50;
      fg = Colors.green.shade900;
    }

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: fg)),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  loading ? '...' : l10n.retryButton,
                  style: TextStyle(color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

