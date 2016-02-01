xcodeproj 'SignalR.Client.ObjC/SignalR.Client.ObjC'
workspace 'SignalR.Client.ObjC'

target :"SignalR.Client.iOS", :exclusive => true do
  platform :ios, '7.0'
  pod 'AFNetworking', '2.6.3'
  pod 'SocketRocket', '0.4.2'
end

target :"SignalR.Client.OSX", :exclusive => true do
  platform :osx, '10.9'
  pod 'AFNetworking', '2.6.3'
  pod 'SocketRocket', '0.4.2'
end

target :"SignalR.Client.Tests.OSX", :exclusive => true do
    platform :osx, '10.9'
    pod 'OCMock'
end

target :"SignalR.Client.Tests.iOS", :exclusive => true do
    platform :ios, '7.0'
    pod 'OCMock'
end


target :"SignalR.Samples.iOS", :exclusive => true do
  platform :ios, '7.0'
end


target :"SignalR.Samples.OSX", :exclusive => true do
  platform :osx, '10.9'
end
