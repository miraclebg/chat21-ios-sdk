//
//  ChatGroup.h
//  Smart21
//
//  Created by Andrea Sponziello on 27/03/15.
//
//

#import <Foundation/Foundation.h>

static NSString* const NOTIFICATION_TYPE_MEMBER_ADDED_TO_GROUP = @"group_member_added";
static NSString* const GROUP_OWNER = @"owner";
static NSString* const GROUP_CREATEDON = @"createdOn";
static NSString* const GROUP_NAME = @"name";
static NSString* const GROUP_MEMBERS = @"members";
static NSString* const GROUP_ICON_ID = @"iconID";

@class FDataSnapshot;
@class FIRDatabaseReference;
@class HelloApplicationContext;
@class ChatUser;

@interface ChatGroup : NSObject

@property (nonatomic, strong) NSString *key;
//@property (nonatomic, strong) Firebase *ref;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSString *tempId;
@property (nonatomic, strong) NSString *user; // used to query groups on local DB ( DB partioning by user )
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *owner;
//@property (nonatomic, strong) NSString *iconID;
@property (nonatomic, strong) NSDate *createdOn;
@property (nonatomic, strong) NSMutableDictionary *members;
@property (nonatomic, strong) NSArray<ChatUser *> *membersFull;
//@property (assign, nonatomic) BOOL completeData;
@property (assign, nonatomic) BOOL imAdmin;

//-(NSString *)iconUrl;
-(FIRDatabaseReference *)reference;
-(NSString *)memberPath:(NSString *)memberId;
-(FIRDatabaseReference *)memberReference:(NSString *)memberId;
-(BOOL)isMember:(NSString *)user_id;
-(NSMutableDictionary *)asDictionary;
+(NSMutableDictionary *)membersArray2Dictionary:(NSArray *)membersIds;
+(NSMutableArray *)membersDictionary2Array:(NSDictionary *)membersDict;
+(NSString *)membersDictionary2String:(NSDictionary *)membersDictionary;
+(NSMutableDictionary *)membersString2Dictionary:(NSString *)membersString;
-(NSString *)ownerFullname;
-(void)completeGroupMembersMetadataWithCompletionBlock:(void(^)(void)) callback;
-(id)initWithGroupId:(NSString *)groupId name:(NSString *)name;

@end
