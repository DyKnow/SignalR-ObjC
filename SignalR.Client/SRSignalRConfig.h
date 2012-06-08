//
//  SRSignalRConfig.h
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

#import <Foundation/Foundation.h>

/**
 * `SRSignalRConfig` is intended to be used for debugging the SignalR Client.
 * 
 * @warning For the most verbose logging set DEBUG_CONNECTION, DEBUG_HTTP_BASED_TRANSPORT, and DEBUG_HTTP_HELPER to 1
 */

///-------------------------------
/// @name Debug output configuration options
///-------------------------------

/**
 * If defined will use the specified function for debug logging otherwise NSLog will be used
 */
#ifndef SR_DEBUG_LOG
    #define SR_DEBUG_LOG NSLog
#endif

/**
 * When set to 1 SignalR will print information about what the connection is doing
 */
#ifndef DEBUG_CONNECTION
    #define DEBUG_CONNECTION 0
#endif

/**
 * When set to 1 SignalR will print information about what the active transport is doing
 */
#ifndef DEBUG_HTTP_BASED_TRANSPORT
    #define DEBUG_HTTP_BASED_TRANSPORT 0
#endif

/**
 * When set to 1 SignalR will print information about what the auto transport is doing
 */
#ifndef DEBUG_AUTO_TRANSPORT
    #define DEBUG_AUTO_TRANSPORT 0
#endif

/**
 * When set to 1 SignalR will print information about what the ServerSentEvents Transport is doing
 */
#ifndef DEBUG_SERVER_SENT_EVENTS
    #define DEBUG_SERVER_SENT_EVENTS 0
#endif

/**
 * When set to 1 SignalR will print information about what the LongPolling Transport is doing
 */
#ifndef DEBUG_LONG_POLLING
    #define DEBUG_LONG_POLLING 0
#endif

/**
 * When set to 1 SignalR will print information about the contents of the messages being sent to the server
 */
#ifndef DEBUG_HTTP_HELPER
    #define DEBUG_HTTP_HELPER 0
#endif

