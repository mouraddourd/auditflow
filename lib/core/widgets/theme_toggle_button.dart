import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/theme_provider.dart';

/// Bouton global de changement de thème avec animation fluide
/// Peut être utilisé comme bouton flottant ou dans une AppBar
class ThemeToggleButton extends StatefulWidget {
  final bool isFloating;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const ThemeToggleButton({
    super.key,
    this.isFloating = false,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    debugPrint('🎨 ThemeToggleButton: _toggleTheme called');
    _controller.forward(from: 0).then((_) {
      _controller.reset();
    });
    final provider = context.read<ThemeProvider>();
    debugPrint('🎨 Current isDarkMode: ${provider.isDarkMode}');
    provider.toggleTheme();
    debugPrint('🎨 After toggle isDarkMode: ${provider.isDarkMode}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleTheme,
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 6.28, // Full rotation
                child: child,
              ),
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.backgroundColor ??
                  (isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Icon(
                isDark ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
                key: ValueKey(isDark),
                size: widget.size * 0.5,
                color: widget.iconColor ??
                    (isDark
                        ? const Color(0xFFFFB300) // Amber for sun
                        : const Color(0xFF5C6BC0)), // Indigo for moon
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton compact pour AppBar
class ThemeAppBarAction extends StatelessWidget {
  const ThemeAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: ThemeToggleButton(size: 36),
    );
  }
}

/// Bouton flottant global positionné
class GlobalThemeFAB extends StatelessWidget {
  final Offset offset;
  final double size;

  const GlobalThemeFAB({
    super.key,
    this.offset = const Offset(16, 16),
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      right: offset.dx,
      child: SafeArea(
        child: ThemeToggleButton(
          isFloating: true,
          size: size,
        ),
      ),
    );
  }
}
