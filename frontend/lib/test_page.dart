import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plotted_data.dart';
import 'package:http/http.dart' as http;
import 'data_reading.dart';
import 'output_screen.dart';

class PageState {
  final String mRes;
  final String mOutput;
  final List<List<int>> mData;
  final List<List<int>> mChannelsData;
  final int index;
  final DataParser parser;
  PageState(this.mRes, this.mOutput, this.mData, this.mChannelsData, this.index,
      this.parser);
}

class PageController extends Cubit<PageState> {
  PageController()
      : super(PageState(
            "No Data",
            "Starting ...",
            List.filled(16, List.filled(127, 0)),
            List.filled(127, List.filled(16, 0)),
            1,
            DataParser()));

  void update() async {
    await Future.delayed(const Duration(seconds: 1));
    while (true) {
      await Future.delayed(const Duration(milliseconds: 200));
      final newData = await state.parser.parseTestCSV(state.index, false);
      final newChannelData = await state.parser.parseTestCSV(state.index, true);

      if (newData.length == 127) {
        emit(PageState(state.mRes, "EEG reading at Second: ${state.index}",
            newData, newChannelData, state.index + 1, state.parser));
      } else {
        emit(PageState(
            state.mRes,
            "Final EEG reading, Model Prediction: ${state.mRes}",
            newData,
            newChannelData,
            state.index,
            state.parser));
      }
    }
  }

  Future<void> fetchTestInfrence() async {
    emit(PageState("fetching", state.mOutput, state.mData, state.mChannelsData,
        state.index, state.parser));
    // Real address: 'https://bci-uscneuro.tech/api/data'
    final response =
        await http.get(Uri.parse('https://bci-uscneuro.tech/api/data'));

    if (response.statusCode == 200) {
      emit(PageState(response.body, state.mOutput, state.mData,
          state.mChannelsData, state.index, state.parser));
    } else {
      emit(PageState('error', state.mOutput, state.mData, state.mChannelsData,
          state.index, state.parser));
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
                  constraints.maxHeight - headerHeight - 100;
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
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(state.mOutput,
                        style: TextStyle(
                            fontSize: 16.0,
                            fontFamily: 'alte haas grotesk',
                            fontWeight: FontWeight.w500))
                  ]),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: screenWidth * (3 / 10),
                        child: ChannelPlotsView(
                            channelViewHeight, state.mChannelsData),
                      ),
                      SizedBox(
                        width: screenWidth * (7 / 10),
                        child: SinglePlottedData(state.mData),
                      ),
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
