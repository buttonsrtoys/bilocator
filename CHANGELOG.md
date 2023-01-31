## 0.5.6
- Added exception for when adding an existing type/name keys to registry.
- Fixed example test.

## 0.5.5
- Repaired lib/bilocator.dart

## 0.5.4
- Add runtimeCheck when consumer omits generic type.
- Upgraded packages.

## 0.5.3
- Improved error messages to provide suggestions on how to fix exceptions.
- Added a Key check to block Bilocators with the same key from registering. This fixes Bilocators 
trying to register BilocatorDelegates during a hot reload.
- Changed Bilocators to register data from constructor instead of initState so the data is 
available earlier.
- Improved the demo app to test context.of

## 0.5.2
- Improved readme.

## 0.5.1
- Removed unnecessary setState listener. Improved tests and readme.

## 0.5.0
- Renamed package from Registrar to Bilocator.

## 0.4.0 
- Added "location" param Registrar to be used instead of "inherited" param.
- Bug fix where attempted to add listener non-ChangeNotifier.
- Improved lazy initialization.

## 0.3.1
Fixed bug where dispose not call omitted.

## 0.3.0
Added support for inherited models on the widget tree.

## 0.2.0
Added "dispose" boolean to API.

## 0.1.10
Static analysis.

## 0.1.9
Embedded example gif in readme.

## 0.1.8
Changed example gif.

## 0.1.7
Added example gif.

## 0.1.6
Updated with the Dart formatter.

## 0.1.5
Updated changelog.

## 0.1.4
Corrected readme.

## 0.1.3
- Removed unused dependency
- Added ValueNotifier to example
- Fixed typo in readme

## 0.1.2
Static analysis.

## 0.1.1
Static analysis.

## 0.1.0
Initial release.
