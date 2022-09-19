# Example

There are three registered services:
1. ColorNotifier changes its color every N seconds and then calls `notifyListeners`.
2. FortyTwoService holds a number that is equal to 42.
3. RandomService generates a random number.

The first service was added to the widget tree with `Bilocator`. The remaining services are added with `Bilocators`.

![example](https://github.com/buttonsrtoys/bilocator/blob/main/example/example.gif)