//
//  ChatContactsSynchronizer.h
//  chat21
//
//  Created by Andrea Sponziello on 09/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatSynchDelegate.h"

@import Firebase;
@class ChatUser;

@interface ChatContactsSynchronizer : NSObject

@property (strong, nonatomic) ChatUser * loggeduser;
@property (nonatomic, strong) FIRDatabaseReference * rootRef;
@property (strong, nonatomic) NSString * tenant;
@property (strong, nonatomic) FIRDatabaseReference * contactsRef;
@property (assign, nonatomic) FIRDatabaseHandle contact_ref_handle_added;
@property (assign, nonatomic) FIRDatabaseHandle contact_ref_handle_changed;
@property (assign, nonatomic) FIRDatabaseHandle contact_ref_handle_removed;
@property (strong, nonatomic) NSTimer * synchTimer;
@property (assign, nonatomic) BOOL synchronizing;
@property (strong) NSMutableArray<id<ChatSynchDelegate>> *synchSubscribers;

-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user;
-(void)startSynchro;
//-(void)stopSynchro;
//+(void)insertOrUpdateContactOnDB:(ChatUser *)user;
+(ChatUser *)contactFromDictionaryFactory:(NSDictionary *)snapshot;
-(void)dispose;
-(void)addSynchSubscriber:(id<ChatSynchDelegate>)subscriber;
-(void)removeSynchSubscriber:(id<ChatSynchDelegate>)subscriber;
+(ChatUser *)contactFromSnapshotFactory:(FIRDataSnapshot *)snapshot;

@end
