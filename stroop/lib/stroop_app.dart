import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:convert'; // For json.decode and utf8.encode
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart'; // <-- Import here

// ------------------ STROOP WIDGET -----------------------

class StroopTask extends StatelessWidget {
  const StroopTask({super.key}); // Add key for performance optimization

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const StroopTaskWidget(), // Embedding your encapsulated widget
      ),
    );
  }
}

class StroopTaskWidget extends StatelessWidget {
  const StroopTaskWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TestObjectCubit>(
          create: (_) => TestObjectCubit(),
        ),
        BlocProvider<TestControllerCubit>(
          create: (_) => TestControllerCubit(),
        ),
        BlocProvider<CsvTrackerCubit>(
          create: (_) => CsvTrackerCubit(),
        ),
        BlocProvider<TaskCubit>(
          create: (context) => TaskCubit(context)..init(),
        ),
      ],
      child: const MyHomePage(), // Your main page widget
    );
  }
}

// ------------------ Global Variables -----------------------

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

final String testStamp = DateTime.now().toIso8601String();

// ------------------ GOOGLE AUTH -----------------------
// TODO: VIRTUALIZE THIS PROCESS, SEND CSV TO SERVER
/// Represents the service account credentials used to authenticate with Google APIs.
/// Loads the service account credentials from an asset file.
Future<ServiceAccountCredentials> _loadServiceAccountCredentials() async {
  final jsonString = await rootBundle.loadString('assets/credential.json');
  final credentialsMap = json.decode(jsonString);
  return ServiceAccountCredentials.fromJson(credentialsMap);
}

/// Returns an authenticated instance of the Drive API.
Future<drive.DriveApi> getDriveApi() async {
  try {
    final credentials = await _loadServiceAccountCredentials();
    final scopes = [drive.DriveApi.driveFileScope];
    final client = await clientViaServiceAccount(credentials, scopes);
    return drive.DriveApi(client);
  } catch (e) {
    rethrow;
  }
}

/// Example function to upload a file to Google Drive.
Future<void> uploadFileToDrive(String csvContent, String fileName) async {
  try {
    final driveApi = await getDriveApi();
    final csvBytes = utf8.encode(csvContent);
    final driveFile = drive.File()
      ..name = fileName
      ..parents = ['19KE2jfHlKZyJSdk4WVf3-k9aOEMXUC6-'];
    final media = drive.Media(
      Stream.fromIterable([csvBytes]),
      csvBytes.length,
      contentType: 'text/csv',
    );
    await driveApi.files.create(
      driveFile,
      uploadMedia: media,
    );
    //print('File uploaded: ${result.name} (ID: ${result.id})');
  } catch (e) {
    //print('An error occurred during file upload: $e');
  }
}

// ------------------ CsvTracker -----------------------
class CsvTracker {
  final List<DateTime> startTimes;
  final List<DateTime> endTimes;
  final List<int> reactionTimes;
  final List<bool> accuracy;
  final List<bool> timeOut;

  const CsvTracker(this.startTimes, this.endTimes, this.reactionTimes,
      this.accuracy, this.timeOut);

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
    final fileName = 'stroop_test_$testStamp.csv';
    await uploadFileToDrive(csvData, fileName);
  }
}

class CsvTrackerCubit extends Cubit<CsvTracker> {
  CsvTrackerCubit() : super(const CsvTracker([], [], [], [], []));

  void update(DateTime startTime, DateTime endTime, int reactionTime,
      bool accuracyValue, bool timeOutValue) {
    if (endTime != DateTime.utc(1970, 1, 1)) {
      final updatedStartTimes = List<DateTime>.from(state.startTimes)
        ..add(startTime);
      final updatedEndTimes = List<DateTime>.from(state.endTimes)..add(endTime);
      final updatedReactionTimes = List<int>.from(state.reactionTimes)
        ..add(reactionTime);
      final updatedAccuracy = List<bool>.from(state.accuracy)
        ..add(accuracyValue);
      final updatedTimeOut = List<bool>.from(state.timeOut)..add(timeOutValue);

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

// ------------------ TestObject --------------------------
class TestObjectState {
  final Color mColor;
  final String mWord;
  final int mType;

  const TestObjectState(this.mColor, this.mWord, this.mType);
}

class TestObjectCubit extends Cubit<TestObjectState> {
  TestObjectCubit()
      : super(TestObjectState(colors[randy.nextInt(colors.length)],
            words[randy.nextInt(words.length)], randy.nextInt(types.length)));

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
  final bool mDatabit;

  const TestController(
      this.mTaskCount,
      this.mCurrCount,
      this.mStarted,
      this.mFinished,
      this.mCorrect,
      this.mQuestioning,
      this.mStartTime,
      this.mEndTime,
      this.mKeyBoardLayout,
      this.mDatabit);
}

class TestControllerCubit extends Cubit<TestController> {
  TestControllerCubit()
      : super(TestController(
            100,
            0,
            false,
            false,
            false,
            false,
            DateTime.utc(1970, 1, 1),
            DateTime.utc(1970, 1, 1),
            [0, 1, 2, 3, 4],
            false));

  List<int> generateUniqueRandomInts() {
    List<int> numbers = List.generate(5, (index) => index);
    numbers.shuffle(randy);
    return numbers;
  }

  void initKeys() {
    emit(TestController(
        state.mTaskCount,
        state.mCurrCount,
        state.mStarted,
        state.mFinished,
        state.mCorrect,
        state.mQuestioning,
        state.mStartTime,
        state.mEndTime,
        generateUniqueRandomInts(),
        state.mDatabit));
  }

  void initStroop(int cnt, bool setBit) {
    emit(TestController(
        cnt,
        state.mCurrCount,
        !state.mStarted,
        state.mFinished,
        state.mCorrect,
        state.mQuestioning,
        state.mStartTime,
        state.mEndTime,
        state.mKeyBoardLayout,
        setBit));
  }

  void updateFinished() {
    emit(TestController(
        state.mTaskCount,
        state.mCurrCount,
        state.mStarted,
        true,
        state.mCorrect,
        true,
        state.mStartTime,
        state.mEndTime,
        state.mKeyBoardLayout,
        state.mDatabit));
  }

  void updateCorrect(bool correct) {
    emit(TestController(
        state.mTaskCount,
        state.mCurrCount,
        state.mStarted,
        state.mFinished,
        correct,
        state.mQuestioning,
        state.mStartTime,
        state.mEndTime,
        state.mKeyBoardLayout,
        state.mDatabit));
  }

  void updateQuestioning() {
    if (!state.mFinished) {
      if (state.mQuestioning == false) {
        emit(TestController(
            state.mTaskCount,
            state.mCurrCount + 1,
            state.mStarted,
            state.mFinished,
            state.mCorrect,
            !state.mQuestioning,
            DateTime.now(),
            state.mEndTime,
            state.mKeyBoardLayout,
            state.mDatabit));
      } else {
        emit(TestController(
            state.mTaskCount,
            state.mCurrCount,
            state.mStarted,
            state.mFinished,
            state.mCorrect,
            !state.mQuestioning,
            state.mStartTime,
            DateTime.now(),
            state.mKeyBoardLayout,
            state.mDatabit));
      }
    }
  }

  Future<void> startQuestion() async {
    int currentQuestion = state.mCurrCount;
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    if (state.mQuestioning &&
        currentQuestion == state.mCurrCount &&
        !state.mFinished) {
      updateCorrect(false);
      updateQuestioning();
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
      updateQuestioning();
    }
  }
}

class TaskState {
  final BuildContext context;
  const TaskState({required this.context});
}

class TaskCubit extends Cubit<TaskState> {
  TaskCubit(BuildContext context) : super(TaskState(context: context));
  late TestControllerCubit controllerCubit;
  late TestObjectCubit objCubit;
  late CsvTrackerCubit csvCubit;

  StreamSubscription<TestController>? _controllerSub;
  bool questionOn = false;

  void init() {
    controllerCubit = state.context.read<TestControllerCubit>();
    objCubit = state.context.read<TestObjectCubit>();
    csvCubit = state.context.read<CsvTrackerCubit>();
    bool outputted = false;

    _controllerSub = controllerCubit.stream.listen((controllerState) {
      if (controllerState.mFinished) {
        if (outputted == false) {
          if (controllerState.mDatabit) {
            csvCubit.state.writeOutData();
          }
          outputted = true;
        }
      } else if (controllerState.mQuestioning) {
        objCubit.update();
        controllerCubit.startQuestion();
      } else if (!controllerState.mQuestioning) {
        if (controllerState.mCurrCount >= controllerState.mTaskCount) {
          updateData();
          controllerCubit.updateFinished();
        } else {
          updateData();
        }
      } else if (controllerState.mCurrCount == controllerState.mTaskCount) {
        controllerCubit.updateQuestioning();
      }
    });
  }

  void processKeyEvent(LogicalKeyboardKey key) {
    if (controllerCubit.state.mQuestioning) {
      for (int i = 0; i < 5; i++) {
        if (key == keys[i]) {
          if (objCubit.state.mType != 0 &&
              objCubit.state.mWord ==
                  words[controllerCubit.state.mKeyBoardLayout.indexOf(i)]) {
            controllerCubit.updateCorrect(true);
            controllerCubit.updateQuestioning();
          } else if (objCubit.state.mType == 0 &&
              objCubit.state.mColor ==
                  colors[controllerCubit.state.mKeyBoardLayout.indexOf(i)]) {
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
    _controllerSub
        ?.cancel(); // Cancel the subscription to prevent memory leaks.
    return super.close();
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 191, 208, 220),
        centerTitle: true,
        // Add the logo in the leading property
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Stroop Task Program'),
            const Text(
              'Neurotech USC BCI Project 2025',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          return Row(
            //////////////////////////////////////////
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlocBuilder<TestControllerCubit, TestController>(
                  builder: (context, state) {
                return Column(
                  //////////////////////////////////////////
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BlocBuilder<TestObjectCubit, TestObjectState>(
                      builder: (context, state) {
                        return Column(
                          //////////////////////////////////////////
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BlocProvider.of<TestControllerCubit>(context)
                                    .state
                                    .mFinished
                                ? _endOutput()
                                : !BlocProvider.of<TestControllerCubit>(context)
                                        .state
                                        .mStarted
                                    ? InputOnStart()
                                    : // ADD INPUT WIDGET HERE
                                    InputOnTask(),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _endOutput() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          'Tests Finished!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 60,
            color: Color.fromARGB(255, 30, 204, 186),
          ),
        ),
        SizedBox(height: 30),
        Text(
          'Data saved to:',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'stroop_test_$testStamp.csv',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            color: Color.fromARGB(255, 30, 204, 186),
          ),
        ),
      ])
    ]);
  }
}

class InputOnStart extends StatefulWidget {
  const InputOnStart({super.key});

  @override
  State<InputOnStart> createState() => _InputOnStartState();
}

class _InputOnStartState extends State<InputOnStart> {
  final TextEditingController _numtec = TextEditingController();
  final TextEditingController _codetec = TextEditingController();
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
    _numtec.dispose();
    _codetec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerCubit = context.read<TestControllerCubit>();
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
          Text(
            'Base number of trials is 100',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 30,
                width: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _numtec,
                  textAlign: TextAlign.center, // This centers the text
                  style: const TextStyle(fontSize: 15.0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter Number of Trials Here',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 30,
                width: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.black),
                ),
                child: TextField(
                  controller: _codetec,
                  textAlign: TextAlign.center, // This centers the text
                  style: const TextStyle(fontSize: 15.0),
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter Data Code',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Text(
                    '${keyStrings[controllerCubit.state.mKeyBoardLayout[index]]}: ${words[index]}',
                    style: TextStyle(
                        color: colors[index],
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0),
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 30),
          RandomKeysWidget(),
          SizedBox(height: 20),
          Text(
            'Press the Spacebar to Start',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTask() async {
    setState(() => _showWait = true);
    // Parse the text as an integer (default to 100 if invalid)
    final enteredNumber = int.tryParse(_numtec.text) ?? 100;
    final String enteredCode = _codetec.text.trim();
    final controllerCubit = context.read<TestControllerCubit>();
    // Wait 3 seconds
    await Future.delayed(const Duration(seconds: 1));
    setState(() => counter--);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => counter--);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => counter--);
    if (enteredCode == "FATIGUE") {
      controllerCubit.initStroop(enteredNumber, true);
    } else {
      controllerCubit.initStroop(enteredNumber, false);
    }
    controllerCubit.updateQuestioning();
    // Return to the input form (or navigate, based on your app logic)
    setState(() => _showWait = false);
  }
}

class RandomKeysWidget extends StatefulWidget {
  const RandomKeysWidget({super.key});

  @override
  RandomKeysWidgetState createState() => RandomKeysWidgetState();
}

class RandomKeysWidgetState extends State<RandomKeysWidget> {
  bool _isRevealed = false;

  void _toggleReveal() {
    setState(() {
      _isRevealed = !_isRevealed;
      final controllerCubit = context.read<TestControllerCubit>();
      controllerCubit.initKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleReveal,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
            child: Text(
          'Click to Randomized Keyboard Inputs',
          style: TextStyle(fontSize: 17.0),
        )),
      ),
    );
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
        if (BlocProvider.of<TestControllerCubit>(context).state.mQuestioning) {
          for (int i = 0; i < 5; i++) {
            if (!_showWait) {
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
          BlocProvider.of<TestControllerCubit>(context).state.mQuestioning
              ? _buildTestObjectView(
                  BlocProvider.of<TestObjectCubit>(context).state)
              : BlocProvider.of<TestControllerCubit>(context).state.mCorrect
                  ? _responseOutput(true)
                  : _responseOutput(false),
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

  Widget _buildBoxTask(Color color) {
    return Container(
      width: 100,
      height: 100,
      color: color,
    );
  }

  Widget _buildTextTask(Color color, String word, bool colored) {
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

  Widget _responseOutput(bool correct) {
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
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    controllerCubit.updateQuestioning();
    setState(() => _showWait = false);
  }
}
