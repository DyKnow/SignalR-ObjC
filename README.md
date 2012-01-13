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
See the [documentation](https://github.com/DyKnow/SignalR-ObjC/wiki)
	
## Installation
NOTE: SignalR-ObjC uses Automatic Reference Counting.

### Method 1:
Copy the contents of the SignalR.Client and Vendor Folders into your project and import SignalR.h

Note: While SignalR-ObjC uses arc it makes use of Vendor Projects that do not.
For each target that SignalR-ObjC is used in update the compiler flags under Build Phases Compile Sources to
-fno-objc-arc 
for any files that have the prefix ASI and for Reachability.m

You should now be able to click build with no errors.

### Method 2:


## LICENSE
[MIT License](https://github.com/DyKnow/SignalR-ObjC/blob/master/LICENSE.md)

## Questions?
The SignalR team hangs out in the **signalr** room at http://jabbr.net.