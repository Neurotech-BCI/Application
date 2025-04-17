import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plotted_data.dart';
import 'package:http/http.dart' as http;
import 'data_reading.dart';

class PageState {
  final String mRes;
  final String mOutput;
  final List<List<double>> mRawData;
  final List<List<int>> mDataFrame;
  final List<List<int>> mChannelDataFrame;
  final int index;
  final DataParser parser;
  PageState(this.mRes, this.mOutput, this.mRawData, this.mDataFrame,
      this.mChannelDataFrame, this.index, this.parser);
}

class PageController extends Cubit<PageState> {
  PageController()
      : super(PageState(
            "No Data",
            "Starting ...",
            [],
            List.generate(127, (index) => List.filled(16, 0)),
            List.generate(16, (index) => List.filled(127, 0)),
            1,
            DataParser())) {
    init();
  }

  void init() async {
    final rawData = await state.parser.readTest2CSV();
    emit(PageState(state.mRes, "EEG reading at Second: ${state.index}", rawData,
        state.mDataFrame, state.mChannelDataFrame, state.index, state.parser));
    update();
  }

  void update() async {
    //await Future.delayed(const Duration(seconds: 1));
    while (true) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (127 + state.index * 127 <= state.mRawData.length) {
        final newDataFrame = state.mRawData
            .sublist(0 + state.index * 127, 127 + state.index * 127);
        final List<List<int>> dataFrame = state.parser.cleanData(newDataFrame);
        final List<List<int>> channelDataFrame =
            state.parser.cleanChannelPlotsData(newDataFrame);

        emit(PageState(
            state.mRes,
            "EEG reading at Second: ${state.index}",
            state.mRawData,
            dataFrame,
            channelDataFrame,
            state.index + 1,
            state.parser));
      } else {
        final List<List<int>> dataFrame =
            state.parser.cleanData(state.mRawData);
        final List<List<int>> channelDataFrame =
            state.parser.cleanChannelPlotsData(state.mRawData);
        emit(PageState(
            state.mRes,
            "Final EEG reading, Model Prediction: ${state.mRes}",
            state.mRawData,
            dataFrame,
            channelDataFrame,
            state.index,
            state.parser));
      }
    }
  }

  Future<void> fetchTestInfrence() async {
    emit(PageState("fetching", state.mOutput, state.mRawData, state.mDataFrame,
        state.mChannelDataFrame, state.index, state.parser));
    // Real address: 'https://bci-uscneuro.tech/api/data'
    final response =
        await http.get(Uri.parse('https://bci-uscneuro.tech/api/data'));

    if (response.statusCode == 200) {
      emit(PageState(
          response.body,
          state.mOutput,
          state.mRawData,
          state.mDataFrame,
          state.mChannelDataFrame,
          state.index,
          state.parser));
    } else {
      emit(PageState('error', state.mOutput, state.mRawData, state.mDataFrame,
          state.mChannelDataFrame, state.index, state.parser));
    }
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageController, PageState>(
      builder: (context, state) {
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double scaleFactor = screenWidth / 1512;
              double headerHeight = 207 * scaleFactor;
              double headerTextWidth = 653 * scaleFactor;
              double headerTextHeight = 224 * scaleFactor;
              double channelViewHeight =
                  constraints.maxHeight - headerHeight - 35;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: screenWidth,
                        height: headerHeight,
                        child: Image.asset(
                          'png_assets/header.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SizedBox(
                          width: headerTextWidth,
                          height: headerTextHeight,
                          child: Image.asset(
                            'png_assets/headerText.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: screenWidth * (3.75 / 10),
                        child: ChannelPlotsView(
                            channelViewHeight, state.mChannelDataFrame),
                      ),
                      SizedBox(
                        width: screenWidth * (6.25 / 10),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.mOutput,
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontFamily: 'alte haas grotesk',
                                      fontWeight: FontWeight.w500)),
                              SinglePlottedData(state.mDataFrame),
                            ]),
                      )
                    ],
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}
