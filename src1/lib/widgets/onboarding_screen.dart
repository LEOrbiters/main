// lib/widgets/onboarding_screen.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _viewType = 'onboarding-iframe';
  static bool _registered = false;
  html.EventListener? _listener;

  @override
  void initState() {
    super.initState();

    if (kIsWeb && !_registered) {
      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '/onboarding.html' // ✅ 상대경로
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
      _registered = true;
    }

    _listener = (event) {
      try {
        final e = event as html.MessageEvent;
        if (e.data is Map && e.data['type'] == 'onboarding:done') {
          html.window.localStorage['onboarding_done'] = '1';
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/'); // ✅ 지도 화면으로
          }
        }
      } catch (_) {}
    };
    html.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    if (_listener != null) {
      html.window.removeEventListener('message', _listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
