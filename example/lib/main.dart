import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bilocator/bilocator.dart';

void main() => runApp(myApp());

Widget myApp() => MaterialApp(
        home: Bilocators(delegates: [
      BilocatorDelegate<RandomService>(builder: () => RandomService()),
      BilocatorDelegate<ColorNotifier>(builder: () => ColorNotifier()),
    ], child: const Page()));

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> with Observer {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    Bilocator.get<ColorNotifier>().addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    Bilocator.get<ColorNotifier>().removeListener(() => setState(() {}));
    super.dispose();
  }

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return Bilocator<FortyTwoService>(
        location: Location.tree,
        builder: () => FortyTwoService(),
        child: Scaffold(
            body: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$_counter',
                  style: TextStyle(
                      fontSize: 64, color: listenTo<ColorNotifier>(listener: () => setState(() {})).color.value)),
              OutlinedButton(
                  onPressed: () => setState(() => _counter = Bilocator.get<RandomService>().number),
                  child: const Text('Set Random (with context.get)')),
              Builder(
                  builder: (context) => OutlinedButton(
                      onPressed: () => _counter = context.of<FortyTwoService>().number,
                      child: const Text('Set 42 (with context.of)'))),
            ])),
            floatingActionButton: FloatingActionButton(
              onPressed: _incrementCounter,
              child: const Icon(Icons.add),
            )));
  }
}

class ColorNotifier extends ChangeNotifier {
  int _counter = 0;
  late final color = ValueNotifier<Color>(Colors.black)..addListener(notifyListeners);

  ColorNotifier() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      color.value = <Color>[Colors.orange, Colors.purple, Colors.cyan][++_counter % 3];
    });
  }

  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class FortyTwoService extends ChangeNotifier {
  int get number {
    notifyListeners();
    return 42;
  }
}

class RandomService {
  int get number => Random().nextInt(100);
}
