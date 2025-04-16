import 'dart:async';
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
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0, // horizontal gap between children
            runSpacing: 8.0, // vertical gap between lines
            children: List.generate(channelColors.length, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Channel ${index + 1}",
                    style: const TextStyle(
                      fontSize: 8,
                      fontFamily: 'alte haas grotesk',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    color: channelColors[index],
                  ),
                ],
              );
            }),
          ),
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
        ..strokeWidth = 1.5
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
      ..strokeWidth = 1.5
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
