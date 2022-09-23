import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

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
        'Error: Tried to register an instance of type $T with name $name but it is already registered.',
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
        'Error: Tried to register an instance of type $runtimeType with name $name but it is already registered.',
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
    if (!_registry.containsKey(type)) {
      _registry[type] = <String?, _RegistryEntry>{};
    }
    _registry[type]![name] = _RegistryEntry(type: type, lazyInitializer: lazyInitializer);
  }

  /// Unregister an [Object] so that it can no longer be retrieved with [Bilocator.get]
  ///
  /// If [T] is a ChangeNotifier then its `dispose()` method is called if [dispose] is true
  static void unregister<T extends Object>({String? name, bool dispose = true}) {
    if (!Bilocator.isRegistered<T>(name: name)) {
      throw Exception(
        'Error: Tried to unregister an instance of type $T with name $name but it is not registered.',
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
        'Error: Tried to unregister an instance of type $runtimeType with name $name but it is not registered.',
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
    assert(T != Object, _missingGenericError('isRegistered', 'Object'));
    return _registry.containsKey(T) && _registry[T]!.containsKey(name);
  }

  /// Determines whether an [Object] is registered and therefore retrievable with [Bilocator.get]
  static bool isRegisteredByRuntimeType({required Type runtimeType, String? name}) {
    return _registry.containsKey(runtimeType) && _registry[runtimeType]!.containsKey(name);
  }

  /// Get a registered [T]
  static T get<T extends Object>({String? name}) {
    if (!Bilocator.isRegistered<T>(name: name)) {
      throw Exception(
        'Bilocator tried to get an instance of type $T with name $name but it is not registered.',
      );
    }
    return _registry[T]![name]!.lazyInitializer.instance as T;
  }
}

class _BilocatorState<T extends Object> extends State<Bilocator<T>> with BilocatorStateImpl<T> {
  @override
  void initState() {
    super.initState();
    initStateImpl(
      location: widget.location,
      builder: widget.builder,
      name: widget.name,
    );
  }

  @override
  void dispose() {
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
  late _LazyInitializer<T> _lazyInitializer;
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
      throw Exception('No inherited Bilocator widget found with type $T');
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

  /// Create a dependency with a [Bilocator] widget with [location] param set and a model of type [T].
  ///
  /// Same idea as the "of" feature of Provider.of, Theme.of, etc. For no dependency, use [get].
  /// Performs a lazy initialization if necessary. An exception is thrown if [T] is not a [ChangeNotifier].
  T of<T extends ChangeNotifier>() {
    final _BilocatorInheritedWidget<T>? inheritedWidget =
        dependOnInheritedWidgetOfExactType<_BilocatorInheritedWidget<T>>();
    if (inheritedWidget == null) {
      throw Exception('BuildContext.of<T>() did not find inherited widget Bilocator<$T>()');
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

/// Register multiple Objects so they can be retrieved with [Bilocator.get]
///
/// [Bilocators] only uses [Location.registry] and does not add widget to the widget try per [Location.tree].
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
  const Bilocators({
    required this.delegates,
    required this.child,
    super.key,
  });

  final List<BilocatorDelegate> delegates;
  final Widget child;

  @override
  State<Bilocators> createState() => _BilocatorsState();
}

class _BilocatorsState extends State<Bilocators> {
  @override
  void initState() {
    super.initState();
    for (final delegate in widget.delegates) {
      delegate._register();
    }
  }

  @override
  void dispose() {
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
  T listenTo<T extends ChangeNotifier>(
      {BuildContext? context, T? notifier, String? name, required void Function() listener}) {
    assert(toOne(context) + toOne(notifier) + toOne(name) <= 1,
        'listenTo can only receive non-null for "context", "instance", or "name" but not two or more can be non-null.');
    final notifierInstance = context == null ? notifier ?? Bilocator.get<T>(name: name) : context.get<T>();
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
  T get<T extends Object>({BuildContext? context, String? name}) {
    assert(context == null || name == null,
        '"get" was passed a non-null value for "name" but cannot locate an inherited model by name.');
    if (context == null) {
      return Bilocator.get<T>(name: name);
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
