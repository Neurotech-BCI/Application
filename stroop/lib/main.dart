import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time/time.dart';
import 'package:csv/csv.dart';

Color red = const Color(0xFFF44336);
Color blue = const Color(0xFF2196F3);
Color green = const Color(0xFF4CAF50);
Color brown = const Color(0xFF795548);
Color purple = const Color(0xFF9C27B0);

List<Color> colors = [red, blue, green, brown, purple];
List<String> words = ['Red', 'Blue', 'Green', 'Brown', 'Purple'];
List<int> types = [0, 1, 2];

// Make a top-level Random instance
final Random randy = Random();

class TestObjectState {
  final Color color;
  final String word;
  final int type;

  const TestObjectState(this.color, this.word, this.type);
}

class TestObjectCubit extends Cubit<TestObjectState> {
  // We no longer try to seed Random here with a non-static field
  TestObjectCubit() : super(TestObjectState(colors[0], words[0], 0));

}

// Now this can use the top-level 'randy'
List<int> generateRandomSequence() {
  return [
    randy.nextInt(5),
    randy.nextInt(5),
    randy.nextInt(3),
  ];
}
void main() 
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget 
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stroop Task',
      home: const MyHomePage(title: 'Stroop Task'),
    );
  }
}

class MyHomePage extends StatelessWidget 
{
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.rectangle,
                ),
              ),
            ]
            )
        ],  
      ),
    );
  }
}