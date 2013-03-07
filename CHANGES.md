# SignalR-ObjC Release Notes

## 0.5.0

* Removes the direct dependency on SBJSON (json-framework) instead makes json pluggable with a fallback to NSJSONSerialization if supported
* uses __unsafe_unretained in place of __weak to support iOS 4.3 (with ARC)
* Expose Headers/Cookies on SRConnection
* Gracefully handle parameter mismatch in SRHubProxy invokeEvent
* Adds AppleDoc Style Documentation to the project
* Bug Fixes
* Changes from the SignalR.Client project see [issue 67](https://github.com/DyKnow/SignalR-ObjC/issues/67) for details


## [0.5.2](https://github.com/DyKnow/SignalR-ObjC/compare/0.5.0...0.5.2)

* Use Apple Defined Exceptions when trowing errors
* Prepare project for Localization
* Invoke Server Side abort when stopping connections for Http Based Transports
* Abstract away AFNetworking and make HTTP library plug-able
* Define Protocol for JSON serialization and deserialization
* Allow sending an Object in SRConnection
* Refactor ServerSentEvents transport
* Add Connection State to SRConnection
* fix retain cycles #92
* switch to CocoaPods for dependency management
* fix compiler warning #94
* Bug Fixes

## [0.5.3](https://github.com/DyKnow/SignalR-ObjC/compare/0.5.2...0.5.3)

* Transition to Cocoapods for easier installs
* Support CocoaLumberjack for logging
* Abort HTTPRequest before shutting down the client
* Fixes URL creation when using a custom query string in SRHubConnection
* Throw Exception if create proxy is called after start
* Throw Exception if JSONSerialization Fails
* Makes the Long Polling and Server Sent Events Transports more configurable
* Bug Fixes

## [1.0RC1](https://github.com/DyKnow/SignalR-ObjC/compare/0.5.3...1.0rc1)


## [1.0.1]((https://github.com/DyKnow/SignalR-ObjC/compare/1.0rc1...1.0.1)

* Adds support for SignalR protocol version 1.2 (SignalR library v1.0.1)