import 'dart:async';

import 'package:flutter/material.dart';
import 'web_ad_banner.dart';

/// Shows an ad with a short countdown. Resolves once the user continues.
Future<void> showWebAdGate(BuildContext context, {int seconds = 5}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WebAdGateDialog(seconds: seconds),
  );
}

class _WebAdGateDialog extends StatefulWidget {
  const _WebAdGateDialog({required this.seconds});

  final int seconds;

  @override
  State<_WebAdGateDialog> createState() => _WebAdGateDialogState();
}

class _WebAdGateDialogState extends State<_WebAdGateDialog> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _remaining <= 0;
    return AlertDialog(
      backgroundColor: const Color(0xFF171B21),
      title: const Text('Sponsored', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WebAdBanner(height: 250),
            const SizedBox(height: 12),
            Text(
              ready
                  ? 'Thanks for supporting the free calculator!'
                  : 'Your PDF will be ready in $_remaining s…',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981)),
          onPressed: ready ? () => Navigator.pop(context) : null,
          child: const Text('Continue to PDF',
              style: TextStyle(color: Color(0xFF003822))),
        ),
      ],
    );
  }
}
