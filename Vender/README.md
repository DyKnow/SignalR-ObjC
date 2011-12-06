# Vendor Projects 
Other open source projects that must be included in the SignalR Objective C project for it to work properly

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
* Including this project is optional if the longpollingTransport is used (currently only supported transport)