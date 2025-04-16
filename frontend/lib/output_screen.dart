import 'package:flutter/material.dart';
import 'plotted_data.dart';

class OutputScreenData {
  final List<List<int>> mData;
  final int mClassification;
  OutputScreenData(this.mData, this.mClassification);
}

class OutputScreen extends StatelessWidget {
  final OutputScreenData screenData;
  const OutputScreen(this.screenData, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(builder: (context, constraints) {
      //double width = constraints.maxWidth;
      //double height = constraints.maxHeight;
      //double fatigueGaugeHeight = height / 5;
      return SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ChannelPlottedData(0, screenData.mData[0])]));
    }));
  }
}

// class FatigueGauge extends StatelessWidget {
//   final int mFatigueLevel;
//   final double mHeight;
//   final double mWidth;
//   const FatigueGauge(this.mFatigueLevel, this.mHeight, this.mWidth,
//       {super.key});
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//         width: mWidth,
//         height: mHeight,
//         child: Row(
//           children: [],
//         ));
//   }
// }
