// Questions still need to timeout after 2000ms if not answered 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:flutter/services.dart';
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

final List<LogicalKeyboardKey> keys = [
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyG,
];

final List<String> keyStrings = ['keyA', 'keyS', 'keyD', 'keyF', 'keyG'];
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
  final int mCurrCount;
  final bool mStarted;
  final bool mFinished;
  final bool mCorrect;
  final bool mQuestioning;
  final DateTime mStartTime;
  final DateTime mEndTime;
  final List<int> mKeyBoardLayout;

  const TestController(
    this.mTaskCount,
    this.mCurrCount,
    this.mStarted,
    this.mFinished,
    this.mCorrect,
    this.mQuestioning,
    this.mStartTime,
    this.mEndTime,
    this.mKeyBoardLayout
  );
}

class TestControllerCubit extends Cubit<TestController> {
  TestControllerCubit()
      : super( TestController(100, 0, false, false, false, false, DateTime.utc(1970, 1, 1), DateTime.utc(1970, 1, 1), []));

  List<int> generateUniqueRandomInts() {
    List<int> numbers = List.generate(5, (index) => index);
    numbers.shuffle(randy);
    return numbers;
  }
  void initKeys() {
    emit(TestController(state.mTaskCount, state.mCurrCount, 
    state.mStarted, state.mFinished, state.mCorrect, 
    state.mQuestioning, state.mStartTime, 
    state.mEndTime, generateUniqueRandomInts()));
  }
  void initStroop(int cnt) {
    emit(TestController(cnt, state.mCurrCount, 
    !state.mStarted, state.mFinished, state.mCorrect,
    state.mQuestioning, state.mStartTime, 
    state.mEndTime, state.mKeyBoardLayout));
  }
  void updateFinished() {
    emit(TestController(state.mTaskCount, state.mCurrCount, 
    state.mStarted, true, state.mCorrect, 
     true, state.mStartTime, 
     state.mEndTime, state.mKeyBoardLayout));
  }
  void updateCorrect(bool correct) {
    emit(TestController(state.mTaskCount, state.mCurrCount, 
    state.mStarted, state.mFinished, correct, state.mQuestioning, 
    state.mStartTime, state.mEndTime, state.mKeyBoardLayout));
  }
  void updateQuestioning() {
    if(state.mQuestioning == false)
    {
      print('${state.mCurrCount}, ${state.mTaskCount}');
      emit(TestController(state.mTaskCount, state.mCurrCount + 1, 
      state.mStarted, state.mFinished, state.mCorrect, 
      !state.mQuestioning, DateTime.now(),
      state.mEndTime, state.mKeyBoardLayout));
    }
    else
    {
      emit(TestController(state.mTaskCount, state.mCurrCount,
        state.mStarted, state.mFinished, state.mCorrect,
        !state.mQuestioning, state.mStartTime, 
        DateTime.now(), state.mKeyBoardLayout));
    }
  }
}

// ------------------ CsvTracker -----------------------
class CsvTracker {
  final List<DateTime> startTimes;
  final List<DateTime> endTimes;
  final List<int> reactionTimes;
  final List<bool> accuracy;
  final List<bool> timeOut;

  const CsvTracker(
    this.startTimes,
    this.endTimes,
    this.reactionTimes,
    this.accuracy,
    this.timeOut
  );

  int boolToInt(bool value) => value ? 1 : 0;

  List<List<String>> toCsv() {
    final csvData = <List<String>>[];

    csvData.add([
      'Start (YYYY-MM-DD HH:MM:SS.microseconds)',
      'End (YYYY-MM-DD HH:MM:SS.microseconds)',
      'Reaction Time (milliseconds)',
      'Accuracy (true = Correct)',
      'TimeOut (true = Too long)'
    ]);

    for (var i = 0; i < startTimes.length; i++) {
      csvData.add([
        startTimes[i].toString(),
        endTimes[i].toString(),
        reactionTimes[i].toString(),
        boolToInt(accuracy[i]).toString(),
        boolToInt(timeOut[i]).toString(),
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
  CsvTrackerCubit()
      : super(const CsvTracker([], [], [], [], []));

  void update(DateTime startTime, DateTime endTime, int reactionTime,
      bool accuracyValue, bool timeOutValue) {
    if(endTime != DateTime.utc(1970, 1, 1)){
      final updatedStartTimes = List<DateTime>.from(state.startTimes)
        ..add(startTime);
      final updatedEndTimes = List<DateTime>.from(state.endTimes)
        ..add(endTime);
      final updatedReactionTimes = List<int>.from(state.reactionTimes)
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
}

class TaskState{
  final BuildContext context;
  const TaskState({required this.context});
}

class TaskCubit extends Cubit<TaskState> {
  TaskCubit(BuildContext context): super( TaskState(context: context));
  late TestControllerCubit controllerCubit;
  late TestObjectCubit objCubit;
  late CsvTrackerCubit csvCubit;

  StreamSubscription<TestController>? _controllerSub;

  void init() {
    controllerCubit = state.context.read<TestControllerCubit>();
    objCubit = state.context.read<TestObjectCubit>();
    csvCubit = state.context.read<CsvTrackerCubit>();

    _controllerSub = controllerCubit.stream.listen((controllerState) {
      if (controllerState.mCurrCount == controllerState.mTaskCount) 
      {
        controllerCubit.updateQuestioning();
      }
      if(controllerState.mFinished) 
      {
        csvCubit.state.writeOutData();
      }
      if(controllerState.mQuestioning)
      {
        objCubit.update();
      }
      if (!controllerState.mQuestioning) 
      {
        if (controllerState.mCurrCount > controllerState.mTaskCount) 
        {
          controllerCubit.updateFinished();
        } 
        else
        {
          updateData();
        }
      }
    });
  }
  void processKeyEvent(LogicalKeyboardKey key) {
    if (controllerCubit.state.mQuestioning) {
      for(int i = 0; i < 5; i++){
        if (key == keys[i]) {
          if (objCubit.state.mType != 0 && objCubit.state.mWord == words[controllerCubit.state.mKeyBoardLayout.indexOf(i)]){
            controllerCubit.updateCorrect(true);
            controllerCubit.updateQuestioning();
          }
          else if (objCubit.state.mType == 0 && objCubit.state.mColor == colors[controllerCubit.state.mKeyBoardLayout.indexOf(i)]){
            controllerCubit.updateCorrect(true);
            controllerCubit.updateQuestioning();
          } else {
            controllerCubit.updateCorrect(false);
            controllerCubit.updateQuestioning();
          }
        }
      }
    }
  }

  void updateData() {
    final startTime = controllerCubit.state.mStartTime;
    final endTime = controllerCubit.state.mEndTime;
    final reactionTime = endTime.difference(startTime).inMilliseconds;
    final accuracy = controllerCubit.state.mCorrect;
    final timeOut = reactionTime > 2000;
    csvCubit.update(startTime, endTime, reactionTime, accuracy, timeOut);
  }

  @override
  Future<void> close() {
    _controllerSub?.cancel(); // Cancel the subscription to prevent memory leaks.
    return super.close();
  }
}

// ------------------ Main -----------------------

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
        BlocProvider<CsvTrackerCubit>(
          create: (context) => CsvTrackerCubit(),
        ),
        BlocProvider<TaskCubit>(
          create: (context) => TaskCubit(context)..init(), // Initialize TaskCubit
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Add key for performance optimization

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor:   const Color.fromARGB(255, 191, 208, 220),
        centerTitle: true,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Stroop Task Program'),
            Text(
              'Neurotech USC BCI Project 2025',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        return Row( //////////////////////////////////////////
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ 
            BlocBuilder<TestControllerCubit, TestController>(
              builder: (context, state) {
                return Column( //////////////////////////////////////////
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BlocBuilder<TestObjectCubit, TestObjectState>(
                      builder: (context, state) {
                        return Column( //////////////////////////////////////////
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BlocProvider.of<TestControllerCubit>(context).state.mFinished ?
                              _endOutput() :
                              !BlocProvider.of<TestControllerCubit>(context).state.mStarted ? 
                                InputOnStart() : // ADD INPUT WIDGET HERE
                                InputOnTask(),
                            const SizedBox(height: 24), 
                            ],
                          );
                        },
                      ),
                    ],
                  );
                }
              ),
            ],
          );
        },
      ),
    );
  }
 
  Future<Directory> getDirectory() async {
        final dir = await getApplicationDocumentsDirectory();
        return dir;
  }
 
  Widget _endOutput() {
    return FutureBuilder<Directory>(
      future: getDirectory(), // The asynchronous function to wait for.
      builder: (
        BuildContext context, 
        AsyncSnapshot<Directory> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While the future is loading, show a loading indicator.
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // If the future returns an error, display the error.
          return Text(
            'Error: ${snapshot.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: Color.fromARGB(255, 30, 204, 186),
            ),
          );
        } else if (snapshot.hasData) {
          // Once the future completes, you have the directory.
          final Directory dir = snapshot.data!;
          return Text(
            'Tests Finished! \n \n Directory path: \n ${dir.path}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 30, 204, 186),
            ),
          );
        } else {
          // In case no data is returned.
          return const Text(
            'No directory found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Color.fromARGB(255, 30, 204, 186),
            ),
          );
        }
      },
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
    final controllerCubit = context.read<TestControllerCubit>();
    controllerCubit.initKeys();
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
          Container(
            height: 50,
            width: 300,
            decoration: BoxDecoration(
              color: const Color.fromARGB(112, 135, 119, 125),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black),
            ),
            child: 
              Text('Press the Spacebar to Start', 
              textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                ),
              )
          ),
          SizedBox(height: 30),
          RevealTextWidget(),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 188, 174, 179),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _tec,
                  textAlign: TextAlign.center, // This centers the text
                  style: const TextStyle(fontSize: 17.0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter Number of Trials Here',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Text('100 Trials if left blank', 
            style: const TextStyle(fontSize: 15)
          ),
          SizedBox(height: 50),
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

class RevealTextWidget extends StatefulWidget {
  const RevealTextWidget({super.key});

  @override
  RevealTextWidgetState createState() => RevealTextWidgetState();
}

class RevealTextWidgetState extends State<RevealTextWidget> {
  bool _isRevealed = false;

  void _toggleReveal() {
    setState(() {
      _isRevealed = !_isRevealed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleReveal,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 79, 113, 173),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: ColoredTextExample(colored: _isRevealed),
        ),
      ),
    );
  }
}

class ColoredTextExample extends StatelessWidget {
  final bool colored;

  const ColoredTextExample({super.key, required this.colored});

  @override
  Widget build(BuildContext context) {
    final controllerCubit = context.read<TestControllerCubit>();
    if (colored) {
      return RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18.0),
          children: List.generate(5, (index) {
            return TextSpan(
              text: '${keyStrings[controllerCubit.state.mKeyBoardLayout[index]]}: ${words[index]}\n',
              style: TextStyle(color: colors[index], fontWeight: FontWeight.bold, fontSize: 18.0),
            );
          }),
        ),
      );
    } else {
      return const Text(
        'Click to Reveal Randomized Keyboard Inputs',
        style: TextStyle(fontSize: 17.0),
      );
    }
  }
}

class InputOnTask extends StatefulWidget {
  const InputOnTask({super.key});

  @override
  State<InputOnTask> createState() => _InputOnTaskState();
}

class _InputOnTaskState extends State<InputOnTask> {
  final FocusNode _focusNode = FocusNode();
  bool _showWait = false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Check if user pressed SPACE in a KeyDownEvent
        if(BlocProvider.of<TestControllerCubit>(context).state.mQuestioning){
          for(int i = 0; i < 5; i++){
            if(!_showWait){
              if (event is KeyDownEvent && event.logicalKey == keys[i]) {
                BlocProvider.of<TaskCubit>(context).processKeyEvent(keys[i]);
                _startTask();
                return KeyEventResult.handled;
              }
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocProvider.of<TestControllerCubit>(context).state.mQuestioning ? 
            _buildTestObjectView(BlocProvider.of<TestObjectCubit>(context).state) : 
            BlocProvider.of<TestControllerCubit>(context).state.mCorrect ?
              _responseOutput(true) :
              _responseOutput(false),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
  
  Widget _buildTestObjectView(TestObjectState state) {
    if (state.mType == 0) {
      return _buildBoxTask(state.mColor);
    } else if (state.mType == 1) {
      return _buildTextTask(state.mColor, state.mWord, true);
    } else {
      return _buildTextTask(state.mColor, state.mWord, false);
    }
  }
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
  Future<void> _startTask() async {
    setState(() => _showWait = true);
    final controllerCubit = context.read<TestControllerCubit>();
    await Future.delayed(const Duration(seconds: 2));
    controllerCubit.updateQuestioning();
    setState(() => _showWait = false);
  }
}

