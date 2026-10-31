import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // MailWeave brand colours
  static const Color _navy = Color(0xFF1A3A5C);
  static const Color _blue = Color(0xFF2E6DA4);
  static const Color _teal = Color(0xFF1A7F8E);
  static const Color _green = Color(0xFF2E9E5B);
  static const Color _white = Color(0xFFFFFFFF);

  late List<ContentConfig> _slides;

  @override
  void initState() {
    super.initState();
    _slides = [
      // ── Slide 1 : Welcome ──────────────────────────────────────────────
      ContentConfig(
        widgetTitle: _slideTitle('Welcome to\nMailWeave'),
        widgetDescription: _slideDescription(
          'Your inbox, beautifully untangled.\n'
          'MailWeave brings all your mail into one clean, connected view.',
        ),
        centerWidget: _slideIcon(Icons.mail_outline_rounded, _white),
        colorBegin: _navy,
        colorEnd: _blue,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd: Alignment.bottomRight,
      ),

      // ── Slide 2 : Thread tree ──────────────────────────────────────────
      ContentConfig(
        widgetTitle: _slideTitle('Threaded Tree View'),
        widgetDescription: _slideDescription(
          'Every reply branches out naturally.\n'
          'Follow the full conversation at a glance — like a tree of ideas.',
        ),
        centerWidget: _threadTreeWidget(),
        colorBegin: _blue,
        colorEnd: _teal,
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),

      // ── Slide 3 : Get started ─────────────────────────────────────────
      ContentConfig(
        widgetTitle: _slideTitle('Stay in the Loop'),
        widgetDescription: _slideDescription(
          'Connect your account and let MailWeave weave your conversations\n'
          'into clarity. Let\'s get started!',
        ),
        centerWidget: _slideIcon(Icons.account_tree_rounded, _white),
        colorBegin: _teal,
        colorEnd: _green,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd: Alignment.bottomRight,
      ),
    ];
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _slideTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Comfortaa',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _white,
            height: 1.3,
          ),
        ),
      );

  Widget _slideDescription(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Comfortaa',
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: _white,
            height: 1.6,
          ),
        ),
      );

  Widget _slideIcon(IconData icon, Color color) => Icon(
        icon,
        size: 120,
        color: color.withValues(alpha: 0.9),
      );

  /// Custom widget that mimics the branching thread tree in the app icon.
  Widget _threadTreeWidget() => SizedBox(
        width: 180,
        height: 180,
        child: CustomPaint(painter: _TreePainter()),
      );

  // ── Button helpers ───────────────────────────────────────────────────────

  ButtonStyle _btnStyle() => ButtonStyle(
        shape: WidgetStateProperty.all(const StadiumBorder()),
        backgroundColor:
            WidgetStateProperty.all(_white.withValues(alpha: 0.20)),
        foregroundColor: WidgetStateProperty.all(_white),
        overlayColor: WidgetStateProperty.all(_white.withValues(alpha: 0.10)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      );

  Widget _nextBtn() => const Text(
        'NEXT',
        style: TextStyle(
          fontFamily: 'Comfortaa',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _white,
        ),
      );

  Widget _skipBtn() => const Text(
        'SKIP',
        style: TextStyle(
          fontFamily: 'Comfortaa',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: _white,
        ),
      );

  Widget _doneBtn() => const Text(
        "LET'S GO",
        style: TextStyle(
          fontFamily: 'Comfortaa',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _white,
        ),
      );

  // ── Navigation ───────────────────────────────────────────────────────────

  void _onDone() {
    // TODO: replace with Navigator push to your main home screen once built.
    // For now shows a snackbar so you can see it fires correctly.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Onboarding complete — navigate to Home here."),
        backgroundColor: Color(0xFF1A3A5C),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: _slides,

      // Buttons
      renderNextBtn: _nextBtn(),
      nextButtonStyle: _btnStyle(),
      renderSkipBtn: _skipBtn(),
      skipButtonStyle: _btnStyle(),
      renderDoneBtn: _doneBtn(),
      doneButtonStyle: _btnStyle(),
      onDonePress: _onDone,

      // Indicator
      indicatorConfig: IndicatorConfig(
        sizeIndicator: 10,
        spaceBetweenIndicator: 8,
        colorIndicator: _white.withValues(alpha: 0.35),
        colorActiveIndicator: _white,
        typeIndicatorAnimation: TypeIndicatorAnimation.sliding,
      ),

      // Navigation bar
      navigationBarConfig: NavigationBarConfig(
        navPosition: NavPosition.bottom,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 8,
        ),
      ),

      curveScroll: Curves.easeInOut,
      scrollPhysics: const BouncingScrollPhysics(),
    );
  }
}

// ── Custom painter : branching tree ─────────────────────────────────────────

class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    // Trunk
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height * 0.45), paint);

    // Left branch
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(size.width * 0.15, size.height * 0.75),
      paint,
    );
    // Centre branch
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(cx, size.height * 0.85),
      paint,
    );
    // Right branch
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(size.width * 0.85, size.height * 0.75),
      paint,
    );

    // Leaf dots
    final dotPaint = Paint()..style = PaintingStyle.fill;

    dotPaint.color = const Color(0xFF2E9E5B); // green
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.75), 10, dotPaint);

    dotPaint.color = const Color(0xFF2E6DA4); // blue
    canvas.drawCircle(Offset(cx, size.height * 0.88), 10, dotPaint);

    dotPaint.color = const Color(0xFFCC4444); // red
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.75), 10, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
