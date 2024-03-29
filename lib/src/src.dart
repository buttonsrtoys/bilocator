import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

typedef Filter = String? Function(List<String?>);

enum Location {
  registry,
  tree,
}

/// A widget that locates a single service in a registry or an inherited model in the widget tree.
///
/// [builder] builds the [T].
/// [name] is a unique name key and only needed when more than one instance is registered of the same type.
/// If object is ChangeNotifier, [dispose] determines if dispose function is called. If object is not a
/// ChangeNotifier then the value of [dispose] is ignored.
/// [child] is the child widget.
/// [location] is where to store the model. Set to [Location.tree] to store the model as an inherited model on the
/// widget tree, which internally uses an InheritedWidget. Set to [Location.registry] to store the model as a single
/// service in a registry. Single services in the registry are accessible from any branch of the widget tree but can
/// only have one instance of a given type [T] and [name]. Inherited models can have unlimited instances of type [T]
/// but are only accessible by descendants. See [context.get], [Observer.get], and [Observer.listenTo] for accessing
/// single services and inherited models.
///
/// Bilocator also manages ChangeNotifiers. If [T] is of type ChangeNotifier then a listener is added to the build
/// ChangeNotifier that rebuilds this Bilocator widget when [ChangeNotifier.notifyListeners] is called. Also, its
/// [ChangeNotifier.dispose] is called when it is unregistered.
///
/// The lifecycle of the [T] object is bound to this widget, regardless of whether [location] is [Location.tree]
/// or [Location.registry].
class Bilocator<T extends Object> extends StatefulWidget {
  Bilocator({
    required this.builder,
    this.name,
    this.location = Location.registry,
    this.dispose = true,
    super.key,
    required this.child,
  }) : assert(T != Object, _missingGenericError('constructor Bilocator', 'Object'));
  final T Function()? builder;
  final String? name;
  final bool dispose;
  final Location location;
  final Widget child;

  @override
  State<Bilocator<T>> createState() => _BilocatorState<T>();

  /// Register an [Object] for retrieving with [Bilocator.get]
  ///
  /// [Bilocator] and [Bilocators] automatically call [register] and [unregister] so this function
  /// is not typically used. It is only used to manually register or unregister an [Object]. E.g., if
  /// you could register/unregister a [ValueNotifier].
  static void register<T extends Object>({T? instance, T Function()? builder, String? name}) {
    if (Bilocator.isRegistered<T>(name: name)) {
      throw Exception(
        'Bilocator tried to register an instance of type $T with name $name but it is already registered. Possible '
        'causes:\n'
        ' - Data was stored in the widget tree using the parameter `location: Location.tree` but the registry was '
        'searched instead. This can be fixed by searching the widget tree with a BuildContext or my storing the data '
        'in the registry using `Location.registry`\n'
        ' - If this exception occurred during a hot reload and a hot restart fixes problem, the issue is likely that '
        'the same bilocator is trying to re-register during a hot reload. This can be fixed by assigning the bilocator '
        'a unique key (Bilocator checks whether the data associated with the key is already registered). See the '
        'documentation for the Bilocators class for more information.\n\n',
      );
    }
    _register(type: T, lazyInitializer: _LazyInitializer(builder: builder, instance: instance), name: name);
  }

  /// Register by runtimeType for when compiled type is not available.
  ///
  /// [register] is preferred. However, use when type is not known at compile time (e.g., a super-class is registering a
  /// sub-class).
  ///
  /// [instance] is registered by runtimeType return by [instance.runtimeType]
  /// [name] is a unique name key and only needed when more than one instance is registered of the same type.
  static void registerByRuntimeType({required Object instance, String? name}) {
    final runtimeType = instance.runtimeType;
    if (Bilocator.isRegisteredByRuntimeType(runtimeType: runtimeType, name: name)) {
      throw Exception(
        'Bilocator tried to register an instance of type $runtimeType with name $name but it is already registered.\n',
      );
    }
    _register(type: runtimeType, lazyInitializer: _LazyInitializer(builder: null, instance: instance), name: name);
  }

  /// [type] is not a generic because sometimes runtimeType is required.
  static void _register({
    required Type type,
    required _LazyInitializer lazyInitializer,
    String? name,
  }) {
    assert(type != Object);
    final Type updatedType = type == Object ? lazyInitializer.instance.runtimeType : type;
    if (Bilocator._isRegistered(type: updatedType, name: name)) {
      throw Exception(
          'Bilocator tried to register an object of type $updatedType with name $name but it was already registered. '
          'Only one object with the same type/name can be stored in the registry. Possible solutions:\n'
          '- Give objects of the same type unique names. E.g.,\n'
          '    Bilocator<MyModel>(\n'
          "      name: 'some unique name',\n"
          "      child: Home(),\n"
          "    ),\n");
    }
    if (!_registry.containsKey(updatedType)) {
      _registry[updatedType] = <String?, _RegistryEntry>{};
    }
    _registry[updatedType]![name] = _RegistryEntry(type: updatedType, lazyInitializer: lazyInitializer);
  }

  /// Unregister an [Object] so that it can no longer be retrieved with [Bilocator.get]
  ///
  /// If [T] is a ChangeNotifier then its `dispose()` method is called if [dispose] is true
  static void unregister<T extends Object>({String? name, bool dispose = true}) {
    if (!Bilocator.isRegistered<T>(name: name)) {
      throw Exception(
        'Bilocator tried to unregister an instance of type $T with name $name but it is not registered. Possible '
        'causes:\n'
        ' - Data was stored in the widget tree using `location: Location.tree` so not found in the registry. See the '
        'documentation for Bilocator for more information.\n\n',
      );
    }
    final registryEntry = _unregister(type: T, name: name);
    if (registryEntry != null && dispose) {
      registryEntry.lazyInitializer.dispose();
    }
  }

  /// Unregister by runtimeType for when compiled type is not available.
  ///
  /// [unregister] is preferred. However, use when type is not known at compile time (e.g., a super-class is
  /// unregistering a sub-class).
  ///
  /// [runtimeType] is value return by [Object.runtimeType]
  /// [name] is a unique name key and only needed when more than one instance is registered of the same type. (See
  /// [Bilocator] comments for more information on [dispose]).
  /// If object is a ChangeNotifier, [dispose] determines whether its dispose function is called. Ignored otherwise.
  static void unregisterByRuntimeType({required Type runtimeType, String? name, bool dispose = true}) {
    if (!Bilocator.isRegisteredByRuntimeType(runtimeType: runtimeType, name: name)) {
      throw Exception(
        'Bilocator tried to unregister an instance of type $runtimeType with name $name but it is not registered.\n',
      );
    }
    final registryEntry = _unregister(type: runtimeType, name: name);
    if (registryEntry != null && dispose) {
      registryEntry.lazyInitializer.dispose();
    }
  }

  /// Unregisters but does not dispose.
  static _RegistryEntry? _unregister({required Type type, String? name}) {
    final registryEntry = _registry[type]!.remove(name);
    if (_registry[type]!.isEmpty) {
      _registry.remove(type);
    }
    return registryEntry;
  }

  /// Determines whether an [Object] is registered and therefore retrievable with [Bilocator.get]
  static bool isRegistered<T extends Object>({String? name}) {
    return _isRegistered(type: T, name: name);
  }

  /// Determines whether an [Object] is registered and therefore retrievable with [Bilocator.get]
  static bool _isRegistered({required Type type, required String? name}) {
    assert(type != Object, _missingGenericError('isRegistered', 'Object'));
    return _registry.containsKey(type) && _registry[type]!.containsKey(name);
  }

  /// Determines whether an [Object] is registered and therefore retrievable with [Bilocator.get]
  static bool isRegisteredByRuntimeType({required Type runtimeType, String? name}) {
    return _registry.containsKey(runtimeType) && _registry[runtimeType]!.containsKey(name);
  }

  /// Get a registered [T]
  ///
  /// [name] is the used when locating a single service but not an inherited model.
  /// [filter] is a custom function that receives a list of the names of all the registered objects of type [T] and
  /// returns a String? that specifies which name to select. For example, if the registry contained objects of type
  /// `BookPage` with names "Page 3", "Page 4", and "Page 5", and you wanted to get the first one found:
  ///
  ///     final BookPage firstLetter = Bilocator.get<GreekLetter>(filter: (pageNames) => pageNames[0]);
  ///
  static T get<T extends Object>({String? name, Filter? filter}) {
    assert(name == null || filter == null, 'Bilocator.get failed. `name` or `filter` cannot both be non-null.');
    final String? updatedName;
    if (filter == null) {
      updatedName = name;
      if (!Bilocator.isRegistered<T>(name: name)) {
        throw Exception(
          'Bilocator tried to get an instance of type $T with name $name but it is not registered. Possible causes:\n'
          ' - Data was stored in the widget tree using `location: Location.tree` so not found in the registry. See the '
          'documentation for Bilocator for more information.\n\n',
        );
      }
    } else {
      if (_registry[T] == null) {
        throw Exception(
          'Bilocator tried to get an instance of type $T none are registered. Possible causes:\n'
          ' - Data was stored in the widget tree using `location: Location.tree` so not found in the registry. See the '
          'documentation for Bilocator for more information.\n\n',
        );
      }
      updatedName = filter(_registry[T]!.keys.toList());
    }
    return _registry[T]![updatedName]!.lazyInitializer.instance as T;
  }
}

class _BilocatorState<T extends Object> extends State<Bilocator<T>> with BilocatorStateImpl<T> {
  ChangeNotifier? changeNotifier;
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    initStateImpl(
      location: widget.location,
      builder: widget.builder,
      name: widget.name,
      onInitialization: (object) {
        if (object is ChangeNotifier) {
          changeNotifier = object;
          object.addListener(update);
        }
      },
    );
  }

  @override
  void dispose() {
    if (changeNotifier != null) {
      changeNotifier!.removeListener(update);
    }
    disposeImpl(location: widget.location, name: widget.name, dispose: widget.dispose);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildImpl(location: widget.location, child: widget.child);
  }
}

/// Implements the State class of [Bilocator]
///
/// This was implemented as a mixin so it could be consumed by other packages. E.g.,
/// [mvvm_plus](https://pub.dev/packages/mvvm_plus) consumes it.
mixin BilocatorStateImpl<T extends Object> {
  late final _LazyInitializer<T> _lazyInitializer;
  final isRegisteredInheritedModel = _IsRegisteredInheritedModel();

  void initStateImpl({
    required Location? location,
    String? name,
    T Function()? builder,
    T? instance,
    void Function(T)? onInitialization,
  }) {
    _lazyInitializer = _LazyInitializer<T>(builder: builder, instance: instance, onInitialization: onInitialization);
    if (location == Location.registry) {
      Bilocator._register(type: T, lazyInitializer: _lazyInitializer, name: name);
    }
  }

  void disposeImpl({
    required Location? location,
    String? name,
    required bool dispose,
  }) {
    if (location == Location.registry || isRegisteredInheritedModel.value) {
      Bilocator.unregister<T>(name: name, dispose: false);
    }
    if (dispose) {
      _lazyInitializer.dispose();
    }
  }

  Widget buildImpl({required Location? location, required Widget child}) {
    if (location == Location.tree) {
      return _BilocatorInheritedWidget<T>(
        lazyInitializer: _lazyInitializer,
        registered: isRegisteredInheritedModel,
        child: child,
      );
    } else {
      return child;
    }
  }
}

/// Adds [get] and [of] features to BuildContext.
extension BilocatorBuildContextExtension on BuildContext {
  _BilocatorInheritedWidget<T> _getInheritedWidget<T extends Object>() {
    final inheritedElement = getElementForInheritedWidgetOfExactType<_BilocatorInheritedWidget<T>>();
    if (inheritedElement == null) {
      throw Exception('No inherited Bilocator widget found with type $T. Possible causes:\n'
          ' - The data was stored in the registry using `location: Location.registry` but searched for in the widget tree. '
          'To search the registry, do not use BuildContext.\n\n');
    }
    return inheritedElement.widget as _BilocatorInheritedWidget<T>;
  }

  /// Searches for a [Bilocator] widget with [location] param set and a model of type [T].
  ///
  /// usage:
  ///
  ///     final myService = context.get<MyService>();
  ///
  /// The search is for the first match up the widget tree from the calling widget.
  /// This does not set up a dependency between the InheritedWidget and the context. For that, use [of].
  /// Performs a lazy initialization if necessary. Throws exception of widget not found.
  /// For those familiar with Provider, [get] is effectively `Provider.of<MyModel>(listen: false);`.
  T get<T extends Object>() {
    final inheritedWidget = _getInheritedWidget<T>();
    return inheritedWidget.instance;
  }

  /// Create a dependency between the calling widget and a [Bilocator] widget with generic type [T].
  ///
  /// Same idea as the "of" feature of Provider.of, Theme.of, etc. For no dependency, use [get].
  /// Performs a lazy initialization if necessary. An exception is thrown if [T] is not a [ChangeNotifier].
  /// or the not match found.
  T of<T extends ChangeNotifier>() {
    final _BilocatorInheritedWidget<T>? inheritedWidget =
        dependOnInheritedWidgetOfExactType<_BilocatorInheritedWidget<T>>();
    if (inheritedWidget == null) {
      throw Exception('BuildContext.of<T>() did not find inherited widget Bilocator<$T>(). Possible causes:\n'
          ' - The data was stored in the registry instead of the widget tree. To search the registry, do not use '
          'BuildContext.\n\n');
    }
    return inheritedWidget.instance;
  }
}

/// Manages lazy initialization.
class _LazyInitializer<T extends Object> {
  /// Can receive a builder or an instance but not both.
  ///
  /// [_builder] builds the instance. In cases where object is already initialized, pass [_instance].
  /// [onInitialization] is called after the call to [_builder].
  _LazyInitializer({required T Function()? builder, required T? instance, this.onInitialization})
      : assert(builder == null ? instance != null : instance == null,
            '_LazyInitializer constructor can only receive the builder parameter or the instance parameter.'),
        _builder = builder,
        _instance = instance;

  final T Function()? _builder;
  T? _instance;
  final void Function(T)? onInitialization;
  bool get hasInitialized => _instance != null;

  T get instance {
    if (_instance == null) {
      _instance = _builder!();
      if (onInitialization != null) {
        onInitialization!(_instance!);
      }
    }
    return _instance!;
  }

  void dispose() {
    if (hasInitialized && instance is ChangeNotifier) {
      (instance as ChangeNotifier).dispose();
    }
  }
}

/// Optional InheritedWidget class.
///
/// updateShouldNotify always returns true, so all dependent children build when
/// If [T] is a ChangeNotifier, [changeNotifierListener] is added a listener. Typically, this listener just calls setState to
/// rebuild.
class _BilocatorInheritedWidget<T extends Object> extends InheritedWidget {
  const _BilocatorInheritedWidget({
    Key? key,
    required this.lazyInitializer,
    required this.registered,
    required Widget child,
  }) : super(key: key, child: child);

  final _LazyInitializer<T> lazyInitializer;
  final _IsRegisteredInheritedModel registered;

  T get instance => lazyInitializer.instance;

  @override
  bool updateShouldNotify(_BilocatorInheritedWidget oldWidget) => true;
}

/// final wrapper for registered inherited models.
class _IsRegisteredInheritedModel {
  bool value = false;
}

/// Manages a unique list of keys and throws if the same key is added twice.
class _UniqueKeysManager {
  static final _keys = <Key>{};
  void add(Key key) {
    if (_keys.contains(key)) {
      throw Exception('A Bilocators constructor was call with a key that was already registered. Possible causes:\n'
          ' - Two Bilocators instances use the same key. Keys for Bilocators must be unique.\n'
          ' - The same Bilocator tried to re-register during a hot reload. This is fixed by giving the Bilocators '
          'instance a unique key. See the Bilocators documentation for more information.\n\n');
    } else {
      _keys.add(key);
    }
  }

  bool contains(Key key) => _keys.contains(key);
  bool remove(Key key) => _keys.remove(key);
}

final _uniqueKeysManager = _UniqueKeysManager();

/// Register multiple Objects so they can be retrieved with [Bilocator.get]
///
/// [Bilocators] only uses [Location.registry] and does not add widget to the widget try per [Location.tree].
///
/// Under certain conditions, [Bilocators] can attempt to re-register deligates on a hot reload which will throw an
/// exception. Assigning a repeatable key prevents this, as Bilocator uses the key to check if it has already
/// registered. E.g.,
///
///     Bilocators(
///       key: ValueKey('services'),
///       delegates: [],
///     }
///
/// The lifecycle of each Object is bound to this widget. Each object is registered when this widget is added to the
/// widget tree and unregistered when removed. If an Object is of type ChangeNotifier then its
/// ChangeNotifier.dispose when it is unregistered.
///
/// usage:
///   Bilocators(
///     delegates: [
///       BilocatorDelegate<MyService>(builder: () => MyService()),
///       BilocatorDelegate<MyOtherService>(builder: () => MyOtherService()),
///     ],
///     child: MyWidget(),
///   );
///
class Bilocators extends StatefulWidget {
  Bilocators({
    required this.delegates,
    required this.child,
    super.key,
  }) {
    if (key == null || !_uniqueKeysManager.contains(key!)) {
      if (key != null) {
        _uniqueKeysManager.add(key!);
      }
      for (final delegate in delegates) {
        delegate._register();
      }
    }
  }

  final List<BilocatorDelegate> delegates;
  final Widget child;

  @override
  State<Bilocators> createState() => _BilocatorsState();
}

class _BilocatorsState extends State<Bilocators> {
  @override
  void dispose() {
    if (widget.key != null && _uniqueKeysManager.contains(widget.key!)) {
      _uniqueKeysManager.remove(widget.key!);
    }
    for (final delegate in widget.delegates) {
      delegate._unregister();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Delegate for [Bilocator]. See [Bilocators] for more information.
///
/// [builder] builds the [Object].
/// [instance] is an instance of [T]
/// [name] is a unique name key and only needed when more than one instance is registered of the same type.
/// If object is a ChangeNotifier, [dispose] determines whether its dispose function is called. (See
/// [Bilocator] comments for more information on [dispose]).
///
/// See [Bilocator] for the difference between using [builder] and [instance]
class BilocatorDelegate<T extends Object> {
  BilocatorDelegate({
    this.builder,
    this.instance,
    this.name,
    this.dispose = true,
  }) : assert(T != Object, _missingGenericError('constructor BilocatorDelegate', 'Object'));

  final T Function()? builder;
  final String? name;
  final T? instance;
  final bool dispose;

  void _register() {
    Bilocator.register<T>(instance: instance, builder: builder, name: name);
  }

  void _unregister() {
    Bilocator.unregister<T>(name: name, dispose: dispose);
  }
}

/// A lazy registry entry
///
/// [instance] is a value of type [T]
/// [builder] is a function that builds [instance]
/// [type] is not a generic because something need to determine at runtime (e.g., runtimeType).
///
/// The constructor can receive either [instance] or [builder] but not both. Passing [builder] is recommended as it
/// makes the implementation lazy. I.e., [builder] is executed on the first get.
class _RegistryEntry {
  _RegistryEntry({
    required Type type,
    required this.lazyInitializer,
  }) : assert(type != Object, _missingGenericError('constructor _BilocatorEntry', 'Object'));

  final _LazyInitializer lazyInitializer;
}

/// Implements observer pattern.
mixin Observer {
  final _subscriptions = <_Subscription>[];

  /// Locates a single service or inherited model and adds a listener ('subscribes') to it.
  ///
  /// The located object must be a ChangeNotifier.
  ///
  /// If [context] is passed, the ChangeNotifier is located on the widget tree. If the ChangeNotifier is already
  /// located, you can pass it to [notifier]. If [context] and [notifier] are null, a registered ChangeNotifier is
  /// located with type [T] and [name], where [name] is the optional name assigned to the ChangeNotifier when it was
  /// registered.
  ///
  /// [filter] is a custom function that receives a list of the names of all the registered objects of type [T] and
  /// returns a String? that specifies which name to select. For example, if the registry contained objects of type
  /// `BookPage` with names "Page 3", "Page 4", and "Page 5", and you wanted to get the first one found:
  ///
  ///     final BookPage firstLetter = Bilocator.get<GreekLetter>(filter: (pageNames) => pageNames[0]);
  ///
  /// A common use case for passing [notifier] is using [get] to retrieve a registered object and listening to one of
  /// its ValueNotifiers:
  ///
  ///     // Get (but don't listen to) an object
  ///     final cloudService = get<CloudService>();
  ///
  ///     // listen to one of its ValueNotifiers
  ///     final user = listenTo<ValueNotifier<User>>(notifier: cloudService.currentUser).value;
  ///
  /// [listener] is the listener to be added. A check is made to ensure the [listener] is only added once.
  ///
  /// StatefulWidget example:
  ///
  ///    class MyWidget extends StatefulWidget {
  ///      const MyWidget({Key? key}) : super(key: key);
  ///      @override
  ///      State<MyWidget> createState() => _MyWidgetState();
  ///    }
  ///
  ///    class _MyWidgetState extends State<MyWidget> with Observable {     // <- with Observable
  ///      @override
  ///      Widget build(BuildContext context) {
  ///        final text = listenTo<MyService>(context: context).text;       // <- listenTo
  ///        return Text(text);
  ///      }
  ///    }
  ///
  @protected
  T listenTo<T extends ChangeNotifier>({
    BuildContext? context,
    T? notifier,
    String? name,
    Filter? filter,
    required void Function() listener,
  }) {
    assert(toOne(context) + toOne(notifier) + toOne(name) <= 1,
        'listenTo can only receive non-null for "context", "notifier", or "name" but not two or more can be non-null.');
    final notifierInstance =
        context == null ? notifier ?? Bilocator.get<T>(name: name, filter: filter) : context.get<T>();
    final subscription = _Subscription(changeNotifier: notifierInstance, listener: listener);
    if (!_subscriptions.contains(subscription)) {
      subscription.subscribe();
      _subscriptions.add(subscription);
    }
    return notifierInstance;
  }

  /// Gets (but does not listen to) a single service or inherited widget.
  ///
  /// If [context] is null, gets a single service from the registry.
  /// If [context] is non-null, gets an inherited model from an ancestor located by context.
  /// [name] is the used when locating a single service but not an inherited model.
  /// [filter] is a custom function that receives a list of the names of all the registered objects of type [T] and
  /// returns a String? that specifies which name to select. For example, if the registry contained objects of type
  /// `BookPage` with names "Page 3", "Page 4", and "Page 5", and you wanted to get the first one found:
  ///
  ///     final BookPage firstLetter = Bilocator.get<GreekLetter>(filter: (pageNames) => pageNames[0]);
  ///
  T get<T extends Object>({BuildContext? context, String? name, Filter? filter}) {
    assert(context == null || name == null,
        '"get" was passed a non-null value for "name" but cannot locate an inherited model by name.');
    if (context == null) {
      return Bilocator.get<T>(name: name, filter: filter);
    } else {
      return context.get<T>();
    }
  }

  /// Registers an inherited object.
  ///
  /// [register] is a handy but rarely needed function. Bilocator(location: Location.tree) widgets are accessible from their
  /// descendants only. Occasionally, access is required by a widget that is not a descendant. In such cases, you can
  /// make the inherited model globally available by registering it.
  /// [name] is assigned to the registered model. [name] is NOT used for locating the object.
  ///
  /// Registered inherited models are unregister when their corresponding Bilocator widget is disposed.
  void register<T extends Object>(BuildContext context, {String? name}) {
    context._getInheritedWidget<T>().registered.value = true;
    Bilocator.register<T>(instance: context.get<T>(), name: name);
  }

  /// Unregisters models registered with [Observer.register].
  ///
  /// [name] is the value given when registering. Note that unlike [Bilocator.unregister] this function does not call
  /// the dispose function of the object if it is a ChangeNotifier because it is unregistering an instance that still
  /// exists in the widget tree. I.e., it was created with Bilocator(location: Location.tree).
  void unregister<T extends Object>(BuildContext context, {String? name}) {
    context._getInheritedWidget<T>().registered.value = false;
    Bilocator.unregister<T>(name: name, dispose: false);
  }

  /// Cancel all listener subscriptions.
  ///
  /// Note that subscriptions are not automatically managed. E.g., [cancelSubscriptions] is not called when this class is
  /// disposed. Instead, [cancelSubscriptions] is typically called from a dispose function of a ChangeNotifier or
  /// StatefulWidget.
  void cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    _subscriptions.clear();
  }
}

/// Returns 1 if non null, 0 if null. Typically used for counting non-nulls. E.g., assert(toOne(a) + toOne(b) == 1)
int toOne(Object? object) {
  return object == null ? 0 : 1;
}

/// Manages a listener that subscribes to a ChangeNotifier
class _Subscription extends Equatable {
  const _Subscription({required this.changeNotifier, required this.listener});

  final void Function() listener;
  final ChangeNotifier changeNotifier;

  void subscribe() => changeNotifier.addListener(listener);

  void unsubscribe() => changeNotifier.removeListener(listener);

  @override
  List<Object?> get props => [changeNotifier, listener];
}

final _registry = <Type, Map<String?, _RegistryEntry>>{};

String _missingGenericError(String function, String type) =>
    'Missing generic. The function "$function" was called without a custom subclass generic. Did you call '
    '"$function(..)" instead of "$function<$type>(..)"?';
