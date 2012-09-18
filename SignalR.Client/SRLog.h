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

#define LOG_FLAG_HTTP               (1 << 0)  // 0...000001
#define LOG_FLAG_CONNECTION         (1 << 1)  // 0...000010
#define LOG_FLAG_LONGPOLLING        (1 << 2)  // 0...000100
#define LOG_FLAG_SERVERSENTEVENTS   (1 << 3)  // 0...001000
#define LOG_FLAG_HTTPTRANSPORT      (1 << 4)  // 0...010000
#define LOG_FLAG_AUTOTRANSPORT      (1 << 5)  // 0...100000

#define LOG_LEVEL_OFF     0
#define LOG_LEVEL_HTTP              (LOG_FLAG_HTTP)                     // 0...000001
#define LOG_LEVEL_CONNECTION        (LOG_FLAG_CONNECTION  | LOG_FLAG_HTTP) // 0...000011
#define LOG_LEVEL_LONGPOLLING       (LOG_FLAG_LONGPOLLING   | LOG_FLAG_CONNECTION | LOG_FLAG_HTTP) // 0...000111
#define LOG_LEVEL_SERVERSENTEVENTS  (LOG_FLAG_SERVERSENTEVENTS | LOG_FLAG_CONNECTION | LOG_FLAG_HTTP) // 0...001011
#define LOG_LEVEL_HTTPTRANSPORT     (LOG_FLAG_HTTPTRANSPORT | LOG_FLAG_SERVERSENTEVENTS | LOG_FLAG_LONGPOLLING | LOG_FLAG_CONNECTION  | LOG_FLAG_HTTP ) // 0...011111
#define LOG_LEVEL_AUTOTRANSPORT     (LOG_FLAG_AUTOTRANSPORT | LOG_FLAG_HTTPTRANSPORT | LOG_FLAG_SERVERSENTEVENTS | LOG_FLAG_LONGPOLLING | LOG_FLAG_CONNECTION  | LOG_FLAG_HTTP ) // 0...111111

#define LOG_HTTP                (ddLogLevel & LOG_FLAG_HTTP )
#define LOG_CONNECTION          (ddLogLevel & LOG_FLAG_CONNECTION )
#define LOG_LONGPOLLING         (ddLogLevel & LOG_FLAG_LONGPOLLING  )
#define LOG_SERVERSENTEVENTS    (ddLogLevel & LOG_FLAG_SERVERSENTEVENTS)
#define LOG_HTTPTRANSPORT       (ddLogLevel & LOG_FLAG_HTTPTRANSPORT  )
#define LOG_AUTOTRANSPORT       (ddLogLevel & LOG_FLAG_AUTOTRANSPORT )

static int ddLogLevel = LOG_LEVEL_OFF;

#define COCOA_LUMBER_JACK 0
#if COCOA_LUMBER_JACK

#import "DDLog.h"

#undef LOG_FLAG_ERROR
#undef LOG_FLAG_WARN
#undef LOG_FLAG_INFO
#undef LOG_FLAG_VERBOSE

#undef LOG_LEVEL_ERROR
#undef LOG_LEVEL_WARN
#undef LOG_LEVEL_INFO
#undef LOG_LEVEL_VERBOSE

#undef LOG_ERROR
#undef LOG_WARN
#undef LOG_INFO
#undef LOG_VERBOSE

#undef DDLogError
#undef DDLogWarn
#undef DDLogInfo
#undef DDLogVerbose

#undef DDLogCError
#undef DDLogCWarn
#undef DDLogCInfo
#undef DDLogCVerbose

#define SRLogHTTP(frmt, ...)                SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_HTTP,              0, frmt, ##__VA_ARGS__)
#define SRLogConnection(frmt, ...)          SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_CONNECTION,        0, frmt, ##__VA_ARGS__)
#define SRLogLongPolling(frmt, ...)         SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_LONGPOLLING,       0, frmt, ##__VA_ARGS__)
#define SRLogServerSentEvents(frmt, ...)    SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_SERVERSENTEVENTS,  0, frmt, ##__VA_ARGS__)
#define SRLogHTTPTransport(frmt, ...)       SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_HTTPTRANSPORT,     0, frmt, ##__VA_ARGS__)
#define SRLogAutoTransport(frmt, ...)       SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_AUTOTRANSPORT,     0, frmt, ##__VA_ARGS__)

#define SRLogCHTTP(frmt, ...)               SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_HTTP,             0, frmt, ##__VA_ARGS__)
#define SRLogCConnection(frmt, ...)         SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_CONNECTION,       0, frmt, ##__VA_ARGS__)
#define SRLogCLongPolling(frmt, ...)        SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_LONGPOLLING,      0, frmt, ##__VA_ARGS__)
#define SRLogCServerSentEvents(frmt, ...)   SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_SERVERSENTEVENTS, 0, frmt, ##__VA_ARGS__)
#define SRLogCHTTPTransport(frmt, ...)      SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_HTTPTRANSPORT,    0, frmt, ##__VA_ARGS__)
#define SRLogCAutoTransport(frmt, ...)      SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_AUTOTRANSPORT,    0, frmt, ##__VA_ARGS__)

#else

#define SRLogHTTP(fmt, ...) \
do{ \
    if(ddLogLevel & LOG_HTTP) \
        NSLog((@"Thread %@:%s [Line %d]\n[HTTP]    " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
} while(0)

#define SRLogConnection(fmt, ...) \
do{ \
    if(ddLogLevel & LOG_CONNECTION) \
        NSLog((@"Thread %@:%s [Line %d]\n[CONNECTION]    " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
} while(0)

#define SRLogLongPolling(fmt, ...) \
do{ \
    if(ddLogLevel & LOG_LONGPOLLING) \
        NSLog((@"Thread %@:%s [Line %d]\n[LONG_POLLING]    " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
} while(0)

#define SRLogServerSentEvents(fmt, ...) \
do{ \
    if(ddLogLevel & LOG_SERVERSENTEVENTS) \
        NSLog((@"Thread %@:%s [Line %d]\n[SERVER_SENT_EVENTS]    " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
} while(0)

#define SRLogHTTPTransport(fmt, ...) \
do{ \
    if(ddLogLevel & LOG_HTTPTRANSPORT) \
        NSLog((@"Thread %@:%s [Line %d]\n[HTTP_BASED_TRANSPORT]    " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
} while(0)

#define SRLogAutoTransport(fmt, ...) \
    do{ if(ddLogLevel & LOG_AUTOTRANSPORT) \
        NSLog((@"Thread %@:%s [Line %d]\n[AUTO_TRANSPORT]    " fmt), [NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
} while(0)

#endif