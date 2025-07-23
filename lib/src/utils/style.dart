import 'dart:math' as math;
import 'dart:ui';

import 'package:company_app/src/effect/beam.dart';
import 'package:company_app/src/utils/responsive.dart';
import 'package:company_app/src/utils/theme.dart';
import 'package:flutter/material.dart';

class GlassMorphicStyle extends StatefulWidget {
  const GlassMorphicStyle({
    required this.child,
    super.key,
    this.border,
    this.borderColor,
    this.gradientStartColor,
    this.gradientEndColor,
    this.borderRadius,
    this.heightFactor,
    this.blurSigmaX = 6.0,
    this.blurSigmaY = 6.0,
    this.borderWidth = 1.5,
    this.shadowColor,
    this.shadowBlurRadius = 15.0,
    this.shadowSpreadRadius = 1.0,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd = Alignment.bottomCenter,
    this.opacity = 0.2,
    this.beamColors,
    this.animationController,
    this.showBeam = false,
    this.width,
    this.height,

  });
  final Widget child;
  final Border? border;
  final Color? borderColor;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final BorderRadius? borderRadius;
  final double? heightFactor;
  final double blurSigmaX;
  final double blurSigmaY;
  final double borderWidth;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final double opacity;
  final List<Color>? beamColors;
  final AnimationController? animationController;
  final double? width;
  final bool showBeam;
  final double? height;
  @override
  State<GlassMorphicStyle> createState() => _GlassMorphicStyleState();
}

class _GlassMorphicStyleState extends State<GlassMorphicStyle> {
  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(Spacing.baseRadius1);
    final effectiveBorderColor = widget.borderColor ?? AppThemeColors.current.glassBorderColor;
    final effectiveGradientStart =
        (widget.gradientStartColor ?? AppThemeColors.current.glassGradientStart).withValues(alpha: widget.opacity);
    final effectiveGradientEnd =
        (widget.gradientEndColor ?? AppThemeColors.current.glassGradientEnd).withValues(alpha: widget.opacity);
    final effectiveShadowColor = widget.shadowColor ?? Colors.black.withAlpha(26);
    return LayoutBuilder(
      builder: (context, constraints) {
        final glassContainer = ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blurSigmaX, sigmaY: widget.blurSigmaY),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: widget.gradientBegin,
                  end: widget.gradientEnd,
                  colors: [effectiveGradientStart, effectiveGradientEnd],
                ),
                borderRadius: effectiveBorderRadius,
                border: widget.border ??
                    Border.all(
                      color: effectiveBorderColor,
                      width: widget.borderWidth,
                    ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveShadowColor,
                    blurRadius: widget.shadowBlurRadius,
                    spreadRadius: widget.shadowSpreadRadius,
                  ),
                ],
              ),
              child: SizedBox(
                height: widget.heightFactor != null
                    ? math.max(2 * Spacing.baseRadius1, constraints.maxHeight * widget.heightFactor!)
                    : null,
                child: widget.child,
              ),
            ),
          ),
        );
        if (widget.showBeam && widget.animationController != null && widget.beamColors != null) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showBeam)
                Positioned.fill(
                  child: CustomPaint(
                    painter: BeamPainter(
                      animation: widget.animationController!,
                      borderRadius: effectiveBorderRadius,
                      beamColors: widget.beamColors!,
                    ),
                  ),
                ),
              glassContainer,
            ],
          );
        }
        return glassContainer;
      },
    );
  }
}
