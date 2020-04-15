//
//  ChatGroupsHandler.h
//  Smart21
//
//  Created by Andrea Sponziello on 02/05/15.
//
//

#import <Foundation/Foundation.h>
#import "ChatGroupsSubscriber.h"
#import "FirebaseDatabase/FIRDatabaseQuery.h"

@class FIRDatabaseReference;
@class FirebaseCustomAuthHelper;
@class Firebase;
@class ChatUser;
@class ChatGroup;

@interface ChatGroupsHandler : NSObject

@property (strong, nonatomic, nullable) ChatUser * loggeduser;
@property (strong, nonatomic, nullable) NSString *me;
@property (strong, nonatomic, nullable) FirebaseCustomAuthHelper *authHelper;
@property (strong, nonatomic, nullable) NSMutableDictionary *groups;
//@property (strong, nonatomic) NSMutableDictionary *groupsDictionary; // easy search by group_id

//@property (strong, nonatomic) NSMutableArray *groups;
@property (strong, nonatomic, nullable) NSString *firebaseToken;
@property (strong, nonatomic, nullable) FIRDatabaseReference *groupsRef;
@property (assign, nonatomic) FIRDatabaseHandle groups_ref_handle_added;
@property (assign, nonatomic) FIRDatabaseHandle groups_ref_handle_changed;
@property (assign, nonatomic) FIRDatabaseHandle groups_ref_handle_removed;
//@property (strong, nonatomic) NSString *firebaseRef;
@property (nonatomic, strong, nullable) FIRDatabaseReference *rootRef;
@property (strong, nonatomic, nullable) NSString *tenant;
@property (strong, nonnull) NSMutableArray<id<ChatGroupsSubscriber>> *subscribers;

//-(id)initWithFirebaseRef:(NSString *)firebaseRef tenant:(NSString *)tenant user:(SHPUser *)user;
-(id _Nonnull)initWithTenant:(NSString *_Nonnull)tenant user:(ChatUser *_Nonnull)user;
-(void)restoreGroupsFromDB;
-(void)connect;
-(void)dispose;
-(ChatGroup *_Nullable)groupById:(NSString *_Nonnull)groupId;
//-(void)insertOrUpdateGroup:(ChatGroup *)group;
-(void)insertOrUpdateGroup:(ChatGroup *_Nonnull)group completion:(void(^_Nullable)()) callback;
-(void)insertInMemory:(ChatGroup *_Nonnull)group;
//+(void)createGroupFromPushNotification:(ChatGroup *)group;
-(void)addSubscriber:(id<ChatGroupsSubscriber>_Nonnull)subscriber;
-(void)removeSubscriber:(id<ChatGroupsSubscriber>_Nonnull)subscriber;
@end

