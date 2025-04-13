import 'dart:math';
import 'package:flutter/material.dart';

final List<Color> channelColors = [
  Color(0xFF00FF80),
  Color(0xFF00FFA1),
  Color(0xFF00FFC3),
  Color(0xFF00FFEA),
  Color(0xFF00F7FF),
  Color(0xFF00D4FF),
  Color(0xFF00B3FF),
  Color(0xFF0090FF),
  Color(0xFF006EFF),
  Color(0xFF004CFF),
  Color(0xFF002AFF),
  Color(0xFF0008FF),
  Color(0xFFE600FF),
  Color(0xFFC400FF),
  Color(0xFFA100FF),
  Color(0xFF8000FF),
];

class PlottedData extends StatelessWidget {
  const PlottedData({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plotted EEG Data',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plotted EEG Data'),
        ),
        body: CustomPaint(
          painter: Renderer(),
          size: const Size(300, 300),
        ),
      ),
    );
  }
}

class Renderer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random();

    for (int i = 0; i < channelColors.length; i++) {
      final paint = Paint()
        ..color = channelColors[i]
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final Path path = Path();

      for (int j = 0; j < 150000; j++) {
        final double x = j * 3;
        final double y = random.nextDouble() * size.height;

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
