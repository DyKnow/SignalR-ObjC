//
//  SRSignalRConfig.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 1/29/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

// ======
// Debug output configuration options
// ======

// If defined will use the specified function for debug logging
// Otherwise use NSLog
#ifndef SR_DEBUG_LOG
    #define SR_DEBUG_LOG NSLog
#endif

// When set to 1 SignalR will print information about what the connection is doing
#ifndef DEBUG_CONNECTION
    #define DEBUG_CONNECTION 0
#endif

// When set to 1 SignalR will print information about what the active transport is doing
#ifndef DEBUG_HTTP_BASED_TRANSPORT
    #define DEBUG_HTTP_BASED_TRANSPORT 0
#endif

// When set to 1 SignalR will print information about what the auto transport is doing
#ifndef DEBUG_AUTO_TRANSPORT
    #define DEBUG_AUTO_TRANSPORT 0
#endif

// When set to 1 SignalR will print information about what the SeverSentEvents Transport is doing
#ifndef DEBUG_SERVER_SENT_EVENTS
    #define DEBUG_SERVER_SENT_EVENTS 0
#endif

// When set to 1 SignalR will print information about what the LongPolling Transport is doing
#ifndef DEBUG_LONG_POLLING
    #define DEBUG_LONG_POLLING 0
#endif

// When set to 1 SignalR will print information about the contents of the messages being sent to the server
#ifndef DEBUG_HTTP_HELPER
    #define DEBUG_HTTP_HELPER 0
#endif

