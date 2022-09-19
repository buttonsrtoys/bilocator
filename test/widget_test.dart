import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';

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
  required bool inherited,
  required bool listen,
}) =>
    MaterialApp(
      home: Registrar(
        builder: () => MyModel(),
        location: inherited ? Location.tree : Location.registry,
        child: MyObserverWidget(inherited: inherited, listen: listen),
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
    required this.inherited,
    required this.listen,
  });

  final bool inherited;
  final bool listen;

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
    return widget.inherited ? context.get<MyModel>() : Registrar.get<MyModel>();
 }

  MyModel listenToModel(BuildContext context) {
    return widget.inherited ? context.of<MyModel>() : listenTo<MyModel>(listener: () => setState(() {}));
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
  setUp(() {
  });

  tearDown(() {
    /// Ensure no residuals
    expect(Registrar.isRegistered<MyModel>(), false);
    expect(numberOfModelsThatNeedDispose, 0);
  });

  group('MyTestWidget', () {
    testWidgets('not listening to registered Registrar does not rebuild widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(inherited: false, listen: false));

      expect(Registrar.isRegistered<MyModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to registered Registrar rebuilds widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(inherited: false, listen: true));

      expect(Registrar.isRegistered<MyModel>(), true);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('not listening to inherited Registrar does not rebuild widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(inherited: true, listen: false));

      expect(Registrar.isRegistered<MyModel>(), false);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('$_number'), findsOneWidget);
    });

    testWidgets('listening to inherited Registrar rebuilds widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(inherited: true, listen: true));

      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });

    testWidgets('register and unregister inherited model', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(inherited: true, listen: true));

      expect(Registrar.isRegistered<MyModel>(), false);
      expect(find.text('$_number'), findsOneWidget);

      await tester.tap(find.text(_registerButtonText));
      await tester.pump();

      expect(Registrar.isRegistered<MyModel>(), true);

      await tester.tap(find.text(_incrementButtonText));
      await tester.pump();

      expect(find.text('${_number + 1}'), findsOneWidget);
    });
  });
}
