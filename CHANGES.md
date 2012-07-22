# SignalR-ObjC Release Notes

## v0.5

### SignalR-ObjC.Client

* Removes the direct dependency on SBJSON (json-framework) instead makes json pluggable with a fallback to NSJSONSerialization if supported
* uses __unsafe_unretained in place of __weak to support iOS 4.3 (with ARC)
* Expose Headers/Cookies on SRConnection
* Gracefully handle parameter mismatch in SRHubProxy invokeEvent
* Adds AppleDoc Style Documentation to the project
* Bug Fixes
* Changes from the SignalR.Client project see [issue 67](https://github.com/DyKnow/SignalR-ObjC/issues/67) for details


## v0.5.2

### SignalR-ObjC.Client

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
