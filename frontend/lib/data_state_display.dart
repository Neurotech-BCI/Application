import 'package:flutter/material.dart';
import 'plotted_data.dart';

class ModelDisplay extends StatefulWidget {
  final String mOutput;
  final List<List<int>> mDataFrame;
  final List<List<int>> mChannelDataFrame;

  const ModelDisplay(this.mOutput, this.mDataFrame, this.mChannelDataFrame,
      {super.key});

  @override
  State<ModelDisplay> createState() => _ModelDisplayState();
}

class _ModelDisplayState extends State<ModelDisplay> {
  @override
  Widget build(BuildContext context) {
    // const TextStyle channelLabelStyle = TextStyle(
    //     fontSize: 11.0,
    //     color: Colors.black,
    //     fontFamily: 'alte haas grotesk',
    //     fontWeight: FontWeight.w700);
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;
        double channelViewHeight = screenHeight;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: screenWidth * (3.75 / 10),
              child:
                  ChannelPlotsView(channelViewHeight, widget.mChannelDataFrame),
            ),
            SizedBox(
              width: screenWidth * (6.25 / 10),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.mOutput,
                        style: TextStyle(
                            fontSize: 16.0,
                            fontFamily: 'alte haas grotesk',
                            fontWeight: FontWeight.w500)),
                    SinglePlottedData(widget.mDataFrame),
                  ]),
            )
          ],
        );
      },
    );
  }
}
