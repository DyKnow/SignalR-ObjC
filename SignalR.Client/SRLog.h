//
//  SRLog.h
//  SignalR
//
//  Created by Alex Billingsley on 1/29/12.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
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

#if __has_include("DDLog.h")
#import <CocoaLumberjack/DDLog.h>

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#if defined( LOG_ASYNC_ENABLED )
    #undef LOG_ASYNC_ENABLED
    #define LOG_ASYNC_ENABLED NO
#endif

#define SRLogError(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   0, frmt, ##__VA_ARGS__)
#define SRLogWarn(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_FLAG_WARN,    0, frmt, ##__VA_ARGS__)
#define SRLogInfo(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)
#define SRLogDebug(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_FLAG_DEBUG,   0, frmt, ##__VA_ARGS__)
#define SRLogVerbose(frmt, ...) LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)

#else

#define SRLogError(frmt, ...)      do{ NSLog((frmt), ##__VA_ARGS__); } while(0)
#define SRLogWarn(frmt, ...)       do{ NSLog((frmt), ##__VA_ARGS__); } while(0)
#define SRLogInfo(frmt, ...)       do{ NSLog((frmt), ##__VA_ARGS__); } while(0)
#define SRLogDebug(frmt, ...)      do{ NSLog((frmt), ##__VA_ARGS__); } while(0)
#define SRLogVerbose(frmt, ...)    do{ NSLog((frmt), ##__VA_ARGS__); } while(0)

#endif

#define SRLogPrefixedError(type, frmt, ...) SRLogError(@"%@:\t%@", type, [NSString stringWithFormat:frmt, ##__VA_ARGS__]);
#define SRLogPrefixedWarn(type, frmt, ...) SRLogWarn(@"%@:\t%@", type, [NSString stringWithFormat:frmt, ##__VA_ARGS__]);
#define SRLogPrefixedInfo(type, frmt, ...) SRLogInfo(@"%@:\t%@", type, [NSString stringWithFormat:frmt, ##__VA_ARGS__]);
#define SRLogPrefixedDebug(type, frmt, ...) SRLogDebug(@"%@:\t%@", type, [NSString stringWithFormat:frmt, ##__VA_ARGS__]);
#define SRLogPrefixedVerbose(type, frmt, ...) SRLogVerboase(@"%@:\t%@", type, [NSString stringWithFormat:frmt, ##__VA_ARGS__]);

#define SRLogConnectionError(frmt, ...)   SRLogPrefixedError(@"CONNECTION", frmt, ##__VA_ARGS__);
#define SRLogConnectionWarn(frmt, ...)    SRLogPrefixedWarn(@"CONNECTION", frmt, ##__VA_ARGS__);
#define SRLogConnectionInfo(frmt, ...)    SRLogPrefixedInfo(@"CONNECTION", frmt, ##__VA_ARGS__);
#define SRLogConnectionDebug(frmt, ...)   SRLogPrefixedDebug(@"CONNECTION", frmt, ##__VA_ARGS__);
#define SRLogConnectionVerbose(frmt, ...) SRLogPrefixedVerbose(@"CONNECTION", frmt, ##__VA_ARGS__);

#define SRLogAutoError(frmt, ...)   SRLogPrefixedError(@"AUTO", frmt, ##__VA_ARGS__);
#define SRLogAutoWarn(frmt, ...)    SRLogPrefixedWarn(@"AUTO", frmt, ##__VA_ARGS__);
#define SRLogAutoInfo(frmt, ...)    SRLogPrefixedInfo(@"AUTO", frmt, ##__VA_ARGS__);
#define SRLogAutoDebug(frmt, ...)   SRLogPrefixedDebug(@"AUTO", frmt, ##__VA_ARGS__);
#define SRLogAutoVerbose(frmt, ...) SRLogPrefixedVerbose(@"AUTO", frmt, ##__VA_ARGS__);

#define SRLogTransportError(frmt, ...)   SRLogPrefixedError(@"TRANSPORT", frmt, ##__VA_ARGS__);
#define SRLogTransportWarn(frmt, ...)    SRLogPrefixedWarn(@"TRANSPORT", frmt, ##__VA_ARGS__);
#define SRLogTransportInfo(frmt, ...)    SRLogPrefixedInfo(@"TRANSPORT", frmt, ##__VA_ARGS__);
#define SRLogTransportDebug(frmt, ...)   SRLogPrefixedDebug(@"TRANSPORT", frmt, ##__VA_ARGS__);
#define SRLogTransportVerbose(frmt, ...) SRLogPrefixedVerbose(@"TRANSPORT", frmt, ##__VA_ARGS__);

#define SRLogWSError(frmt, ...)   SRLogPrefixedError(@"WS", frmt, ##__VA_ARGS__);
#define SRLogWSWarn(frmt, ...)    SRLogPrefixedWarn(@"WS", frmt, ##__VA_ARGS__);
#define SRLogWSInfo(frmt, ...)    SRLogPrefixedInfo(@"WS", frmt, ##__VA_ARGS__);
#define SRLogWSDebug(frmt, ...)   SRLogPrefixedDebug(@"WS", frmt, ##__VA_ARGS__);
#define SRLogWSVerbose(frmt, ...) SRLogPrefixedVerbose(@"WS", frmt, ##__VA_ARGS__);

#define SRLogSSEError(frmt, ...)   SRLogPrefixedError(@"SSE", frmt, ##__VA_ARGS__);
#define SRLogSSEWarn(frmt, ...)    SRLogPrefixedWarn(@"SSE", frmt, ##__VA_ARGS__);
#define SRLogSSEInfo(frmt, ...)    SRLogPrefixedInfo(@"SSE", frmt, ##__VA_ARGS__);
#define SRLogSSEDebug(frmt, ...)   SRLogPrefixedDebug(@"SSE", frmt, ##__VA_ARGS__);
#define SRLogSSEVerbose(frmt, ...) SRLogPrefixedVerbose(@"SSE", frmt, ##__VA_ARGS__);

#define SRLogLPError(frmt, ...)   SRLogPrefixedError(@"LP", frmt, ##__VA_ARGS__);
#define SRLogLPWarn(frmt, ...)    SRLogPrefixedWarn(@"LP", frmt, ##__VA_ARGS__);
#define SRLogLPInfo(frmt, ...)    SRLogPrefixedInfo(@"LP", frmt, ##__VA_ARGS__);
#define SRLogLPDebug(frmt, ...)   SRLogPrefixedDebug(@"LP", frmt, ##__VA_ARGS__);
#define SRLogLPVerbose(frmt, ...) SRLogPrefixedVerbose(@"LP", frmt, ##__VA_ARGS__);
