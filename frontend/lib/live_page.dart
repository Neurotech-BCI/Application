import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'plotted_data.dart';
import 'data_reading.dart';

//TODO parse and clean live Data
//TODO Test time frequencies for polling and displaying data

class LivePageState {
  static const int mEEGHz = 127;
  static const int mFrameSize = 40;
  static const int mMaxIndex = 120;
  static const int mMaxFrameIndex = (mEEGHz * mMaxIndex) ~/ mFrameSize;
  static const String mPassKey = "fatigue";

  final String mOutput;
  final int mIndex;
  final int mFrameIndex;
  final int mFatigeLevel;
  final bool mBeginDataStream;
  final bool mFatigueResponse;
  final List<List<double>> mRawData;
  final List<List<int>> mDataFrame;
  final List<List<int>> mChannelDataFrame;
  final DataParser parser;

  LivePageState(
      this.mOutput,
      this.mIndex,
      this.mFrameIndex,
      this.mFatigeLevel,
      this.mBeginDataStream,
      this.mFatigueResponse,
      this.mRawData,
      this.mDataFrame,
      this.mChannelDataFrame,
      this.parser);

  int getFrameSize() {
    return mFrameSize;
  }

  int getIndexMax() {
    return mMaxIndex;
  }

  int getFrameMax() {
    return mMaxFrameIndex;
  }

  String getKey() {
    return mPassKey;
  }
}

class LivePageController extends Cubit<LivePageState> {
  LivePageController()
      : super(LivePageState(
            "Starting",
            0,
            0,
            0,
            false,
            false,
            [],
            List.generate(127, (index) => List.filled(16, 0)),
            List.generate(16, (index) => List.filled(127, 0)),
            DataParser())) {
    onStart();
  }

  Future<void> updateData() async {
    while (state.mFrameIndex < state.getFrameMax()) {
      int startIndex = state.mFrameIndex * state.getFrameSize();
      int endIndex =
          state.getFrameSize() + state.mFrameIndex * state.getFrameSize();
      if (endIndex < state.mRawData.length) {
        final newDataFrame = state.mRawData.sublist(startIndex, endIndex);
        final List<List<int>> dataFrame = state.parser.cleanData(newDataFrame);
        final List<List<int>> channelDataFrame =
            state.parser.cleanChannelPlotsData(newDataFrame);
        emit(LivePageState(
            state.mOutput,
            state.mIndex,
            state.mFrameIndex + 1,
            state.mFatigeLevel,
            state.mBeginDataStream,
            state.mFatigueResponse,
            state.mRawData,
            dataFrame,
            channelDataFrame,
            state.parser));
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    onStop();
  }

  Future<void> poll() async {
    while (state.mIndex < state.getIndexMax()) {
      final response =
          await http.get(Uri.parse('https://bci-uscneuro.tech/api/data'));
      emit(LivePageState(
          response.body,
          state.mIndex + 1,
          state.mFrameIndex,
          state.mFatigeLevel,
          state.mBeginDataStream,
          state.mFatigueResponse,
          state.mRawData,
          state.mDataFrame,
          state.mChannelDataFrame,
          state.parser));
    }
    onStop();
  }

  Future<void> onStart() async {
    final response =
        await http.post(Uri.parse('https://bci-uscneuro.tech/api/demo/start'));
    emit(LivePageState(
        response.body,
        state.mIndex,
        state.mFrameIndex,
        state.mFatigeLevel,
        state.mBeginDataStream,
        state.mFatigueResponse,
        state.mRawData,
        state.mDataFrame,
        state.mChannelDataFrame,
        state.parser));

    poll();
  }

  Future<void> onStop() async {
    final response =
        await http.post(Uri.parse('https://bci-uscneuro.tech/api/demo/stop'));
    emit(LivePageState(
        response.body,
        state.mIndex,
        state.mFrameIndex,
        state.mFatigeLevel,
        state.mBeginDataStream,
        state.mFatigueResponse,
        state.mRawData,
        state.mDataFrame,
        state.mChannelDataFrame,
        state.parser));
  }
}

class LivePage extends StatelessWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LivePageController, LivePageState>(
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
                  Text(state.mOutput,
                      style: TextStyle(
                          fontSize: 16.0,
                          fontFamily: 'alte haas grotesk',
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 15),
                  // if (!state.mBeginDataStream)
                  //   PasswordInputView(
                  //     screenWidth: screenWidth,
                  //     viewHeight: channelViewHeight,
                  //   ),
                  if (state.mBeginDataStream)
                    ChannelFatigueView(
                      screenWidth: screenWidth,
                      channelViewHeight: channelViewHeight,
                      index: state.mIndex,
                      showFatigueLevel: state.mFatigueResponse,
                      fatigueLevel: state.mFatigeLevel,
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
