//
//  ChatConnectionStatusHandler.h
//  chat21
//
//  Created by Andrea Sponziello on 01/01/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatEventType.h"
#import <Firebase/Firebase.h>

@interface ChatConnectionStatusHandler : NSObject

@property (strong, nonatomic) FIRDatabaseReference *connectedRef;
@property (assign, nonatomic) FIRDatabaseHandle connectedRefHandle;

-(void)isStatusConnectedWithCompletionBlock:(void (^)(BOOL connected, NSError* error))callback;

// observer
@property (strong, nonatomic) NSMutableDictionary *eventObservers;
@property (assign, atomic) volatile int64_t lastEventHandle;
@property (assign, atomic) volatile int32_t lastEventHandle32;
-(NSUInteger)observeEvent:(ChatConnectionStatusEventType)eventType withCallback:(void (^)())callback;
-(void)removeObserverWithHandle:(NSUInteger)event_handle;
-(void)removeAllObservers;

-(void)connect;
-(void)dispose;

@end
