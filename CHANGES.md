# SignalR-ObjC Release Notes

## v0.5

### SignalR-ObjC.Client

* Removes the direct dependency on SBJSON (json-framework) instead makes json pluggable with a fallback to NSJSONSerialization if supported
* uses __unsafe_unretained in place of __weak to support iOS 4.3 (with ARC)
* Expose Headers/Cookies on SRConnection
* Gracefully handle parameter mismatch in SRHubProxy invokeEvent
* Adds AppleDoc Style Documentation to the project