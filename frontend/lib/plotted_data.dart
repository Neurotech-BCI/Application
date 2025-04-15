import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
//import 'data_reading.dart';

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

class PlottedData extends StatefulWidget {
  final List<List<int>> plotData;
  const PlottedData(this.plotData, {super.key});

  @override
  State<PlottedData> createState() => _PlottedDataState();
}

class _PlottedDataState extends State<PlottedData> {
  late Timer _timer;
  //late List<List<int>> data;
  //late int second;
  @override
  void initState() {
    super.initState();
    //second = 0;
    //data = await parseCSV('datafiles/test.csv');
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            return CustomPaint(
              painter: Renderer(widget.plotData),
              size: Size(screenWidth, 500),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(channelColors.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Channel ${index + 1}",
                        style:
                            TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 10,
                        height: 10,
                        color: channelColors[index],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class Renderer extends CustomPainter {
  final List<List<int>> plotData;
  Renderer(this.plotData);

  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    // For each channel, generate a random path.
    for (int i = 0; i < channelColors.length; i++) {
      final paint = Paint()
        ..color = channelColors[i]
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final Path path = Path();
      for (int j = 0; j < plotData.length; j++) {
        final double x = j * (size.width / plotData.length);
        final double y = plotData[j][i].toDouble();
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
    // Return true so that the custom painter repaints every time a new instance is provided.
    return true;
  }
}
