# Vendor Projects 
Other open source projects that must be included in the SignalR Objective C project for it to work properly

## ASIHTTPRequest
ASIHTTPRequest is an easy to use wrapper around the CFNetwork API that makes some of the more tedious aspects of communicating with web servers easier. It is written in Objective-C and works in both Mac OS X and iPhone applications.
[Ben Copsey asi-http-request on GitHub](https://github.com/pokeb/asi-http-request)

### What is it for?
ASIHTTPRequest is used to manage all http requests


## Reachability
A replacement for Apple’s Reachability class.
[Andrew Donoho Reachablilty](http://blog.ddg.com/?p=24)

### What is it for?
Reachability is only included as a requirement of ASIHttpRequest
It allows ASIHTTPRequest to be notified when the network connection changes from WWAN to WiFi, or vice-versa.


## SBJSON
JSON (JavaScript Object Notation) is a light-weight data interchange format that's easy to read and write for humans and computers alike. This library implements strict JSON parsing and generation in Objective-C.
[Stig Brautaset json-framework on GitHub](https://github.com/stig/json-framework)

### What is it for?
SBJSON is used to json strinify objects in the Transports before sending to the server


## DKHttpHelper
Simiple wrapper to make for posting and getting http request easy.  
This is adopted from the HttpHelper in the SignalR Project and is included in Vendor since I have started using it in multiple projects I am working.

### What is it for?
SRHttpHelper is as subclass of DKHttpHelper and is used to provide a clean interface to making async post and get requests


## CocoaAysncSocket
CocoaAsyncSocket provides easy-to-use and powerful asynchronous socket libraries for Mac and iOS. The classes are described below.
[Robbie Hanson CocoaAsyncSocket on GitHub](https://github.com/robbiehanson/CocoaAsyncSocket)

### What is it for?
CocoaAysncSocket will be used with the WebsocketsTransport when supported
* Including this project is optional if longpolling or serversentevents transports are used (currently only supported transports)