import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // ── Light-blue / grey palette ──────────────────────────────────────────────
  static const Color _lightBlue     = Color(0xFF4A9FE3);
  static const Color _lightBlueSoft = Color(0xFF8FC2EE);
  static const Color _greyDark      = Color(0xFF37474F);
  static const Color _greyMid       = Color(0xFF607D8B);
  static const Color _greyLight     = Color(0xFFECEFF1);
  static const Color _white         = Colors.white;

  late List<ContentConfig> _slides;

  @override
  void initState() {
    super.initState();
    _slides = [
      // ── Slide 1 : Welcome ───────────────────────────────────────────────────
      ContentConfig(
        widgetTitle:       _title('Welcome to\nMailWeave'),
        widgetDescription: _body(
          'Your inbox, beautifully untangled.\n'
          'MailWeave brings all your mail into one clean, connected view.',
        ),
        centerWidget: _balloon(),
        colorBegin: _lightBlue,
        colorEnd:   _greyLight,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd:   Alignment.bottomRight,
      ),

      // ── Slide 2 : Thread tree ──────────────────────────────────────────────
      ContentConfig(
        widgetTitle:       _title('Threaded Tree View'),
        widgetDescription: _body(
          'Every reply branches out naturally.\n'
          'Follow the full conversation at a glance — like a tree of ideas.',
        ),
        centerWidget: _balloon(),
        colorBegin: _greyLight,
        colorEnd:   _lightBlueSoft,
        directionColorBegin: Alignment.topRight,
        directionColorEnd:   Alignment.bottomLeft,
      ),

      // ── Slide 3 : Get started ──────────────────────────────────────────────
      ContentConfig(
        widgetTitle:       _title('Stay in the Loop'),
        widgetDescription: _body(
          'Connect your account and let MailWeave weave your\n'
          'conversations into clarity. Let\'s get started!',
        ),
        centerWidget: _balloon(),
        colorBegin: _lightBlueSoft,
        colorEnd:   _lightBlue,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd:   Alignment.bottomRight,
      ),
    ];
  }

  // ── Visual helpers ────────────────────────────────────────────────────────

  Widget _balloon() => Lottie.asset(
        'assets/json/man_in_ballon.json',
        width:   220,
        height:  220,
        fit:     BoxFit.contain,
        repeat:  true,
        animate: true,
      );

  /// Headings → Playwrite US Modern (handwriting accent).
  Widget _title(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily:  'Playwrite US Modern',
            fontWeight:  FontWeight.w400,
            fontSize:    26,
            color:       _greyDark,
            height:      1.5,
          ),
        ),
      );

  /// Body / description → Comfortaa (rounded, readable).
  Widget _body(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily:  'Comfortaa',
            fontWeight:  FontWeight.w300,
            fontSize:    15,
            color:       _greyMid,
            height:      1.7,
          ),
        ),
      );

  // ── Button helpers ─────────────────────────────────────────────────────────

  ButtonStyle _btnStyle() => ButtonStyle(
        shape: WidgetStateProperty.all(const StadiumBorder()),
        backgroundColor: WidgetStateProperty.all(_lightBlue),
        foregroundColor: WidgetStateProperty.all(_white),
        overlayColor: WidgetStateProperty.all(_lightBlue.withValues(alpha: 0.8)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        ),
      );

  Widget _btnLabel(String text, {bool bold = false}) => Text(
        text,
        style: TextStyle(
          fontFamily:   'Comfortaa',
          fontWeight:   bold ? FontWeight.w700 : FontWeight.w400,
          fontSize:     14,
          color:        _white,
          letterSpacing: 0.5,
        ),
      );

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onDone() async {
    await _markIntroSeen();
    _goLogin();
  }

  void _onSkip() async {
    await _markIntroSeen();
    _goLogin();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: _slides,

      // Next button
      renderNextBtn:  _btnLabel('NEXT', bold: true),
      nextButtonStyle: _btnStyle(),

      // Skip button
      renderSkipBtn:  _btnLabel('SKIP'),
      skipButtonStyle: _btnStyle(),
      onSkipPress:    _onSkip,

      // Done button
      renderDoneBtn:   _btnLabel("LET'S GO", bold: true),
      doneButtonStyle: _btnStyle(),
      onDonePress:     _onDone,

      // Indicator
      indicatorConfig: IndicatorConfig(
        sizeIndicator:          10,
        spaceBetweenIndicator:  8,
        colorIndicator:         _greyLight,
        colorActiveIndicator:   _lightBlue,
        typeIndicatorAnimation: TypeIndicatorAnimation.sliding,
      ),

      // Navigation bar
      navigationBarConfig: NavigationBarConfig(
        navPosition:     NavPosition.bottom,
        backgroundColor:  Colors.transparent,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top:    8,
        ),
      ),

      curveScroll:   Curves.easeInOut,
      scrollPhysics: const BouncingScrollPhysics(),
    );
  }
}
