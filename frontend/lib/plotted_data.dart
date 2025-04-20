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
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: SinglePlotRenderer(widget.plotData),
      ),
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
  Color backgroundColor = const Color.fromARGB(255, 255, 255, 255),
  Color fillColor = const Color(0xFFF8BBD0),
  double borderRadius = 4,
}) {
  assert(percent >= 0 && percent <= 1);
  return Container(
    height: height,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.black, width: 1),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: percent,
        child: Container(
          decoration: BoxDecoration(
            color: channelColors[(percent * 15).round()],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    ),
  );
}

Widget buildFatigueScore({
  required int score,
  int maxScore = 3,
  double boxSize = 35,
  Color fillColor = const Color(0xFFB39DDB),
}) {
  assert(score >= 0 && score <= maxScore);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Fatigue Score:',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'alte haas grotesk',
            fontWeight: FontWeight.w700,
            fontSize: 18.0,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(maxScore, (i) {
          final filled = i < score;
          return Padding(
            padding: EdgeInsets.only(right: i == maxScore - 1 ? 0 : 6),
            child: Container(
              height: boxSize,
              width: boxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: filled ? fillColor : Colors.transparent,
                border: Border.all(color: Colors.black, width: 1),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class FatigueAPIinterface extends StatefulWidget {
  final int mIndex;
  final bool mShowFatigueLevel;
  final int mFatigeScore;

  const FatigueAPIinterface(
      this.mIndex, this.mShowFatigueLevel, this.mFatigeScore,
      {super.key});

  @override
  State<FatigueAPIinterface> createState() => _FatigueAPIinterfaceState();
}

class _FatigueAPIinterfaceState extends State<FatigueAPIinterface> {
  @override
  Widget build(BuildContext context) {
    const TextStyle tStyle = TextStyle(
        color: Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'alte haas grotesk',
        fontSize: 16.0,
        fontWeight: FontWeight.w700);
    return SizedBox(
      child: widget.mShowFatigueLevel
          ? buildFatigueScore(score: widget.mFatigeScore)
          : Column(children: [
              Text("Loading EEG Data", style: tStyle),
              SizedBox(height: 10),
              buildLoadingBar(percent: widget.mIndex / 120)
            ]),
    );
  }
}

class ChannelFatigueView extends StatelessWidget {
  final double screenWidth;
  final double channelViewHeight;
  final int index;
  final bool showFatigueLevel;
  final int fatigueLevel;
  final List<List<int>> channelDataFrame;
  final List<List<int>> dataFrame;

  const ChannelFatigueView({
    super.key,
    required this.screenWidth,
    required this.channelViewHeight,
    required this.index,
    required this.showFatigueLevel,
    required this.fatigueLevel,
    required this.channelDataFrame,
    required this.dataFrame,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.375,
            child: ChannelPlotsView(channelViewHeight, channelDataFrame),
          ),
          SizedBox(
            width: screenWidth * 0.625,
            height: channelViewHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: screenWidth * 0.5,
                  child: FatigueAPIinterface(
                      index, showFatigueLevel, fatigueLevel),
                ),
                SizedBox(height: channelViewHeight * 0.1),
                SizedBox(
                  width: screenWidth * 0.575,
                  height: channelViewHeight * 0.8,
                  child: SinglePlottedData(dataFrame),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
