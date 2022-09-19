import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/registrar.dart';

class MyModel {
  final answer = 42;
}

class MyChangeNotifier extends ChangeNotifier {
  MyChangeNotifier(this.onDispose);
  final void Function() onDispose;
  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}

void main() {
  group('Object', () {
    test('unnamed model instance', () {
      expect(Registrar.isRegistered<MyModel>(), false);
      Registrar.register<MyModel>(instance: MyModel());
      expect(Registrar.isRegistered<MyModel>(), true);
      expect(Registrar.get<MyModel>().answer, 42);
      Registrar.unregister<MyModel>();
      expect(Registrar.isRegistered<MyModel>(), false);
      expect(() => Registrar.get<MyModel>(), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyModel>(), throwsA(isA<Exception>()));
    });

    test('named model instance', () {
      String name = 'Some name';
      expect(Registrar.isRegistered<MyModel>(), false);
      Registrar.register<MyModel>(instance: MyModel(), name: name);
      expect(Registrar.isRegistered<MyModel>(), false);
      expect(Registrar.isRegistered<MyModel>(name: name), true);
      expect(Registrar.get<MyModel>(name: name).answer, 42);
      Registrar.unregister<MyModel>(name: name);
      expect(Registrar.isRegistered<MyModel>(), false);
      expect(Registrar.isRegistered<MyModel>(name: name), false);
      expect(() => Registrar.get<MyModel>(name: name), throwsA(isA<Exception>()));
      expect(() => Registrar.unregister<MyModel>(name: name), throwsA(isA<Exception>()));
    });

    test('unnamed model builder', () {
      Registrar.register<MyModel>(builder: () => MyModel());
      expect(Registrar.isRegistered<MyModel>(), true);
      Registrar.unregister<MyModel>();
      expect(Registrar.isRegistered<MyModel>(), false);
    });

    test('named model builder', () {
      String name = 'Some name';
      expect(Registrar.isRegistered<MyModel>(), false);
      Registrar.register<MyModel>(builder: () => MyModel(), name: name);
      expect(Registrar.isRegistered<MyModel>(), false);
      expect(Registrar.isRegistered<MyModel>(name: name), true);
      Registrar.unregister<MyModel>(name: name);
      expect(Registrar.isRegistered<MyModel>(name: name), false);
    });
  });

  group('ChangeNotifier', () {
    test('dispose called', () {
      bool disposeCalled = false;
      Registrar.register<MyChangeNotifier>(instance: MyChangeNotifier(() => disposeCalled = true));
      expect(Registrar.isRegistered<MyChangeNotifier>(), true);
      Registrar.unregister<MyChangeNotifier>();
      expect(disposeCalled, true);
    });

    test('dispose not called', () {
      bool disposeCalled = false;
      Registrar.register<MyChangeNotifier>(instance: MyChangeNotifier(() => disposeCalled = true));
      expect(Registrar.isRegistered<MyChangeNotifier>(), true);
      Registrar.unregister<MyChangeNotifier>(dispose: false);
      expect(disposeCalled, false);
    });
  });
}
