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
  static const Color _lightBlue = Color(0xFF4A9FE3);
  static const Color _greyDark = Color(0xFF37474F);
  static const Color _greyMid = Color(0xFF607D8B);
  static const Color _greyDarkSoft = Color(0xFF455A64);
  static const Color _greyLight = Color(0xFFECEFF1);
  static const Color _white = Colors.white;

  late List<ContentConfig> _slides;

  @override
  void initState() {
    super.initState();
    _slides = [
      // ── Slide 1 : Welcome ───────────────────────────────────────────────────
      ContentConfig(
        widgetTitle: _welcomeTitle(),
        widgetDescription: _body(
          'Your inbox, beautifully untangled.\n'
          'MailWeave brings all your mail into one clean, connected view.',
        ),
        centerWidget: _animation(),
        colorBegin: _lightBlue,
        colorEnd: _greyLight,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd: Alignment.bottomRight,
      ),
    ];
  }

  // ── Visual helpers ────────────────────────────────────────────────────────

  /// Animated mail illustration shown at the centre of the welcome slide.
  Widget _animation() => Lottie.asset(
    'assets/json/contact.json',
    width: 220,
    height: 220,
    fit: BoxFit.contain,
    repeat: true,
    animate: true,
  );

  /// Forward-arrow call-to-action — an outlined circle (no fill).
  Widget _getStartedButton() => TextButton(
    onPressed: _onDone,
    style: _btnStyle().copyWith(
      shape: WidgetStateProperty.all(const CircleBorder()),
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.all(
        const BorderSide(color: _lightBlue, width: 2),
      ),
      overlayColor: WidgetStateProperty.all(
        _lightBlue.withValues(alpha: 0.12),
      ),
      padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
    ),
    child: const Icon(Icons.arrow_forward_rounded, color: _lightBlue, size: 28),
  );

  /// Two-line brand title: a small "Welcome to" kicker above the larger
  /// "Mail Weave" wordmark.
  Widget _welcomeTitle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome to',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Playwrite US Modern',
            fontWeight: FontWeight.w300,
            fontSize: 16,
            color: _greyDarkSoft,
            letterSpacing: 2,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mail Weave',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Playwrite US Modern',
            fontWeight: FontWeight.w400,
            fontSize: 34,
            color: _greyDark,
            height: 1.2,
          ),
        ),
      ],
    ),
  );

  /// Body / description → Comfortaa (rounded, readable).
  Widget _body(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Comfortaa',
        fontWeight: FontWeight.w300,
        fontSize: 15,
        color: _greyMid,
        height: 1.7,
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

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _onDone() async {
    await _markIntroSeen();
    _goLogin();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IntroSlider(
          listContentConfig: _slides,

          // Single slide → no skip / next / done buttons; the CTA is overlaid
          // at the bottom of the screen instead.
          isShowSkipBtn: false,
          isShowNextBtn: false,
          isShowDoneBtn: false,

          // A lone indicator dot isn't useful with a single slide.
          indicatorConfig: const IndicatorConfig(isShowIndicator: false),

          // Navigation bar (transparent, reserves bottom space for the CTA).
          navigationBarConfig: NavigationBarConfig(
            navPosition: NavPosition.bottom,
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 64,
              top: 8,
            ),
          ),

          curveScroll: Curves.easeInOut,
          scrollPhysics: const BouncingScrollPhysics(),
        ),

        // Forward-arrow CTA pinned to the bottom, horizontally centered.
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 28,
          child: Center(child: _getStartedButton()),
        ),
      ],
    );
  }
}
