import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Logo "GuardiaN" animado: el ícono late y rota suavemente, el círculo
/// cambia de color en degradado, y el texto tiene un brillo que se
/// desliza — el elemento de marca distintivo de la app.
class GuardianLogo extends StatefulWidget {
  final double size;
  const GuardianLogo({super.key, this.size = 1.0});

  @override
  State<GuardianLogo> createState() => _GuardianLogoState();
}

class _GuardianLogoState extends State<GuardianLogo> with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 34.0 * widget.size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_bounceController, _glowController]),
          builder: (context, child) {
            final b = _bounceController.value;
            final scale = 1.0 + (b < 0.5 ? b : 1 - b) * 0.24;
            final rotation = (b < 0.25 ? -b : (b < 0.75 ? b - 0.5 : 1 - b)) * 0.35;
            final glowColor = Color.lerp(AppColors.accentCyan, AppColors.accentPink, _glowController.value)!;
            return Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconSize * 0.3),
                gradient: AppColors.logoGradient,
                boxShadow: [BoxShadow(color: glowColor.withOpacity(0.7), blurRadius: 16, spreadRadius: 1)],
              ),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Icon(Icons.shield_rounded, color: Colors.white, size: iconSize * 0.56),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 10 * widget.size),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                final t = _glowController.value;
                return LinearGradient(
                  begin: Alignment(-1 + t * 2, 0),
                  end: Alignment(1 + t * 2, 0),
                  colors: const [Colors.white, AppColors.accentCyan, AppColors.accentPink, Colors.white],
                ).createShader(bounds);
              },
              child: Text(
                'GuardiaN',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22 * widget.size,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
