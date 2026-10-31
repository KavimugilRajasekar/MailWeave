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

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  // ── Light-blue / grey palette ──────────────────────────────────────────────
  static const Color _lightBlue = Color(0xFF4A9FE3);
  static const Color _greyDark = Color(0xFF37474F);
  static const Color _greyMid = Color(0xFF607D8B);
  static const Color _greyDarkSoft = Color(0xFF455A64);
  static const Color _greyAccent = Color(0xFF3F525B); // between _greyDarkSoft & _greyDark
  static const Color _greyLight = Color(0xFFECEFF1);

  late List<ContentConfig> _slides;
  bool _isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _slides = [
      // ── Slide 1 : Welcome ───────────────────────────────────────────────────
      ContentConfig(
        widgetTitle: _welcomeTitle(),
        widgetDescription: _welcomeDescription(),
        centerWidget: _animation(),
        colorBegin: _lightBlue,
        colorEnd: _greyLight,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd: Alignment.bottomRight,
      ),
    ];

    // Trace the circular border from the top, all the way around, over ~4 s.
    // Once the outline completes the inner arrow is revealed & made tappable.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isLoading = false);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  /// Forward-arrow call-to-action — a circular outline that traces from the
  /// top all the way around (~4 s). The inner arrow stays hidden while the
  /// outline draws, then fades in and becomes tappable once it completes.
  Widget _getStartedButton() => SizedBox(
    width: 57,
    height: 57,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Tracing border → a full circle once the controller completes.
            SizedBox(
              width: 57,
              height: 57,
              child: CircularProgressIndicator(
                value: _controller.value,
                color: _lightBlue,
                strokeWidth: 2,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
              ),
            ),
            // Arrow icon — invisible while the border traces, fades in once
            // done. IgnorePointer keeps it non-interactive until then.
            AnimatedOpacity(
              opacity: _isLoading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 350),
              child: IgnorePointer(
                ignoring: _isLoading,
                child: IconButton(
                  onPressed: _onDone,
                  padding: EdgeInsets.zero,
                  splashRadius: 26,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: _lightBlue,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
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

  /// Welcome-slide description → Comfortaa (rounded, readable). The word
  /// "untangled" is emphasized in a tone darker than the "Welcome to" kicker
  /// but lighter than the "Mail Weave" wordmark.
  Widget _welcomeDescription() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Comfortaa',
          fontWeight: FontWeight.w300,
          fontSize: 15,
          color: _greyMid,
          height: 1.7,
        ),
        children: const [
          TextSpan(text: 'Your inbox, beautifully '),
          TextSpan(
            text: 'Untangled',
            style: TextStyle(color: _greyAccent),
          ),
          TextSpan(
            text:
                '.\n'
                'MailWeave brings all your mail into one clean, connected view.',
          ),
        ],
      ),
      textAlign: TextAlign.center,
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
