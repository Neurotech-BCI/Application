import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plotted_data.dart';
import 'package:http/http.dart' as http;
import 'data_reading.dart';

class PageState {
  final String mRes;
  final String mOutput;
  final List<List<int>> mData;
  final int index;
  final DataParser parser;
  PageState(this.mRes, this.mOutput, this.mData, this.index, this.parser);
}

class PageController extends Cubit<PageState> {
  PageController()
      : super(PageState("No Data", "Starting ...",
            List.filled(16, List.filled(127, 0)), 1, DataParser()));

  void update() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 200));
      final newData = await state.parser.parseCSV(state.index);
      if (newData.length == 127) {
        emit(PageState(state.mRes, "EEG reading at Second: ${state.index}",
            newData, state.index + 1, state.parser));
      } else {
        emit(PageState(
            state.mRes,
            "Final EEG reading, Model Prediction: ${state.mRes}",
            newData,
            state.index,
            state.parser));
      }
    }
  }

  Future<void> fetchData() async {
    emit(PageState(
        "fetching", state.mOutput, state.mData, state.index, state.parser));
    // Real address: 'https://bci-uscneuro.tech/api/data'
    final response =
        await http.get(Uri.parse('https://bci-uscneuro.tech/api/data'));

    if (response.statusCode == 200) {
      emit(PageState(response.body, state.mOutput, state.mData, state.index,
          state.parser));
    } else {
      emit(PageState(
          'error', state.mOutput, state.mData, state.index, state.parser));
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
                            fontSize: 15.0,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900))
                  ]),
                  Expanded(child: PlottedData(state.mData)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
