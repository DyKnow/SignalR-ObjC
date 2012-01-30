# Vendor Projects 
Other open source projects that must be included in the SignalR Objective C project for it to work properly

## AFNetworking
AFNetworking is a delightful networking library for iOS and Mac OS X. It's built on top of NSURLConnection, NSOperation, and other familiar Foundation technologies. It has a modular architecture with well-designed, feature-rich APIs that are a joy to use.
[Gowalla AFNetworking on GitHub](https://github.com/AFNetworking/AFNetworking)

### What is it for?
AFNetworking is used to manage all http requests


## SBJSON
JSON (JavaScript Object Notation) is a light-weight data interchange format that's easy to read and write for humans and computers alike. This library implements strict JSON parsing and generation in Objective-C.
[Stig Brautaset json-framework on GitHub](https://github.com/stig/json-framework)

### What is it for?
SBJSON is used to json strinify objects in the Transports before sending to the server


## CocoaAysncSocket
CocoaAsyncSocket provides easy-to-use and powerful asynchronous socket libraries for Mac and iOS. The classes are described below.
[Robbie Hanson CocoaAsyncSocket on GitHub](https://github.com/robbiehanson/CocoaAsyncSocket)

### What is it for?
CocoaAysncSocket will be used with the WebsocketsTransport when supported
* Including this project is optional if longpolling or serversentevents transports are used (currently only supported transports)