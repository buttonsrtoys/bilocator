import 'package:bilocator/src/src.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

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
      expect(Bilocator.isRegistered<MyModel>(), false);
      Bilocator.register<MyModel>(instance: MyModel());
      expect(Bilocator.isRegistered<MyModel>(), true);
      expect(Bilocator.get<MyModel>().answer, 42);
      GetIt.I.unregister<MyModel>();
      expect(Bilocator.isRegistered<MyModel>(), false);
      expect(() => Bilocator.get<MyModel>(), throwsA(isA<Exception>()));
    });

    test('named model instance', () {
      String name = 'Some name';
      expect(Bilocator.isRegistered<MyModel>(), false);
      Bilocator.register<MyModel>(instance: MyModel(), name: name);
      expect(Bilocator.isRegistered<MyModel>(), false);
      expect(Bilocator.isRegistered<MyModel>(name: name), true);
      expect(Bilocator.get<MyModel>(name: name).answer, 42);
      GetIt.I.unregister<MyModel>(instanceName: name);
      expect(Bilocator.isRegistered<MyModel>(), false);
      expect(Bilocator.isRegistered<MyModel>(name: name), false);
      expect(() => Bilocator.get<MyModel>(name: name), throwsA(isA<Exception>()));
    });

    test('unnamed model builder', () {
      Bilocator.register<MyModel>(builder: () => MyModel());
      expect(Bilocator.isRegistered<MyModel>(), true);
      GetIt.I.unregister<MyModel>();
      expect(Bilocator.isRegistered<MyModel>(), false);
    });

    test('named model builder', () {
      String name = 'Some name';
      expect(Bilocator.isRegistered<MyModel>(), false);
      Bilocator.register<MyModel>(builder: () => MyModel(), name: name);
      expect(Bilocator.isRegistered<MyModel>(), false);
      expect(Bilocator.isRegistered<MyModel>(name: name), true);
      GetIt.I.unregister<MyModel>(instanceName: name);
      expect(Bilocator.isRegistered<MyModel>(name: name), false);
    });
  });

  group('ChangeNotifier', () {
    test('dispose called', () {
      bool disposeCalled = false;
      Bilocator.register<MyChangeNotifier>(instance: MyChangeNotifier(() => disposeCalled = true));
      expect(Bilocator.isRegistered<MyChangeNotifier>(), true);
      Bilocator.get<MyChangeNotifier>();
      GetIt.I.unregister<MyChangeNotifier>();
      expect(disposeCalled, true);
    });

    test('dispose not called', () {
      bool disposeCalled = false;
      Bilocator.register<MyChangeNotifier>(instance: MyChangeNotifier(() => disposeCalled = true));
      expect(Bilocator.isRegistered<MyChangeNotifier>(), true);
      GetIt.I.unregister<MyChangeNotifier>(disposingFunction: null);
      expect(disposeCalled, false);
    });
  });
}
