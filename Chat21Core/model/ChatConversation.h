//
//  ChatConversation.h
//  Soleto
//
//  Created by Andrea Sponziello on 22/11/14.
//
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

extern int const CONV_STATUS_FAILED;
extern int const CONV_STATUS_JUST_CREATED; // for group management
extern int const CONV_STATUS_LAST_MESSAGE;

extern NSString* __nonnull const CONV_LAST_MESSAGE_TEXT_KEY;
extern NSString* __nonnull const CONV_RECIPIENT_KEY;
extern NSString* __nonnull const CONV_SENDER_KEY;
extern NSString* __nonnull const CONV_SENDER_FULLNAME_KEY;
extern NSString* __nonnull const CONV_RECIPIENT_FULLNAME_KEY;
extern NSString* __nonnull const CONV_TIMESTAMP_KEY;
extern NSString* __nonnull const CONV_IS_NEW_KEY;
extern NSString* __nonnull const CONV_CONVERS_WITH_KEY;
extern NSString* __nonnull const CONV_CHANNEL_TYPE_KEY;
extern NSString* __nonnull const CONV_STATUS_KEY;
extern NSString* __nonnull const CONV_ATTRIBUTES_KEY;

@class ChatUser;

//@class Firebase;
//@class FDataSnapshot;

@interface ChatConversation : NSObject

@property (nonatomic, strong, nullable) NSString *key;
@property (nonatomic, strong, nullable) FIRDatabaseReference *ref;
@property (nonatomic, strong, nullable) NSString *conversationId;
@property (nonatomic, strong, nullable) NSString *user; // used to query conversations on local DB
@property (nonatomic, strong, nullable) NSString *last_message_text;
@property (nonatomic, assign) BOOL is_new;
@property (nonatomic, assign) BOOL archived;
@property (nonatomic, strong, nullable) NSDate *date;
@property (nonatomic, strong, nullable) NSString *sender;
@property (nonatomic, strong, nullable) NSString *senderFullname;
@property (nonatomic, strong, nullable) NSString *recipient;
@property (nonatomic, strong, nullable) NSString *recipientFullname;
@property (nonatomic, strong, nullable) NSString *conversWith;
@property (nonatomic, strong, nullable) NSString *conversWith_fullname;
@property (nonatomic, strong, nullable) NSString *channel_type;
@property (nonatomic, strong, nullable) NSString *thumbImageURL;
@property (nonatomic, assign) int status;
@property (nonatomic, assign) int indexInMemory;
@property (nonatomic, strong, nullable) NSDictionary *attributes; // firebase
@property (nonatomic, strong, nonnull) NSString *mtype; // firebase

@property (nonatomic, strong) NSDictionary * _Nullable snapshot;
@property (nonatomic, strong) NSString * _Nullable snapshotAsJSONString;

@property (nonatomic, assign) BOOL isDirect;

-(NSString *_Nullable)dateFormattedForListView;

-(NSString *_Nullable)textForLastMessage:(NSString *_Nonnull)me;

+(ChatConversation *_Nullable)conversationFromSnapshotFactory:(FIRDataSnapshot *_Nonnull)snapshot me:(ChatUser *_Nonnull)me;


@end
