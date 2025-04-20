import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

final List<Color> channelColors = [
  Color(0xFFE57373), // Red 300 (darker red)
  Color(0xFFFFAB91), // Deep Orange 200
  Color(0xFFFFCC80), // Orange 200
  Color(0xFFFFE082), // Amber 200
  Color(0xFFFFF59D), // Yellow 200
  Color(0xFFE6EE9C), // Lime 200
  Color(0xFFC5E1A5), // Light Green 200
  Color(0xFFA5D6A7), // Green 200
  Color(0xFF80CBC4), // Teal 200
  Color(0xFF80DEEA), // Cyan 200
  Color(0xFF81D4FA), // Light Blue 200
  Color(0xFF90CAF9), // Blue 200
  Color(0xFF9FA8DA), // Indigo 200
  Color(0xFFB39DDB), // Deep Purple 200
  Color(0xFFCE93D8), // Purple 200
  Color(0xFFF8BBD0), // Pink 200
];

class SinglePlottedData extends StatefulWidget {
  final List<List<int>> plotData;
  const SinglePlottedData(this.plotData, {super.key});

  @override
  State<SinglePlottedData> createState() => _SinglePlottedDataState();
}

class _SinglePlottedDataState extends State<SinglePlottedData> {
  late Timer _timer;
  @override
  void initState() {
    super.initState();
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
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            double plotWidth = constraints.maxWidth * (9 / 10);
            double plotHeight = constraints.maxWidth * (5.5 / 10);

            return CustomPaint(
              painter: SinglePlotRenderer(widget.plotData),
              size: Size(plotWidth, plotHeight),
            );
          },
        ),
      ],
    );
  }
}

class SinglePlotRenderer extends CustomPainter {
  final List<List<int>> plotData;
  SinglePlotRenderer(this.plotData);

  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < channelColors.length; i++) {
      final paint = Paint()
        ..color = channelColors[i]
        ..strokeWidth = 0.6
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
    return true;
  }
}

class ChannelPlottedData extends StatefulWidget {
  final int channelIndex;
  final List<int> plotData;
  const ChannelPlottedData(this.channelIndex, this.plotData, {super.key});

  @override
  State<ChannelPlottedData> createState() => _ChannelPlottedDataState();
}

class _ChannelPlottedDataState extends State<ChannelPlottedData> {
  @override
  Widget build(BuildContext context) {
    const TextStyle channelLabelStyle = TextStyle(
        fontSize: 11.0,
        color: Colors.black,
        fontFamily: 'alte haas grotesk',
        fontWeight: FontWeight.w700);
    return LayoutBuilder(
      builder: (context, constraints) {
        double colorDim = constraints.maxWidth * (1 / 30);
        double openSpace = constraints.maxWidth * (1 / 20);
        double plotWidth = constraints.maxWidth * (3.75 / 5);
        return Container(
            width: constraints.maxWidth,
            padding: EdgeInsets.all(openSpace / 10),
            margin: EdgeInsets.all(openSpace / 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 1.0,
              ),
            ),
            child: Row(children: [
              Text("Channel  ${widget.channelIndex}", style: channelLabelStyle),
              SizedBox(width: openSpace / 6),
              Container(
                height: colorDim,
                width: colorDim,
                color: channelColors[widget.channelIndex],
              ),
              SizedBox(width: openSpace / 2),
              CustomPaint(
                painter:
                    ChannelPlotRenderer(widget.channelIndex, widget.plotData),
                size: Size(plotWidth, 50),
              )
            ]));
      },
    );
  }
}

class ChannelPlotRenderer extends CustomPainter {
  final int channelIndex;
  final List<int> plotData;
  ChannelPlotRenderer(this.channelIndex, this.plotData);

  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = channelColors[channelIndex]
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    for (int j = 0; j < plotData.length; j++) {
      final double x = j * (size.width / plotData.length);
      final double y = plotData[j].toDouble();
      if (j == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ChannelPlotsView extends StatefulWidget {
  final List<List<int>> plotsData;
  final double mHeight;
  const ChannelPlotsView(this.mHeight, this.plotsData, {super.key});

  @override
  State<ChannelPlotsView> createState() => _ChannelPlotsViewState();
}

class _ChannelPlotsViewState extends State<ChannelPlotsView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.mHeight, // Specify a finite height here.
      child: SingleChildScrollView(
        child: Column(
          children: [
            ...List.generate(
              16,
              (index) => ChannelPlottedData(index, widget.plotsData[index]),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildLoadingBar({
  required double percent,
  double height = 20,
  Color backgroundColor = Colors.grey,
  Color fillColor = const Color(0xFFF8BBD0),
  double borderRadius = 4,
}) {
  assert(percent >= 0 && percent <= 1);
  return Container(
    height: height,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: percent,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    ),
  );
}
