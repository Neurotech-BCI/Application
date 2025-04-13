import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:convert';

enum ConnectionState {
  connect0,
  connect1,
  connect2,
  connect3,
  connected,
}

class Connection {
  ConnectionState mState;
  Connection(this.mState);
}

class ConnectionControl extends Cubit<Connection> {
  List<ConnectionState> connectionStates = [
    ConnectionState.connect0,
    ConnectionState.connect1,
    ConnectionState.connect2,
    ConnectionState.connect3,
    ConnectionState.connected,
  ];

  int index = 0;
  ConnectionControl() : super(Connection(ConnectionState.connect0)) {
    update();
  }

  void update() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 700));
      index++;
      if (index == 4) {
        index = 0;
      }
      emit(Connection(connectionStates[index]));
    }
  }

  Future<void> getEEGConnection() async {
    final client = HttpClient();
    try {
      final url = Uri.parse('https://bci-uscneuro.tech/api/eegConnect');
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        print("Response body: $responseBody");
      } else {
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception caught: $e");
    } finally {
      client.close();
    }
  }
}

class ConnectingPage extends StatelessWidget {
  const ConnectingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionControl, Connection>(
      builder: (context, state) {
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double scaleFactor = screenWidth / 1512;
              double headerHeight = 207 * scaleFactor;
              double headerTextWidth = 653 * scaleFactor;
              double headerTextHeight = 224 * scaleFactor;

              const textStyle = TextStyle(
                fontFamily: 'Roboto',
                fontSize: 50,
              );

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
                  const SizedBox(height: 100),
                  Center(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 400,
                                width: 500,
                                child: state.mState == ConnectionState.connect0
                                    ? Text("Connecting to EEG",
                                        style: textStyle)
                                    : state.mState == ConnectionState.connect1
                                        ? Text("Connecting to EEG .",
                                            style: textStyle)
                                        : state.mState ==
                                                ConnectionState.connect2
                                            ? Text("Connecting to EEG ..",
                                                style: textStyle)
                                            : state.mState ==
                                                    ConnectionState.connect3
                                                ? Text("Connecting to EEG ...",
                                                    style: textStyle)
                                                : Text("Connected",
                                                    style: textStyle),
                              ),
                            ])
                      ])),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
