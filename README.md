<p align="center">
    SignalR Objective-C
</p>

SignalR-ObjC is a client library for iOS and Mac OS X.  It's built on top of two popular open source libraries [AFNetworking](https://github.com/AFNetworking/AFNetworking) and [SocketRocket](https://github.com/square/SocketRocket).
SignalR-ObjC is intended to be used along side ASP.NET SignalR, a new library for ASP.NET developers that makes it incredibly simple to add real-time functionality to your applications. What is "real-time web" functionality? It's the ability to have your server-side code push content to the connected clients as it happens, in real-time.

For example, here's how easy it is to get started:
```objective-c
SRConnection *connection = [SRConnection connectionWithURL:@"http://localhost/mysite/echo"];
connection.received = ^(NSString * data) {
    NSLog(data);
};
[connection start];


[connection send:@"hello world"];
```

## How To Get Started

- Download SignalR-ObjC and try out the included Mac and iPhone example apps
    1. Install [CocoaPods](http://cocoapods.org/)
        * $ [sudo] gem install cocoapods
        * $ pod setup
    1. cd SignalR-ObjC project directory
    1. $ pod install
- Check out the [documentation](http://dyknow.github.com/SignalR-ObjC/Documentation/index.html) for a comprehensive look at the APIs available in SignalR-ObjC. **NOTE:** this is a work in progress and is currently outdated.
- Questions? [JabbR](https://jabbr.net/#/rooms/signalr-objc) is the best place to find answers

### Installation
1. Install [CocoaPods](http://cocoapods.org/)
    * $ [sudo] gem install cocoapods
    * $ pod setup
2. Create or Add SignalR to your "Podfile"
<table>
  <tr>
    <th>Sample iOS Podfile</th>
    <th>Sample OSX Podfile</th>
  </tr>
  <tr>
    <td>
platform :ios, '5.0'<br/>
pod 'SignalR-ObjC'
    </td>
    <td>
platform :osx, '10.7'<br/>
pod 'SignalR-ObjC'
    </td>
  </tr>
</table>
3. Install SignalR-ObjC into your project
    * $ pod install

## Overview

<table>
  <tr><th colspan="2" style="text-align:center;">Hubs</th></tr>
  <tr>
    <td>SRHubConnection</td>
    <td></td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Core</th></tr>
  <tr>
    <td>SRConnection</td>
    <td></td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Transports</th></tr>
  <tr>
    <td>SRWebSocketTransport</td>
    <td></td>
  </tr>
  <tr>
    <td>SRServerSentEventsTransport</td>
    <td></td>
  </tr>
  <tr>
    <td>SRLongPollingTransport</td>
    <td></td>
  </tr>
</table>

## Example Usage

## Requirements

SignalR-ObjC requires either [iOS 5.0](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html) and above, or [Mac OS 10.7](http://developer.apple.com/library/mac/#releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_6.html#//apple_ref/doc/uid/TP40008898-SW7) ([64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)) and above.

### ARC

- SignalR-ObjC requires ARC

### Networking

- SignalR-ObjC uses [AFNetworking](https://github.com/AFNetworking/AFNetworking).  The minimum supported version of AFNetworking is 1.0.0
- SignalR-ObjC uses  [SocketRocket](https://github.com/square/SocketRocket).  The minimum supported version of SocketRocket is 0.2.0

### JSON

SignalR-ObjC uses [`NSJSONSerialization`](http://developer.apple.com/library/mac/#documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html) if it is available. You can include one of the following JSON libraries to your project for SignalR-ObjC to automatically detect and use.

* [JSONKit](https://github.com/johnezang/JSONKit)
* [SBJson](http://stig.github.com/json-framework/)
* [YAJL](http://lloyd.github.com/yajl/)
* [NextiveJson](https://github.com/nextive/NextiveJson)


## LICENSE
[MIT License](https://github.com/DyKnow/SignalR-ObjC/blob/master/LICENSE.md)

SignalR-ObjC uses 3rd-party code, see [ACKNOWLEDGEMENTS](https://github.com/DyKnow/SignalR-ObjC/blob/master/ACKNOWLEDGEMENTS.md) for contributions
