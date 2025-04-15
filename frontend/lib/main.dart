import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'test_page.dart' as test;
import 'live_page.dart' as live;
import 'connecting.dart';

void main() {
  runApp(const MainApplication());
}

class MainApplication extends StatelessWidget {
  const MainApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeuroTechUSC BCI Application',
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    TextStyle tStyle = TextStyle(
        color: Colors.white, fontFamily: 'Roboto', fontWeight: FontWeight.w900);
    return Scaffold(
        body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset('png_assets/background.png', fit: BoxFit.cover),
        ),
        Center(
            child: Transform.scale(
          alignment: Alignment(-0.5, -1.0),
          scale: 0.85, // 50% of the original size
          child: Image.asset('png_assets/logo.png'),
        )),
        Container(
          padding: EdgeInsets.all(12),
          alignment: Alignment(0.3, .85),
          child: SizedBox(
              width: 120,
              height: 60,
              child: OpenContainer(
                transitionDuration: Duration(milliseconds: 500),
                transitionType: ContainerTransitionType.fadeThrough,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                closedElevation: 6.0,
                openBuilder: (BuildContext context, VoidCallback _) {
                  return BlocProvider(
                    create: (_) => ConnectionControl(),
                    child: live.LivePage(),
                  );
                },
                closedBuilder:
                    (BuildContext context, VoidCallback openContainer) {
                  return GestureDetector(
                    onTap: openContainer,
                    child: Container(
                      width: 112.0,
                      height: 56.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: const Color.fromARGB(255, 219, 162, 229),
                      ),
                      child: Text("Live Recording", style: tStyle),
                    ),
                  );
                },
              )),
        ),
        Container(
          padding: EdgeInsets.all(12),
          alignment: Alignment(-0.3, .85),
          child: SizedBox(
              width: 120,
              height: 60,
              child: OpenContainer(
                transitionDuration: Duration(seconds: 1),
                transitionType: ContainerTransitionType.fadeThrough,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                closedElevation: 6.0,
                openBuilder: (BuildContext context, VoidCallback _) {
                  return BlocProvider(
                    create: (_) => test.PageController()
                      ..update()
                      ..fetchData(),
                    child: test.TestPage(),
                  );
                },
                closedBuilder:
                    (BuildContext context, VoidCallback openContainer) {
                  return GestureDetector(
                    onTap: openContainer,
                    child: Container(
                      width: 112.0,
                      height: 56.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: const Color.fromARGB(255, 228, 180, 90),
                      ),
                      child: Text("Test Recording", style: tStyle),
                    ),
                  );
                },
              )),
        ),
      ],
    ));
  }
}
