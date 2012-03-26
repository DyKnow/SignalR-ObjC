# SignalR 
Async signaling library for .NET to help build real-time, multi-user interactive web applications
for the official SignalR Library for .NET see the [SignalR Repository](https://github.com/SignalR/SignalR/wiki)

# SignalR Objective-C
Extends the reach of the main SignalR project by providing a client that is written in Objective-C and is compaitible
with iOS and Mac

## What can it be used for?
Pushing data from the server to the client (not just browser clients) has always been a tough problem. SignalR makes 
it dead easy and handles all the heavy lifting for you.


## Documentation
See the [documentation](https://github.com/DyKnow/SignalR-ObjC/wiki) and [api reference](http://dyknow.github.com/SignalR-ObjC/Documentation/index.html)
	
## Installation
NOTE: SignalR-ObjC uses Automatic Reference Counting.

### Method 1:
1. Copy the contents of the SignalR.Client and Vendor Folders into your project
	- Note: While SignalR-ObjC uses arc it makes use of Vendor Projects that do not.
		- For each target that SignalR-ObjC is used in update the compiler flags under Build Phases Compile Sources to ```-fno-objc-arc```
		- for any files that have the prefix AF (This requirement will go away in future release of AFNetworking)
1. In your pch file or where every you intend to use SignalR ```#import SignalR.h```
1. Build and Run your project with no errors

### Method 2:
1. Open the [SignalR.Framework XCode Project](https://github.com/DyKnow/SignalR-ObjC/tree/master/Xcode/SignalR.Framework) 
1. Choose the appropriate build target SignalR-iOS or SignalR-OSX
1. Verify that the Project's Base SDK setting under Build Settings is correct, Latest iOS for the iOS target, Latest Mac OS for the mac target
1. Run the target
1. Expand the Products Group
1. Right Click on the product that corresponds to the target you built against, and choose show in finder
1. Copy the SignalR-iOS.framework or SignalR-OSX.framework to your project
1. In your pch file or where every you intend to use SignalR ```#import <SignalR-iOS/SignalR.h>``` or ```#import <SignalR-OSX/SignalR.h>```
1. Build and Run your project with no errors

## Requirements

SignalR-ObjC uses [`NSJSONSerialization`](http://developer.apple.com/library/mac/#documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html) if it is available. You can include one of the following JSON libraries to your project for SignalR-ObjC to automatically detect and use.

* [JSONKit](https://github.com/johnezang/JSONKit)
* [SBJson](http://stig.github.com/json-framework/)
* [YAJL](http://lloyd.github.com/yajl/)

### ARC Support

SignalR-ObjC requires ARC

## LICENSE
[MIT License](https://github.com/DyKnow/SignalR-ObjC/blob/master/LICENSE.md)

SignalR-ObjC uses 3rd-party code, see [ACKNOWLEDGEMENTS](https://github.com/DyKnow/SignalR-ObjC/blob/master/ACKNOWLEDGEMENTS.md) for contributions and
[Vendor](https://github.com/DyKnow/SignalR-ObjC/tree/master/Vendor) for specific usage

## Questions?
- The SignalR team hangs out in the **signalr** room at http://jabbr.net/
- The SignalR-ObjC team hangs out in the **signalr-objc** room at http://jabbr.net/