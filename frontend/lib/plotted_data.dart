import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'live_page.dart';

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

final List<Color> scoreColors = [
  Color(0xFFA5D6A7),
  Color(0xFFFFE082),
  Color(0xFFE57373),
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
        ..strokeWidth = .8
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
              Text("Channel  ${widget.channelIndex + 1}",
                  style: channelLabelStyle),
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
  required double percent,
  double height = 20,
  Color backgroundColor = const Color.fromARGB(255, 255, 255, 255),
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
            color: scoreColors[(percent * 2).round()],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    ),
  );
}

class FatigueAPIinterface extends StatefulWidget {
  final int mIndex;
  final int mMaxIndex;
  final bool mShowFatigueLevel;
  final double mFatigeScore;

  const FatigueAPIinterface(
      this.mIndex, this.mMaxIndex, this.mShowFatigueLevel, this.mFatigeScore,
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
          ? Column(children: [
              Text(
                  "User is at a Fatigue level of ${(widget.mFatigeScore * 100).toStringAsFixed(0)}%",
                  style: tStyle),
              SizedBox(height: 10),
              buildFatigueScore(percent: widget.mFatigeScore)
            ])
          : Column(children: [
              Text("Loading EEG Data", style: tStyle),
              SizedBox(height: 10),
              buildLoadingBar(percent: widget.mIndex / widget.mMaxIndex)
            ]),
    );
  }
}

class ChannelFatigueView extends StatelessWidget {
  final double screenWidth;
  final double channelViewHeight;
  final int index;
  final int maxIndex;
  final bool showFatigueLevel;
  final double fatigueLevel;
  final List<List<int>> channelDataFrame;
  final List<List<int>> dataFrame;

  const ChannelFatigueView({
    super.key,
    required this.screenWidth,
    required this.channelViewHeight,
    required this.index,
    required this.maxIndex,
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
                      index, maxIndex, showFatigueLevel, fatigueLevel),
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

class PasswordInputView extends StatefulWidget {
  final double screenWidth;
  final double viewHeight;

  const PasswordInputView({
    super.key,
    required this.screenWidth,
    required this.viewHeight,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PasswordInputViewState createState() => _PasswordInputViewState();
}

class _PasswordInputViewState extends State<PasswordInputView> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LivePageController>();

    return Expanded(
      child: SizedBox(
        height: widget.viewHeight,
        child: Center(
          child: SizedBox(
            width: widget.screenWidth * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  obscureText: true,
                  obscuringCharacter: '•',
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final password = _controller.text;
                    if (password == bloc.state.getKey()) {
                      bloc.onStart();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingFatigueView extends StatelessWidget {
  final double screenWidth;
  final double viewHeight;

  const LoadingFatigueView({
    super.key,
    required this.screenWidth,
    required this.viewHeight,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle tStyle = TextStyle(
        color: Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'alte haas grotesk',
        fontSize: 32.0,
        fontWeight: FontWeight.w700);
    return Expanded(
      child: SizedBox(
        height: viewHeight,
        child: const Center(
          child: Text('Loading Fatigue Score',
              textAlign: TextAlign.center, style: tStyle),
        ),
      ),
    );
  }
}
