import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // ── Brand colours ────────────────────────────────────────────────────────
  static const Color _navy  = Color(0xFF1A3A5C);
  static const Color _blue  = Color(0xFF2E6DA4);
  static const Color _teal  = Color(0xFF1A7F8E);
  static const Color _green = Color(0xFF2E9E5B);
  static const Color _white = Color(0xFFFFFFFF);

  late List<ContentConfig> _slides;

  @override
  void initState() {
    super.initState();
    _slides = [
      // ── Slide 1 : Welcome ───────────────────────────────────────────────
      ContentConfig(
        widgetTitle:       _title('Welcome to\nMailWeave'),
        widgetDescription: _body(
          'Your inbox, beautifully untangled.\n'
          'MailWeave brings all your mail into one clean, connected view.',
        ),
        centerWidget: _icon(Icons.mail_outline_rounded),
        colorBegin: _navy,
        colorEnd:   _blue,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd:   Alignment.bottomRight,
      ),

      // ── Slide 2 : Thread tree ────────────────────────────────────────────
      ContentConfig(
        widgetTitle:       _title('Threaded Tree View'),
        widgetDescription: _body(
          'Every reply branches out naturally.\n'
          'Follow the full conversation at a glance — like a tree of ideas.',
        ),
        centerWidget: _ThreadTreeWidget(),
        colorBegin: _blue,
        colorEnd:   _teal,
        directionColorBegin: Alignment.topRight,
        directionColorEnd:   Alignment.bottomLeft,
      ),

      // ── Slide 3 : Get started ────────────────────────────────────────────
      ContentConfig(
        widgetTitle:       _title('Stay in the Loop'),
        widgetDescription: _body(
          'Connect your account and let MailWeave weave your\n'
          'conversations into clarity. Let\'s get started!',
        ),
        centerWidget: _icon(Icons.account_tree_rounded),
        colorBegin: _teal,
        colorEnd:   _green,
        directionColorBegin: Alignment.topLeft,
        directionColorEnd:   Alignment.bottomRight,
      ),
    ];
  }

  // ── Font helpers ─────────────────────────────────────────────────────────

  /// Headings / slide titles  →  Playwrite US Modern (handwriting accent)
  Widget _title(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Playwrite US Modern',
            fontWeight: FontWeight.w400, // Regular weight for script feel
            fontSize:   26,
            color:      _white,
            height:     1.5,
          ),
        ),
      );

  /// Body / description copy  →  Comfortaa (rounded, readable)
  Widget _body(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Comfortaa',
            fontWeight: FontWeight.w300,
            fontSize:   15,
            color:      _white,
            height:     1.7,
          ),
        ),
      );

  Widget _icon(IconData icon) => Icon(
        icon,
        size:  120,
        color: _white.withValues(alpha: 0.9),
      );

  // ── Button helpers ───────────────────────────────────────────────────────

  ButtonStyle _btnStyle() => ButtonStyle(
        shape: WidgetStateProperty.all(const StadiumBorder()),
        backgroundColor:
            WidgetStateProperty.all(_white.withValues(alpha: 0.20)),
        foregroundColor: WidgetStateProperty.all(_white),
        overlayColor:
            WidgetStateProperty.all(_white.withValues(alpha: 0.10)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      );

  // Button labels also use Comfortaa (they are UI controls, not headings)
  Widget _btnLabel(String text, {bool bold = false}) => Text(
        text,
        style: TextStyle(
          fontFamily:  'Comfortaa',
          fontWeight:  bold ? FontWeight.w700 : FontWeight.w400,
          fontSize:    14,
          color:       _white,
          letterSpacing: 0.5,
        ),
      );

  // ── Shared-prefs: mark intro as seen ────────────────────────────────────

  Future<void> _markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _onDone() async {
    await _markIntroSeen();
    _goHome();
  }

  void _onSkip() async {
    await _markIntroSeen();
    _goHome();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: _slides,

      // Next button
      renderNextBtn: _btnLabel('NEXT', bold: true),
      nextButtonStyle: _btnStyle(),

      // Skip button — also marks intro seen so back-press can't re-show it
      renderSkipBtn: _btnLabel('SKIP'),
      skipButtonStyle: _btnStyle(),
      onSkipPress: _onSkip,

      // Done button
      renderDoneBtn: _btnLabel("LET'S GO", bold: true),
      doneButtonStyle: _btnStyle(),
      onDonePress: _onDone,

      // Indicator
      indicatorConfig: IndicatorConfig(
        sizeIndicator:          10,
        spaceBetweenIndicator:  8,
        colorIndicator:         _white.withValues(alpha: 0.35),
        colorActiveIndicator:   _white,
        typeIndicatorAnimation: TypeIndicatorAnimation.sliding,
      ),

      // Navigation bar
      navigationBarConfig: NavigationBarConfig(
        navPosition:     NavPosition.bottom,
        backgroundColor: Colors.transparent,
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

// ── Custom painter : branching thread tree ───────────────────────────────────

class _ThreadTreeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        width:  180,
        height: 180,
        child:  CustomPaint(painter: _TreePainter()),
      );
}

class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color      = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 6
      ..strokeCap  = StrokeCap.round
      ..style      = PaintingStyle.stroke;

    final cx = size.width / 2;

    // Trunk
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height * 0.45), linePaint);

    // Left branch
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(size.width * 0.15, size.height * 0.75),
      linePaint,
    );
    // Centre branch
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(cx, size.height * 0.85),
      linePaint,
    );
    // Right branch
    canvas.drawLine(
      Offset(cx, size.height * 0.45),
      Offset(size.width * 0.85, size.height * 0.75),
      linePaint,
    );

    // Leaf dots
    final dot = Paint()..style = PaintingStyle.fill;

    dot.color = const Color(0xFF2E9E5B); // green
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 10, dot);

    dot.color = const Color(0xFF2E6DA4); // blue
    canvas.drawCircle(Offset(cx, size.height * 0.88), 10, dot);

    dot.color = const Color(0xFFCC4444); // red
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.75), 10, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
