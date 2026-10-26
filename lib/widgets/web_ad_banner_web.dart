import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

// Build with: --dart-define=ADSENSE_CLIENT=ca-pub-XXXXXXXXXXXXXXXX --dart-define=ADSENSE_SLOT=1234567890
const String _client = String.fromEnvironment('ADSENSE_CLIENT', defaultValue: 'ca-pub-3744400504443798');
const String _slot = String.fromEnvironment('ADSENSE_SLOT', defaultValue: '9954398051');
// In-feed unit: fill in after creating it in AdSense (hidden while empty).
const String _inFeedSlot = String.fromEnvironment('ADSENSE_INFEED_SLOT', defaultValue: '7299248893');
const String _inFeedLayoutKey = String.fromEnvironment('ADSENSE_INFEED_LAYOUT_KEY', defaultValue: '-6t+ed+2i-1n-4w');

bool _registered = false;

@JS('eval')
external JSAny? _eval(String code);

void _pushAd() {
  Future.delayed(const Duration(milliseconds: 300), () {
    try {
      _eval('(window.adsbygoogle = window.adsbygoogle || []).push({})');
    } catch (_) {}
  });
}

void _ensureRegistered() {
  if (_registered) return;
  _registered = true;

  if (web.document.querySelector('script[src*="adsbygoogle.js"]') == null) {
    final script = web.document.createElement('script') as web.HTMLScriptElement
      ..id = 'adsense-script'
      ..async = true
      ..crossOrigin = 'anonymous'
      ..src =
          'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$_client';
    web.document.head!.appendChild(script);
  }

  ui_web.platformViewRegistry.registerViewFactory('adsense-banner', (int id) {
    final ins = web.document.createElement('ins') as web.HTMLElement
      ..className = 'adsbygoogle'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('data-ad-client', _client)
      ..setAttribute('data-ad-slot', _slot)
      ..setAttribute('data-ad-format', 'auto')
      ..setAttribute('data-full-width-responsive', 'true');

    final container = web.document.createElement('div') as web.HTMLElement
      ..style.width = '100%'
      ..style.height = '100%'
      ..appendChild(ins);

    // Push after the element is attached to the DOM.
    _pushAd();
    return container;
  });

  ui_web.platformViewRegistry.registerViewFactory('adsense-infeed', (int id) {
    final ins = web.document.createElement('ins') as web.HTMLElement
      ..className = 'adsbygoogle'
      ..style.display = 'block'
      ..setAttribute('data-ad-client', _client)
      ..setAttribute('data-ad-slot', _inFeedSlot)
      ..setAttribute('data-ad-format', 'fluid')
      ..setAttribute('data-ad-layout-key', _inFeedLayoutKey);

    final container = web.document.createElement('div') as web.HTMLElement
      ..style.width = '100%'
      ..style.height = '100%'
      ..appendChild(ins);
    _pushAd();
    return container;
  });
}

class WebInFeedAd extends StatelessWidget {
  const WebInFeedAd({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    if (_client.isEmpty || _inFeedSlot.isEmpty || _inFeedLayoutKey.isEmpty) {
      return const SizedBox.shrink();
    }
    _ensureRegistered();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const HtmlElementView(viewType: 'adsense-infeed'),
    );
  }
}

class WebAdBanner extends StatelessWidget {
  const WebAdBanner({super.key, this.height = 90});

  final double height;

  @override
  Widget build(BuildContext context) {
    if (_client.isEmpty || _slot.isEmpty) return const SizedBox.shrink();
    _ensureRegistered();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const HtmlElementView(viewType: 'adsense-banner'),
    );
  }
}
