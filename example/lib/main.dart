import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bilocator/bilocator.dart';

void main() => runApp(myApp());

Widget myApp() => MaterialApp(
        home: Bilocators(
            delegates: [
          BilocatorDelegate<RandomService>(builder: () => RandomService()),
          BilocatorDelegate<ColorNotifier>(builder: () => ColorNotifier()),
        ],
            child: Bilocator(
              builder: () => Counter(),
              location: Location.tree,
              child: const Page(),
            )));

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> with Observer {
  @override
  void initState() {
    super.initState();
    get<ColorNotifier>().addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    get<ColorNotifier>().removeListener(() => setState(() {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(context.of<Counter>().count.toString(),
              style:
                  TextStyle(fontSize: 64, color: listenTo<ColorNotifier>(listener: () => setState(() {})).color.value)),
          OutlinedButton(
              onPressed: () => context.of<Counter>().count = get<RandomService>().number,
              child: const Text('Set Random')),
          OutlinedButton(
            onPressed: () => context.of<Counter>().count = 0,
            child: const Text('Clear'),
          ),
        ])),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.of<Counter>().count++,
          child: const Icon(Icons.add),
        ));
  }
}

class Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  set count(int value) {
    _count = value;
    notifyListeners();
  }
}

class ColorNotifier extends ChangeNotifier {
  int _counter = 0;
  late final color = ValueNotifier<Color>(Colors.black)..addListener(notifyListeners);

  ColorNotifier() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
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

class RandomService {
  int get number => Random().nextInt(100);
}
