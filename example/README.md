# Example

There are three registered services:
1. ColorNotifier changes its color every N seconds and then calls `notifyListeners`.
2. FortyTwoService holds a number that is equal to 42.
3. RandomService generates a random number.

The first service was added to the widget tree with `Registrar`. The remaining services are added with `MultiRegistrar`.

![example](https://github.com/buttonsrtoys/registrar/blob/main/example/example.gif)