import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:time/time.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';


// Global colors and words
final List<Color> colors = [
  const Color(0xFFF44336), // red
  const Color(0xFF2196F3), // blue
  const Color(0xFF4CAF50), // green
  const Color(0xFF795548), // brown
  const Color(0xFF9C27B0), // purple
];
final List<String> words = ['Red', 'Blue', 'Green', 'Brown', 'Purple'];
final List<int> types = [0, 1, 2];

// Make a top-level Random instance
final Random randy = Random(DateTime.now().millisecondsSinceEpoch);

// ------------------ TestObject --------------------------
class TestObjectState {
  final Color mColor;
  final String mWord;
  final int mType;

  const TestObjectState(this.mColor, this.mWord, this.mType);
}

class TestObjectCubit extends Cubit<TestObjectState> {
  TestObjectCubit() : super(TestObjectState(colors[randy.nextInt(colors.length)], words[randy.nextInt(words.length)], randy.nextInt(types.length)));

  void update() {
    final sequence = _generateRandomSequence();
    emit(
      TestObjectState(
        colors[sequence[0]],
        words[sequence[1]],
        sequence[2],
      ),
    );
  }

  List<int> _generateRandomSequence() => [
        randy.nextInt(colors.length),
        randy.nextInt(words.length),
        randy.nextInt(types.length),
      ];
}

// ------------------ TestController -----------------------
class TestController {
  final int mTaskCount;
  final bool mStarted;
  final bool mFinished;
  final bool mCorrect;
  final bool mQuestioning;

  const TestController(
    this.mTaskCount,
    this.mStarted,
    this.mFinished,
    this.mCorrect,
    this.mQuestioning,
  );
}

class TestControllerCubit extends Cubit<TestController> {
  TestControllerCubit()
      : super(const TestController(0, false, false, false, false));

  void initStroop(int cnt) {
    emit(TestController(cnt, !state.mStarted, state.mFinished, state.mCorrect, state.mQuestioning));
  }
  void updateFinished() {
    emit(TestController(state.mTaskCount, state.mStarted, !state.mFinished, state.mCorrect, state.mQuestioning));
  }
  void updateCorrect() {
    emit(TestController(state.mTaskCount, state.mStarted, state.mFinished, !state.mCorrect, state.mQuestioning));
  }
  void updateQuestioning() {
    //if(state.mQuestioning == false)
    emit(TestController(state.mTaskCount, state.mStarted, state.mFinished, state.mCorrect, !state.mQuestioning));
  }
}

// ------------------ CsvTracker -----------------------
class CsvTracker {
  final List<DateTime> startTimes;
  final List<DateTime> endTimes;
  final List<double> reactionTimes;
  final List<bool> accuracy;
  final List<bool> timeOut;

  const CsvTracker(
    this.startTimes,
    this.endTimes,
    this.reactionTimes,
    this.accuracy,
    this.timeOut,
  );

  int boolToInt(bool value) => value ? 1 : 0;

  List<List<String>> toCsv() {
    final csvData = <List<String>>[];

    // Add headers
    csvData.add([
      'Start (YYYY-MM-DD HH:MM:SS.microseconds)',
      'End (YYYY-MM-DD HH:MM:SS.microseconds)',
      'Reaction Time (milliseconds)',
      'Accuracy (true=Correct)',
      'TimeOut (true=Too long)'
    ]);

    // Add data rows
    for (var i = 0; i < startTimes.length; i++) {
      csvData.add([
        startTimes[i].toString(),
        endTimes[i].toString(),
        ((reactionTimes[i] * 100).round() / 100).toString(), // Round to 2 decimal places
        boolToInt(accuracy[i]).toString(), // Convert bool to 0 or 1
        boolToInt(timeOut[i]).toString(), // Convert bool to 0 or 1
      ]);
    }

    return csvData;
  }

  String toCsvString() {
    final data = toCsv();
    return const ListToCsvConverter().convert(data);
  }

  void writeOutData() async {
    final csvData = toCsvString();
    final fileName = 'stroop_test_${DateTime.now().toIso8601String()}.csv';
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsString(csvData);
  }

}

class CsvTrackerCubit extends Cubit<CsvTracker> {
  // Initialize with empty lists
  CsvTrackerCubit()
      : super(const CsvTracker([], [], [], [], []));

  // Push back each item into the lists
  void update(DateTime startTime, DateTime endTime, double reactionTime,
      bool accuracyValue, bool timeOutValue) {
    final updatedStartTimes = List<DateTime>.from(state.startTimes)
      ..add(startTime);
    final updatedEndTimes = List<DateTime>.from(state.endTimes)
      ..add(endTime);
    final updatedReactionTimes = List<double>.from(state.reactionTimes)
      ..add(reactionTime);
    final updatedAccuracy = List<bool>.from(state.accuracy)
      ..add(accuracyValue);
    final updatedTimeOut = List<bool>.from(state.timeOut)
      ..add(timeOutValue);

    emit(
      CsvTracker(
        updatedStartTimes,
        updatedEndTimes,
        updatedReactionTimes,
        updatedAccuracy,
        updatedTimeOut,
      ),
    );
  }
}
void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<TestObjectCubit>(
          create: (context) => TestObjectCubit(),
        ),
        BlocProvider<TestControllerCubit>(
          create: (context) => TestControllerCubit(),
        ),
        // Add more BLoCs here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget 
{
  const MyApp({super.key});

  @override
  Widget build( BuildContext context )
  { 
    return BlocProvider<TestObjectCubit>( 
      create: (context) => TestObjectCubit(),
      child:  MaterialApp( 
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Stroop Test'),
            Text(
              'Neurotech USC BCI Project 2025',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocBuilder<TestControllerCubit, TestController>(
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlocBuilder<TestObjectCubit, TestObjectState>(
                    builder: (context, state) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BlocProvider.of<TestControllerCubit>(context).state.mFinished ?
                            _endOutput() :
                            !BlocProvider.of<TestControllerCubit>(context).state.mStarted ? 
                              InputOnStart() : // ADD INPUT WIDGET HERE
                              BlocProvider.of<TestControllerCubit>(context).state.mQuestioning ? 
                                _buildTestObjectView(state) : 
                                BlocProvider.of<TestControllerCubit>(context).state.mCorrect ?
                                  _responseOutput(true) :
                                  _responseOutput(false),
                          const SizedBox(height: 24), 
                        ],
                      );
                    },
                  ),


                // Timer, Task Count, CSV, and KeyBoard Input logic here. 


                ],
              );
            },
          ),
        ],
      ),
    );
  }
  // Helper function to choose which widget to display
  Widget _buildTestObjectView(TestObjectState state) {
    if (state.mType == 0) {
      return _buildBoxTask(state.mColor);
    } else if (state.mType == 1) {
      return _buildTextTask(state.mColor, state.mWord, true);
    } else {
      return _buildTextTask(state.mColor, state.mWord, false);
    }
  }

  // Same widget-building logic, but as private methods in the widget
  Widget _buildBoxTask(Color color) 
  {
    return Container(
      width: 100,
      height: 100,
      color: color,
    );
  }

  Widget _buildTextTask(Color color, String word, bool colored) 
  {
    return Container(
      width: 120,
      height: 100,
      alignment: Alignment.center,
      child: Text(
        word,
        style: TextStyle(
          color: colored ? color : Colors.black,
          fontSize: 24,
        ),
      ),
    );
  }
  
  Widget _responseOutput(bool correct)
  {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      child: Center(
        child: Text(
          correct ? 'Correct' : 'Incorrect',
          style: TextStyle(
            color: Color.fromARGB(255, 30, 204, 186),
            fontSize: 60,
          ),
        ),
      ),
    );
  }
  Widget _endOutput()
  {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
      ),
      child: Center(
        child: Text(
          'Test Finished: Check CSV for data \n in the Documents folder',
          style: TextStyle(
            color: Color.fromARGB(255, 30, 204, 186),
            fontSize: 25,
          ),
        ),
      ),
    );
  }
}



class InputOnStart extends StatefulWidget {
  const InputOnStart({super.key});

  @override
  State<InputOnStart> createState() => _InputOnStartState();
}

class _InputOnStartState extends State<InputOnStart> {
  final TextEditingController _tec = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showWait = false;
  int counter = 3;

  @override
  void initState() {
    super.initState();
    // Automatically request focus so we can capture keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _tec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If waiting, just show "Wait..." text
    if (_showWait) {
      return Center(
        child: Text(
          'Wait... $counter',
          style: TextStyle(fontSize: 30),
        ),
      );
    }

    // Otherwise, wrap the UI in a Focus widget
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Check if user pressed SPACE in a KeyDownEvent
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space) {
          _startTask();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Use: A(Red), S(Green), D(Blue), F(Purple), G(Brown) Keys \nPress SPACE to start', 
            style: const TextStyle(fontSize: 15)
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                ),
                child: TextField(
                  controller: _tec,
                  style: const TextStyle(fontSize: 20),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter number of trials here',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startTask() async {
    setState(() => _showWait = true);

    // Parse the text as an integer (default to 100 if invalid)
    final enteredNumber = int.tryParse(_tec.text) ?? 100;
    final controllerCubit = context.read<TestControllerCubit>();

    // Wait 3 seconds
    await Future.delayed(const Duration(seconds: 1));
    setState(() => counter--);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => counter--);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => counter--);

   controllerCubit.initStroop(enteredNumber);
   controllerCubit.updateQuestioning();
    // Return to the input form (or navigate, based on your app logic)
    setState(() => _showWait = false);
  }
}