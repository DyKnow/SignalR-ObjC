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

### [CocoaPods](http://cocoapods.org/)
1. Install CocoaPods (if you have not already done so)
    * $ [sudo] gem install cocoapods
    * $ pod setup
1. Create or Add SignalR to your "Podfile"
    * ```platform :ios, '5.0'``` or ```platform :osx, '10.7'```
    * ```pod 'SignalR-ObjC'```
1. Install SignalR-ObjC into your project
    * pod install

## Running the Samples
1. Install CocoaPods (if you have not already done so)
    * $ [sudo] gem install cocoapods
    * $ pod setup
1. cd SignalR-ObjC project directory
1. $ pod install

## Requirements

SignalR-ObjC uses [`NSJSONSerialization`](http://developer.apple.com/library/mac/#documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html) if it is available. You can include one of the following JSON libraries to your project for SignalR-ObjC to automatically detect and use.

* [JSONKit](https://github.com/johnezang/JSONKit)
* [SBJson](http://stig.github.com/json-framework/)
* [YAJL](http://lloyd.github.com/yajl/)
* [NextiveJson](https://github.com/nextive/NextiveJson)

### ARC Support

SignalR-ObjC requires ARC

## LICENSE
[MIT License](https://github.com/DyKnow/SignalR-ObjC/blob/master/LICENSE.md)

SignalR-ObjC uses 3rd-party code, see [ACKNOWLEDGEMENTS](https://github.com/DyKnow/SignalR-ObjC/blob/master/ACKNOWLEDGEMENTS.md) for contributions

## Questions?
- The SignalR team hangs out in the **signalr** room at http://jabbr.net/
- The SignalR-ObjC team hangs out in the **signalr-objc** room at http://jabbr.net/