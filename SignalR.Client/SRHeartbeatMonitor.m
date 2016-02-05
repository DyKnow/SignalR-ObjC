//
//  SRHeartbeatMonitor.m
//  SignalR
//
//  Created by Alex Billingsley on 5/9/13.
//  Copyright (c) 2013 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import "SRHeartbeatMonitor.h"
#import "SRConnectionInterface.h"
#import "SRKeepAliveData.h"
#import "SRConnectionState.h"
#import "SRLog.h"
#import "SRClientTransportInterface.h"

@interface SRHeartbeatMonitor ()

@property (strong, nonatomic, readwrite) id <SRConnectionInterface> connection;
@property (strong, nonatomic, readwrite) NSTimer *timer;

@end

@implementation SRHeartbeatMonitor

- (instancetype)initWithConnection:(id <SRConnectionInterface>)connection {
    if (self = [super init]) {
        _connection = connection;
    }
    return self;
}

- (void)start {
    [_connection updateLastKeepAlive];
    _beenWarned = NO;
    _timedOut = NO;
    _timer = [NSTimer scheduledTimerWithTimeInterval:[[[_connection keepAliveData] checkInterval] integerValue]
                                              target:self
                                            selector:@selector(heartbeat:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)heartbeat:(NSTimer *)timer {
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSinceDate:[[_connection keepAliveData] lastKeepAlive]];
    [self beat:timeElapsed];
}

- (void)beat:(NSInteger)timeElapsed {
    if (_connection.state == connected) {
        if (timeElapsed >= [[[_connection keepAliveData] timeout] integerValue]) {
            if (!self.timedOut) {
                // Connection has been lost
                SRLogConnectionWarn(@"Connection Timed-out : Transport Lost Connection");
                _timedOut = true;
                [[_connection transport] lostConnection:_connection];
            }
        } else if (timeElapsed >= [[[_connection keepAliveData] timeoutWarning] integerValue]) {
            if (!self.hasBeenWarned) {
                // Inform user and set HasBeenWarned to true
                SRLogConnectionWarn(@"Connection Timeout Warning : Notifying user");
                _beenWarned = true;
                [_connection connectionDidSlow];
            }
        } else {
            _beenWarned = false;
            _timedOut = false;
        }
    }
}

- (void)stop {
    [_timer invalidate];
    _timer = nil;
}

@end
