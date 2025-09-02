import 'package:flutter/material.dart';

class MessXLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const MessXLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: MessXLogoPainter(color: color ?? Colors.purple),
    );
  }
}

class MessXLogoPainter extends CustomPainter {
  final Color color;

  MessXLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw outer circle with gradient effect
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.3),
      ],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, gradientPaint);

    // Draw stylized "M" and "X" 
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size.width * 0.35,
      fontWeight: FontWeight.bold,
      letterSpacing: -2,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: 'MX', style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);

    // Add decorative elements - chat bubble indicators
    final bubbleRadius = size.width * 0.08;
    
    // Top right bubble
    canvas.drawCircle(
      Offset(center.dx + radius * 0.6, center.dy - radius * 0.6),
      bubbleRadius,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // Bottom left bubble
    canvas.drawCircle(
      Offset(center.dx - radius * 0.6, center.dy + radius * 0.6),
      bubbleRadius * 0.7,
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    // Add subtle border
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
