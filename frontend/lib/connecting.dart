import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  List<List<int>>? mData;
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
}

class ConnectingPage extends StatelessWidget {
  const ConnectingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionControl, Connection>(
        builder: (context, state) {
      const TextStyle textStyle = TextStyle(
          fontSize: 25,
          color: Colors.black,
          fontFamily: 'alte haas grotesk',
          fontWeight: FontWeight.w500);
      return Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            height: 400,
            width: 500,
            child: state.mState == ConnectionState.connect0
                ? Text("Connecting to EEG", style: textStyle)
                : state.mState == ConnectionState.connect1
                    ? Text("Connecting to EEG .", style: textStyle)
                    : state.mState == ConnectionState.connect2
                        ? Text("Connecting to EEG ..", style: textStyle)
                        : state.mState == ConnectionState.connect3
                            ? Text("Connecting to EEG ...", style: textStyle)
                            : Text("Connected", style: textStyle),
          ),
        ])
      ]));
    });
  }
}
