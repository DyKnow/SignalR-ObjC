<p align="center">
    <img src="https://f.cloud.github.com/assets/1089907/475156/237c7c22-b780-11e2-92e8-3787fdfe5f08.png" />
</p>

SignalR-ObjC is a client library for iOS and Mac OS X.  It's built on top of two popular open source libraries [AFNetworking](https://github.com/AFNetworking/AFNetworking) and [SocketRocket](https://github.com/square/SocketRocket).
SignalR-ObjC is intended to be used along side ASP.NET SignalR, a new library for ASP.NET developers that makes it incredibly simple to add real-time functionality to your applications. What is "real-time web" functionality? It's the ability to have your server-side code push content to the connected clients as it happens, in real-time.

For example, here's how easy it is to get started:
```objective-c
SRConnection *connection = [SRConnection connectionWithURL:@"http://localhost/mysite/echo"];
connection.received = ^(NSString * data) {
    NSLog(data);
};
connection.started =  ^{
    [connection send:@"hello world"];
};
[connection start];
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
    <td><a href="https://github.com/DyKnow/SignalR-ObjC/blob/master/SignalR.Client/Transports/SRAutoTransport.h" >SRAutoTransport</a></td>
    <td>SRAutoTransport chooses the best supported transport for both client and server.  This achieved by falling back to less performant transports.<br/>The default transport fallback is:<br/> 1. SRWebSocketTransport <br/> 2. SRServerSentEventsTransport <br/> 3. SRLongPollingTransport</td>
  </tr>
  <tr>
    <td><a href="https://github.com/DyKnow/SignalR-ObjC/blob/master/SignalR.Client/Transports/SRWebSocketsTransport.h" >SRWebSocketsTransport</a></td>
    <td>WebSockets is the only transport that establishes a true persistent, two-way connection between the client and server.</td>
  </tr>
  <tr>
    <td><a href="https://github.com/DyKnow/SignalR-ObjC/blob/master/SignalR.Client/Transports/SRServerSentEventsTransport.h" >SRServerSentEventsTransport</a></td>
    <td>With Server Sent Events, also known as EventSource, it's possible for a server to send new data to a client at any time, by pushing messages to the client. Server Sent Events requires few new connections then Long Polling and therefore will have less latency.</td>
  </tr>
  <tr>
    <td><a href="https://github.com/DyKnow/SignalR-ObjC/blob/master/SignalR.Client/Transports/SRLongPollingTransport.h" >SRLongPollingTransport</a></td>
    <td>Long polling does not create a persistent connection, but instead polls the server with a request that stays open until the server responds, at which point the connection closes, and a new connection is requested immediately. This may introduce some latency while the connection resets.</td>
  </tr>
</table>

## Example Usage
### Persistent Connection
```c#
using System.Threading.Tasks;
using Microsoft.AspNet.SignalR;

//Server
public class MyConnection : PersistentConnection 
{
    protected override Task OnReceived(IRequest request, string connectionId, string data) 
    {
        // Broadcast data to all clients
        return Connection.Broadcast(data);
    }
}
```

```objective-c
#import "SignalR.h"

//Client
SRConnection *connection = [SRConnection connectionWithURL:@"http://localhost/mysite/echo"];
connection.received = ^(NSString * data) {
    NSLog(data);
};
connection.started =  ^{
    [connection send:@"hello world"];
};
[connection start];
```
### Hubs
```c#
//Server
public class Chat : Hub 
{
    public void Send(string message)
    {
        // Call the addMessage method on all clients            
        Clients.All.addMessage(message);
    }
}
```

```objective-c
//Client
#import "SignalR.h"

// Connect to the service
SRHubConnection *hubConnection = [SRHubConnection connectionWithURL:@"http://localhost/mysite"];
// Create a proxy to the chat service
SRHubProxy *chat = [hubConnection createHubProxy:@"chat"];
[chat on:@"addMessage" perform:self selector:@selector(addMessage:)];
// Start the connection
[hubConnection start];

- (void)addMessage:(NSString *)message {
    // Print the message when it comes in
    NSLog(message);
}
```
## Requirements

SignalR-ObjC requires either [iOS 6.0](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html) and above, or [Mac OS 10.8](http://developer.apple.com/library/mac/#releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_6.html#//apple_ref/doc/uid/TP40008898-SW7) ([64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)) and above.

### ARC

- SignalR-ObjC requires ARC

### Networking

- SignalR-ObjC uses [AFNetworking](https://github.com/AFNetworking/AFNetworking).  The minimum supported version of AFNetworking is 2.0.0
- SignalR-ObjC uses  [SocketRocket](https://github.com/square/SocketRocket).  The minimum supported version of SocketRocket is 0.2.0


## LICENSE

SignalR-ObjC is available under the MIT license. See the [LICENSE](https://github.com/DyKnow/SignalR-ObjC/blob/master/LICENSE.md) file for more info.<br/>
SignalR-ObjC uses 3rd-party code which each have specific licenses, see [ACKNOWLEDGEMENTS](https://github.com/DyKnow/SignalR-ObjC/blob/master/ACKNOWLEDGEMENTS.md) for contributions
