import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class LivePageState {
  final String mOutput;
  final int mIndex;
  LivePageState(this.mOutput, this.mIndex);
}

class LivePageController extends Cubit<LivePageState> {
  LivePageController()
      : super(LivePageState(
          "Starting",
          1,
        )) {
    startDemo();
  }

  void poll() async {
    while (state.mIndex < 120) {
      final response =
          await http.get(Uri.parse('https://bci-uscneuro.tech/api/data'));
      emit(LivePageState(
        response.body,
        state.mIndex + 1,
      ));
    }
    stopDemo();
  }

  Future<void> startDemo() async {
    final response =
        await http.post(Uri.parse('https://bci-uscneuro.tech/api/demo/start'));
    emit(LivePageState(
      response.body,
      state.mIndex,
    ));
    poll();
  }

  Future<void> stopDemo() async {
    final response =
        await http.post(Uri.parse('https://bci-uscneuro.tech/api/demo/stop'));
    emit(LivePageState(
      response.body,
      state.mIndex,
    ));
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
                ],
              );
            },
          ),
        );
      },
    );
  }
}
