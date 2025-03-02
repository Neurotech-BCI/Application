import 'stroop_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animations/animations.dart';

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
    return Scaffold(
        body: Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset('assets/ApplicationBackground.svg',
              fit: BoxFit.cover),
        ),
        Center(child: SvgPicture.asset('assets/LogoCard.svg')),
        Container(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
              width: 100,
              height: 50,
              child: OpenContainer(
                transitionDuration: Duration(milliseconds: 500),
                transitionType: ContainerTransitionType.fadeThrough,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                closedElevation: 6.0,
                openBuilder: (BuildContext context, VoidCallback _) {
                  return StroopTask();
                },
                closedBuilder:
                    (BuildContext context, VoidCallback openContainer) {
                  // The closed state shows a FloatingActionButton.
                  return GestureDetector(
                    onTap: openContainer,
                    child: Container(
                      width: 56.0,
                      height: 56.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        color: Colors.purple[200],
                      ),
                      child: Text("Stroop Task"),
                    ),
                  );
                },
              )),
        )
      ],
    ));
  }
}
