import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'plotted_data.dart';
import 'data_reading.dart';
import 'dart:convert';

class LivePageState {
  static const int mEEGHz = 127;
  static const int mFrameSize = 90;
  static const int mMaxIndex = 60;
  static const int mMaxFrameIndex = (mEEGHz * mMaxIndex) ~/ mFrameSize;
  static const int mOffset = 127;
  static const String mPassKey = "fatigue";

  final String mOutput;
  final int mFrameIndex;
  final double mFatigeLevel;
  final bool mBeginDataStream;
  final bool mFatigueResponse;
  final List<List<double>> mRawData;
  final List<List<int>> mDataFrame;
  final List<List<int>> mChannelDataFrame;
  final DataParser parser;
  final bool mLoading;

  LivePageState(
      this.mOutput,
      this.mFrameIndex,
      this.mFatigeLevel,
      this.mBeginDataStream,
      this.mFatigueResponse,
      this.mRawData,
      this.mDataFrame,
      this.mChannelDataFrame,
      this.parser,
      this.mLoading);

  int getFrameSize() {
    return mFrameSize;
  }

  int getIndexMax() {
    return mMaxIndex;
  }

  int getFrameMax() {
    return mMaxFrameIndex;
  }

  int getMaxDataWindow() {
    return mEEGHz * mMaxIndex;
  }

  int getOffset() {
    return mOffset;
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
            false,
            false,
            [],
            List.generate(40, (index) => List.filled(16, 0)),
            List.generate(16, (index) => List.filled(40, 0)),
            DataParser(),
            false)) {
    updateData();
  }

  Future<void> updateData() async {
    while (state.mFrameIndex < state.getFrameMax() - 1) {
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
            state.mFrameIndex + 1,
            state.mFatigeLevel,
            state.mBeginDataStream,
            state.mFatigueResponse,
            state.mRawData,
            dataFrame,
            channelDataFrame,
            state.parser,
            state.mLoading));
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    emit(LivePageState(
        state.mOutput,
        state.mFrameIndex,
        state.mFatigeLevel,
        state.mBeginDataStream,
        true,
        state.mRawData,
        state.mDataFrame,
        state.mChannelDataFrame,
        state.parser,
        state.mLoading));
    onStop();
  }

  Future<void> poll() async {
    while (state.mRawData.length < state.getMaxDataWindow()) {
      final response =
          await http.get(Uri.parse('https://bci-uscneuro.tech/api/data'));
      print(response);
      List<List<double>> rawFile =
          state.parser.parseCsvWithBandPass(response.body);
      print(rawFile);
      emit(LivePageState(
          "Data Collected ${rawFile.length}",
          state.mFrameIndex,
          state.mFatigeLevel,
          state.mBeginDataStream,
          state.mFatigueResponse,
          rawFile,
          state.mDataFrame,
          state.mChannelDataFrame,
          state.parser,
          state.mLoading));
    }
  }

  Future<void> onStart() async {
    final response =
        await http.post(Uri.parse('https://bci-uscneuro.tech/api/demo/start'));
    emit(LivePageState(
        response.body,
        state.mFrameIndex,
        state.mFatigeLevel,
        true,
        state.mFatigueResponse,
        state.mRawData,
        state.mDataFrame,
        state.mChannelDataFrame,
        state.parser,
        state.mLoading));

    poll();
  }

  Future<void> onStop() async {
    emit(LivePageState(
        state.mOutput,
        state.mFrameIndex,
        state.mFatigeLevel,
        state.mBeginDataStream,
        state.mFatigueResponse,
        state.mRawData,
        state.mDataFrame,
        state.mChannelDataFrame,
        state.parser,
        true));

    final response = await http.post(
      Uri.parse('https://bci-uscneuro.tech/api/demo/stop'),
    );
    final Map<String, dynamic> json = jsonDecode(response.body);
    final dynamic pred = json['prediction'];
    final double inferenceResult = (pred is num)
        ? pred.toDouble()
        : double.tryParse(pred.toString().trim()) ?? 0.0;

    final newDataFrame =
        state.mRawData.sublist(state.getOffset(), state.mRawData.length);
    print(newDataFrame);

    emit(LivePageState(
        state.mOutput,
        state.mFrameIndex,
        inferenceResult,
        state.mBeginDataStream,
        state.mFatigueResponse,
        state.mRawData,
        state.parser.cleanData(newDataFrame),
        state.parser.cleanChannelPlotsData(newDataFrame),
        state.parser,
        false));
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
                  SizedBox(height: 15),
                  if (!state.mBeginDataStream && !state.mLoading)
                    PasswordInputView(
                      screenWidth: screenWidth,
                      viewHeight: channelViewHeight,
                    ),
                  if (state.mBeginDataStream && !state.mLoading)
                    ChannelFatigueView(
                      screenWidth: screenWidth,
                      channelViewHeight: channelViewHeight,
                      index: state.mFrameIndex,
                      maxIndex: state.getFrameMax(),
                      showFatigueLevel: state.mFatigueResponse,
                      fatigueLevel: state.mFatigeLevel,
                      channelDataFrame: state.mChannelDataFrame,
                      dataFrame: state.mDataFrame,
                    ),
                  if (state.mLoading)
                    LoadingFatigueView(
                        screenWidth: screenWidth, viewHeight: channelViewHeight)
                ],
              );
            },
          ),
        );
      },
    );
  }
}
