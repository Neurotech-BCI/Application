import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plotted_data.dart';
import 'data_reading.dart';

class PageState {
  final bool mShowFatigeLevel;
  final List<List<double>> mRawData;
  final List<List<int>> mDataFrame;
  final List<List<int>> mChannelDataFrame;
  final double mFatigueLevel;
  final int index;
  final DataParser parser;
  PageState(this.mShowFatigeLevel, this.mRawData, this.mDataFrame,
      this.mChannelDataFrame, this.mFatigueLevel, this.index, this.parser);
}

class PageController extends Cubit<PageState> {
  PageController()
      : super(PageState(
            false,
            [],
            List.generate(127, (index) => List.filled(16, 0)),
            List.generate(16, (index) => List.filled(127, 0)),
            .47,
            1,
            DataParser())) {
    init();
  }

  void init() async {
    final rawData = await state.parser.readTestCSV();
    emit(PageState(
        state.mShowFatigeLevel,
        rawData,
        state.mDataFrame,
        state.mChannelDataFrame,
        state.mFatigueLevel,
        state.index,
        state.parser));
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
            state.mShowFatigeLevel,
            state.mRawData,
            dataFrame,
            channelDataFrame,
            state.mFatigueLevel,
            state.index + 1,
            state.parser));
      } else {
        final List<List<int>> dataFrame =
            state.parser.cleanData(state.mRawData);
        final List<List<int>> channelDataFrame =
            state.parser.cleanChannelPlotsData(state.mRawData);
        emit(PageState(
            true,
            state.mRawData,
            state.parser.averageEveryXRows(127, dataFrame),
            state.parser.averageEveryXColumns(127, channelDataFrame),
            state.mFatigueLevel,
            state.index,
            state.parser));
        break;
      }
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
                  ChannelFatigueView(
                    screenWidth: screenWidth,
                    channelViewHeight: channelViewHeight,
                    index: state.index,
                    maxIndex: 120,
                    showFatigueLevel: state.mShowFatigeLevel,
                    fatigueLevel: state.mFatigueLevel,
                    channelDataFrame: state.mChannelDataFrame,
                    dataFrame: state.mDataFrame,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
