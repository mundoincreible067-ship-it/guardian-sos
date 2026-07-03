import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fondo compartido: degradado morado-índigo + resplandores que laten +
/// partículas flotando hacia arriba. Usado en todas las pantallas para
/// mantener la identidad visual consistente.
class NeonBackground extends StatefulWidget {
  final Widget child;
  const NeonBackground({super.key, required this.child});

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground> with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    final rnd = Random(7);
    _particles = List.generate(4, (i) => _Particle(
          left: rnd.nextDouble(),
          delaySeconds: i * 1.1,
          controller: AnimationController(vsync: this, duration: const Duration(seconds: 6))
            ..repeat(),
        ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(gradient: AppColors.appBackground)),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final t = _glowController.value;
            return Opacity(
              opacity: 0.4 + t * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.6),
                    radius: 1.1,
                    colors: [AppColors.primaryPurple.withOpacity(0.35), Colors.transparent],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final t = 1 - _glowController.value;
            return Opacity(
              opacity: 0.3 + t * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, -0.8),
                    radius: 1.0,
                    colors: [AppColors.accentPink.withOpacity(0.3), Colors.transparent],
                  ),
                ),
              ),
            );
          },
        ),
        ..._particles.map((p) => _ParticleDot(particle: p)),
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double left;
  final double delaySeconds;
  final AnimationController controller;
  _Particle({required this.left, required this.delaySeconds, required this.controller});
}

class _ParticleDot extends StatelessWidget {
  final _Particle particle;
  const _ParticleDot({required this.particle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return AnimatedBuilder(
        animation: particle.controller,
        builder: (context, child) {
          final t = particle.controller.value;
          final y = constraints.maxHeight * (1 - t);
          final opacity = (sin(t * pi)).clamp(0.0, 1.0);
          return Positioned(
            left: constraints.maxWidth * particle.left,
            top: y,
            child: Opacity(
              opacity: opacity * 0.6,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
            ),
          );
        },
      );
    });
  }
}
