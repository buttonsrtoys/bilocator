import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bilocator/src/src.dart';

const _number = 42;
const _incrementButtonText = 'Increment';
const _registerButtonText = 'Register';
const _unregisterButtonText = 'Unregister';

/// Test app for all widget tests
///
/// [listen] true to listen to [My]
/// [registerViewModel] true to register [MyTestWidgetViewModel]
/// [viewModelName] is option name of registered [MyTestWidgetViewModel]
Widget testApp({
  required Location location,
  required bool listen,
  bool useOf = false,
}) =>
    MaterialApp(
      home: Bilocator(
        location: location,
        builder: () => MyModel(),
        child: MyObserverWidget(location: location, listen: listen, useOf: useOf),
      ),
    );

int numberOfModelsThatNeedDispose = 0;

class MyModel extends ChangeNotifier {
  MyModel() {
    numberOfModelsThatNeedDispose++;
  }

  int number = _number;

  @override
  void dispose() {
    numberOfModelsThatNeedDispose--;
    super.dispose();
  }

  void incrementNumber() {
    number++;
    notifyListeners();
  }
}

/// Widget to show model contents. Its State class uses the Observer mixin.
///
/// Buttons are created that can be tapped by the test to update the model. E.g., a register button registers an
/// inherited model, an increment button increments the counter, etc.
class MyObserverWidget extends StatefulWidget {
  const MyObserverWidget({
    super.key,
    required this.location,
    required this.listen,
    required this.useOf,
  });

  final Location location;
  final bool listen;
  final bool useOf;

  @override
  State<MyObserverWidget> createState() => _MyObserverWidgetState();
}

class _MyObserverWidgetState extends State<MyObserverWidget> with Observer {
  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  MyModel getModel(BuildContext context) {
    return widget.location == Location.tree ? context.get<MyModel>() : Bilocator.get<MyModel>();
  }

  MyModel listenToModel(BuildContext context) {
    if (widget.useOf) {
      return context.of<MyModel>();
    } else {
      return listenTo<MyModel>(
          context: widget.location == Location.tree ? context : null, listener: () => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myModel = widget.listen ? listenToModel(context) : getModel(context);
    return Column(
      children: <Widget>[
        OutlinedButton(onPressed: () => myModel.incrementNumber(), child: const Text(_incrementButtonText)),
        OutlinedButton(onPressed: () => register<MyModel>(context), child: const Text(_registerButtonText)),
        OutlinedButton(onPressed: () => unregister<MyModel>(context), child: const Text(_unregisterButtonText)),
        Text('${myModel.number}'),
      ],
    );
  }
}

void main() {
  setUp(() {});

  tearDown(() {
    /// Ensure no residuals
    expect(Bilocator.isRegistered<MyModel>(), false);
    expect(numberOfModelsThatNeedDispose, 0);
  });

  group('MyTestWidget', () {
    testWidgets('not listening to registered Bilocator does not rebuild widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(location: Location.registry, listen: false));

      expect(Bilocator.isRegistered<MyModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to registered Bilocator rebuilds widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(location: Location.registry, listen: true));

      expect(Bilocator.isRegistered<MyModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('not listening to inherited Bilocator does not rebuild widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(location: Location.tree, listen: false));

      expect(Bilocator.isRegistered<MyModel>(), false);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to inherited Bilocator rebuilds widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(location: Location.tree, listen: true));

      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('register and unregister inherited model', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(location: Location.tree, listen: true));

      expect(Bilocator.isRegistered<MyModel>(), false);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_registerButtonText));
      await tester.pump();

      expect(Bilocator.isRegistered<MyModel>(), true);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('listen to model with ".of"', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(location: Location.tree, listen: true, useOf: true));

      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
