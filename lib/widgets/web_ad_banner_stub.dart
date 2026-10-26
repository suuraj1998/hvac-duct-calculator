import 'package:flutter/widgets.dart';

class WebAdBanner extends StatelessWidget {
  const WebAdBanner({super.key, this.height = 90});

  final double height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class WebInFeedAd extends StatelessWidget {
  const WebInFeedAd({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
