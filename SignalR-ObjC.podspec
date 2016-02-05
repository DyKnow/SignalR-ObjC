Pod::Spec.new do |s|
  s.default_subspec = 'Core'
  s.name         = "SignalR-ObjC"
  s.version      = "2.0.1"
  s.summary      = "Objective-C Client for the SignalR Project works with iOS and Mac."
  s.homepage     = "https://github.com/DyKnow/SignalR-ObjC"
  s.license      = 'MIT'
  s.author       = { "Alex Billingsley" => "abillingsley@dyknow.com" }
  s.source   	 = { :git => 'https://github.com/DyKnow/SignalR-ObjC.git', :tag => '2.0.1' }
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true

  s.subspec 'Core' do |sp|
    sp.source_files = 'SignalR.Client/**/*.{h,m}'
    sp.dependency 'AFNetworking', '~>2.0'
    sp.dependency 'SocketRocket', '~>0.4'
  end

  s.subspec 'CocoaLumberjack' do |sp|
    sp.dependency 'CocoaLumberjack', '~>1.0'
    sp.dependency 'SignalR-ObjC/Core'
  end
end
