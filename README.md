<p align="center">
    <img src="https://f.cloud.github.com/assets/1089907/475156/237c7c22-b780-11e2-92e8-3787fdfe5f08.png" />
</p>

SignalR-ObjC is a client library for iOS and Mac OS X.  It's built on top of two popular open source libraries [AFNetworking](https://github.com/AFNetworking/AFNetworking) and [SocketRocket](https://github.com/square/SocketRocket).
SignalR-ObjC is intended to be used along side ASP.NET SignalR, a new library for ASP.NET developers that makes it incredibly simple to add real-time functionality to your applications. What is "real-time web" functionality? It's the ability to have your server-side code push content to the connected clients as it happens, in real-time.

## Installation

### Installation with CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like SignalR-ObjC in your projects. See the ["Getting Started" guide for more information](https://guides.cocoapods.org/using/getting-started.html). You can install it with the following command:

```
$ gem install cocoapods
```

#### Podfile

To integrate SignalR-ObjC into your Xcode project using CocoaPods, specify it in your Podfile:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'SignalR-ObjC', '~> 2.0'
```

Then, run the following command:

```
$ pod install
```

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
    <td>SRAutoTransport chooses the best supported transport for both client and server.  This achieved by falling back to less performant transports.<br/>The default transport fallback is:<br/> 1. SRWebSocketTransport (if supported by the server) <br/> 2. SRServerSentEventsTransport <br/> 3. SRLongPollingTransport</td>
  </tr>
  <tr>
    <td><a href="https://github.com/DyKnow/SignalR-ObjC/blob/master/SignalR.Client/Transports/SRWebSocketTransport.m" >SRWebSocketTransport</a></td>
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

// Register for connection lifecycle events
[connection setStarted:^{
    NSLog(@"Connection Started");
    [connection send:@"hello world"];
}];
[connection setReceived:^(NSString *message) {
    NSLog(@"Connection Recieved Data: %@",message);
}];
[connection setConnectionSlow:^{
    NSLog(@"Connection Slow");
}];
[connection setReconnecting:^{
    NSLog(@"Connection Reconnecting");
}];
[connection setReconnected:^{
    NSLog(@"Connection Reconnected");
}];
[connection setClosed:^{
    NSLog(@"Connection Closed");
}];
[connection setError:^(NSError *error) {
    NSLog(@"Connection Error %@",error);
}];

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

// Register for connection lifecycle events
[hubConnection setStarted:^{
    NSLog(@"Connection Started");
    [connection send:@"hello world"];
}];
[hubConnection setReceived:^(NSString *message) {
    NSLog(@"Connection Recieved Data: %@",message);
}];
[hubConnection setConnectionSlow:^{
    NSLog(@"Connection Slow");
}];
[hubConnection setReconnecting:^{
    NSLog(@"Connection Reconnecting");
}];
[hubConnection setReconnected:^{
    NSLog(@"Connection Reconnected");
}];
[hubConnection setClosed:^{
    NSLog(@"Connection Closed");
}];
[hubConnection setError:^(NSError *error) {
    NSLog(@"Connection Error %@",error);
}];
// Start the connection
[hubConnection start];

- (void)addMessage:(NSString *)message {
    // Print the message when it comes in
    NSLog(message);
}
```

### Customizing Query Params

#### Persistent Connections
```objectivec
id qs = @{
   @"param1": @1,
   @"param2": @"another"
};
SRConnection *connection = [SRConnection connectionWithURL:@"http://localhost/mysite" queryString:qs];
```

#### Hub Connections
```objectivec
id qs = @{
   @"param1": @1,
   @"param2": @"another"
};
SRHubConnection *hubConnection = [SRHubConnection connectionWithURL:@"http://localhost/mysite" queryString:qs];
```

### Customizing Request Headers

#### Persistent Connections
```objectivec
id headers = @{
   @"param1": @1,
   @"param2": @"another"
};
SRConnection *connection = [SRConnection connectionWithURL:@"http://localhost/mysite"];
[connection setHeaders:headers];

//Alternative Usage
SRConnection *connection = [SRConnection connectionWithURL:@"http://localhost/mysite"];
[connection addValue:@"1" forHTTPHeaderField:@"param1"];
[connection addValue:@"another" forHTTPHeaderField:@"param2"];
```

#### Hub Connections
```objectivec
id headers = @{
   @"param1": @1,
   @"param2": @"another"
};
SRHubConnection *hubConnection = [SRHubConnection connectionWithURL:@"http://localhost/mysite"];
[hubConnection setHeaders:headers];

//Alternative Usage
SRHubConnection *hubConnection = [SRHubConnection connectionWithURL:@"http://localhost/mysite"];
[hubConnection addValue:@"1" forHTTPHeaderField:@"param1"];
[hubConnection addValue:@"another" forHTTPHeaderField:@"param2"];
```

## Requirements

SignalR-ObjC requires either iOS 7.0 and above, or Mac OS 10.9 (64-bit with modern Cocoa runtime) and above.

### ARC

- SignalR-ObjC requires ARC

### Networking

- SignalR-ObjC uses [AFNetworking](https://github.com/AFNetworking/AFNetworking).  The minimum supported version of AFNetworking is 2.x
- SignalR-ObjC uses  [SocketRocket](https://github.com/square/SocketRocket).  The minimum supported version of SocketRocket is 0.4.x


## LICENSE

SignalR-ObjC is available under the MIT license. See the [LICENSE](https://github.com/DyKnow/SignalR-ObjC/blob/master/LICENSE.md) file for more info.<br/>
SignalR-ObjC uses 3rd-party code which each have specific licenses, see [ACKNOWLEDGEMENTS](https://github.com/DyKnow/SignalR-ObjC/blob/master/ACKNOWLEDGEMENTS.md) for contributions
