import 'package:flutter/material.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

class EzvizPtzPad extends StatelessWidget {
  final VoidCallback onUpStart;
  final VoidCallback onUpStop;
  final VoidCallback onDownStart;
  final VoidCallback onDownStop;
  final VoidCallback onLeftStart;
  final VoidCallback onLeftStop;
  final VoidCallback onRightStart;
  final VoidCallback onRightStop;
  final VoidCallback onStop;

  const EzvizPtzPad({
    super.key,
    required this.onUpStart,
    required this.onUpStop,
    required this.onDownStart,
    required this.onDownStop,
    required this.onLeftStart,
    required this.onLeftStop,
    required this.onRightStart,
    required this.onRightStop,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.black.withAlpha(140),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HoldButton(
              icon: Icons.keyboard_arrow_up,
              onStart: onUpStart,
              onStop: onUpStop,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoldButton(
                  icon: Icons.keyboard_arrow_left,
                  onStart: onLeftStart,
                  onStop: onLeftStop,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.stopTooltip,
                  onPressed: onStop,
                  icon: const Icon(Icons.stop, color: Colors.white),
                ),
                const SizedBox(width: 8),
                _HoldButton(
                  icon: Icons.keyboard_arrow_right,
                  onStart: onRightStart,
                  onStop: onRightStop,
                ),
              ],
            ),
            _HoldButton(
              icon: Icons.keyboard_arrow_down,
              onStart: onDownStart,
              onStop: onDownStop,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _HoldButton({
    required this.icon,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onStart(),
      onTapUp: (_) => onStop(),
      onTapCancel: onStop,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withAlpha(30),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

