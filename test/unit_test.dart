import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// These tests used to use Bilocator registry functions but were refactored to use GetIt. So, they're not
/// useful tests, but I'm leaving them for reference.
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
    test('unnamed model throws on register if already registered ', () {
      expect(GetIt.I.isRegistered<MyModel>(), false);
      GetIt.I.registerSingleton<MyModel>(MyModel());
      expect(GetIt.I.isRegistered<MyModel>(), true);
      expect(() => GetIt.I.registerSingleton<MyModel>(MyModel()), throwsA(isA<ArgumentError>()));
      GetIt.I.unregister<MyModel>();
      expect(GetIt.I.isRegistered<MyModel>(), false);
    });

    test('unnamed model instance', () {
      expect(GetIt.I.isRegistered<MyModel>(), false);
      GetIt.I.registerSingleton<MyModel>(MyModel());
      expect(GetIt.I.isRegistered<MyModel>(), true);
      expect(GetIt.I.get<MyModel>().answer, 42);
      GetIt.I.unregister<MyModel>();
      expect(GetIt.I.isRegistered<MyModel>(), false);
      expect(() => GetIt.I.get<MyModel>(), throwsA(isA<StateError>()));
    });

    test('named model instance', () {
      String name = 'Some name';
      expect(GetIt.I.isRegistered<MyModel>(), false);
      GetIt.I.registerSingleton<MyModel>(MyModel(), instanceName: name);
      expect(GetIt.I.isRegistered<MyModel>(), false);
      expect(GetIt.I.isRegistered<MyModel>(instanceName: name), true);
      expect(GetIt.I.get<MyModel>(instanceName: name).answer, 42);
      GetIt.I.unregister<MyModel>(instanceName: name);
      expect(GetIt.I.isRegistered<MyModel>(), false);
      expect(GetIt.I.isRegistered<MyModel>(instanceName: name), false);
      expect(() => GetIt.I.get<MyModel>(instanceName: name), throwsA(isA<StateError>()));
    });

    test('unnamed model builder', () {
      GetIt.I.registerLazySingleton<MyModel>(() => MyModel());
      expect(GetIt.I.isRegistered<MyModel>(), true);
      GetIt.I.unregister<MyModel>();
      expect(GetIt.I.isRegistered<MyModel>(), false);
    });

    test('named model builder', () {
      String name = 'Some name';
      expect(GetIt.I.isRegistered<MyModel>(), false);
      GetIt.I.registerLazySingleton<MyModel>(() => MyModel(), instanceName: name);
      expect(GetIt.I.isRegistered<MyModel>(), false);
      expect(GetIt.I.isRegistered<MyModel>(instanceName: name), true);
      GetIt.I.unregister<MyModel>(instanceName: name);
      expect(GetIt.I.isRegistered<MyModel>(instanceName: name), false);
    });
  });

  group('ChangeNotifier', () {
    test('dispose called', () {
      bool disposeCalled = false;
      final myChangeNotifier = MyChangeNotifier(() => disposeCalled = true);
      GetIt.I.registerSingleton<MyChangeNotifier>(
        myChangeNotifier,
        dispose: (_) => myChangeNotifier.dispose(),
      );
      expect(GetIt.I.isRegistered<MyChangeNotifier>(), true);
      GetIt.I.get<MyChangeNotifier>();
      GetIt.I.unregister<MyChangeNotifier>();
      expect(disposeCalled, true);
    });

    test('dispose not called', () {
      bool disposeCalled = false;
      GetIt.I.registerSingleton<MyChangeNotifier>(MyChangeNotifier(() => disposeCalled = true));
      expect(GetIt.I.isRegistered<MyChangeNotifier>(), true);
      GetIt.I.unregister<MyChangeNotifier>(disposingFunction: null);
      expect(disposeCalled, false);
    });
  });
}
