# bilocator

![bilocator logo](https://github.com/buttonsrtoys/bilocator/blob/main/assets/BilocatorLogo.png)

A flexible hybrid locator that supports both single services (like GetIt) and inherited models (like Provider).

Bilocator goals:
- Locate single services from global registry.
- Locate inherited models in the widget tree.
- Bind the lifecycle of both single services and inherited models to widgets.
- Support lazy loading.
- Support models being simultaneously locatable in the registry and on the widget tree.
- Work alone or with other state management packages (RxDart, Provider, GetIt, ...).
- Be scalable and performant, so suitable for both indy and production apps.

Bilocator can be used as a standalone locator or integrated into state management libraries. [mvvm+](https://pub.dev/packages/mvvm_plus) uses Bilocator.

## Single Services

Single services are those single instances that need to located from anywhere in the widget tree.

To add a single service to the registry, give a builder to a Bilocator widget and add it to the widget tree:

```dart
Bilocator<MyService>(
  builder: () => MyService(),
  child: MyWidget(),
);
```

## Inherited Models 

Inherited models are located on the widget tree (similar to Provider, InheritedWidget). Unlike single services, you can add as many inherited models of the same type as you need.

Adding inherited models to the widget tree uses the same Bilocator widget, but with the `inherited` parameter:

```dart
Bilocator<MyModel>(
  builder: () => MyModel(),
  inherited: true,
  child: MyWidget(),
);
```

Bilocator widgets unregister their services and models when they are removed from the widget tree. If their services and models are ChangeNotifiers, the Bilocator widgets optionally call the ChangeNotifiers' `dispose` method.

## How to Locate Single Services

The single service instance can located from anywhere by type:

```dart
final myService = Bilocator.get<MyService>();
```

If more than one instance of a service of the same type is needed, you can specify a unique name:

```dart
Bilocator<MyService>(
  builder: () => MyService(),
  name: 'some unique name',
  child: MyWidget(),
);
```

And then get the service by type and name:

```dart
final myService = Bilocator.get<MyService>(name: 'some unique name');
```

When you want to manage multiple services with a single widget, use MultiBilocator:

```dart
MultiBilocator(
  delegates: [
    BilocatorDelegate<MyService>(builder: () => MyService()),
    BilocatorDelegate<MyOtherService>(builder: () => MyOtherService()),
  ],
  child: MyWidget(),
);
```

For rare use cases where you need to directly manage registering and unregistering services (instead of letting Bilocator and MultiBilocator manage your services), you can use the static `register` and `unregister` functions:

````dart
Bilocator.register<MyService>(builder: () => MyService())
````

## How to Located Inherited Models

Bilocator implements the observer pattern as a mixin that can my added to your models and widgets.

```dart
class MyModel with Observer {
  int counter;
}
```

Models and widgets that use Observer can `listenTo` inherited models and single services. To listen to single services:

```dart
final text = listenTo<MyWidgetViewModel>(listener: myListener).text;
```

To listen to inherited models on the widget tree, add the `context` parameter to search the widget tree:

```dart
final text = listenTo<MyWidgetViewModel>(context: context, listener: myListener).text;
```

For convenience, Observer also adds a `get` function that doesn't required the preceding Bilocator class name. Models and widgets that use Observer can get single services:

```dart
final text = get<MyModel>().text;
```

And get inherited models:

```dart
final text = get<MyModel>(context: context).text;
```

# .of

The `of` function (Theme.of, Provider.of) is known to introduce unnecessary dependencies in apps (and consequently unnecessary builds). So, using `listenTo` is recommended. However, if you are migrating from another library that uses `of` (or simply like using `of`), Bilocator includes `of` in its BuildContext extension:

```dart
final text = context.of<MyModel>().text;
```

Or, you get use the BuildContext extension to get models without adding a dependency:

```dart
final text = context.get<MyModel>().text;
```

# Registering an Inherited Model as a Single Service

To make an inherited model on the widget tree visible to widgets on other branches, register the inherited model as a single service:

```dart
register<MyModel>(context);
```

After registering, the model will be available from anywhere. When no longer needed in the registry, simply unregister it:

```dart
unregister<MyModel>(context);
```

# Did You Know...

Bilocators are religious zealots and mystics that claim to have the power of locating in two places at once? Thus the name.

# Example
(The source code for this example is under the Pub.dev "Example" tab and in the GitHub `example/lib/main.dart` file.)

There are three registered services:
1. ColorNotifier changes its color every N seconds and then calls `notifyListeners`.
2. FortyTwoService holds a number that is equal to 42.
3. RandomService generates a random number.

The first service was added to the widget tree with `Bilocator`. The remaining services were added with `MultiBilocator`.

![example](https://github.com/buttonsrtoys/bilocator/blob/main/example/example.gif)

## That's it! 

If you have questions or suggestions on anything Bilocator, please do not hesitate to contact me.

