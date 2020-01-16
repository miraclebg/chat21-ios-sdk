//
//  ChatManager.h
//  Soleto
//
//  Created by Andrea Sponziello on 20/12/14.
//
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@class ChatConversationHandler;
@class ChatConversationsHandler;
@class ChatGroupsHandler;
@class SHPUser;
@class ChatGroup;
@class FDataSnapshot;
@class ChatConversation;
@class ChatPresenceHandler;
@class ChatConversationsVC;
@class ChatUser;
@class ChatMessage;
@class ChatContactsSynchronizer;
@class ChatSpeaker;
@class ChatConversationHandler;
@class ChatConnectionStatusHandler;
@class ChatDiskImageCache;

static int const CHAT_LOG_LEVEL_ERROR = 0;
static int const CHAT_LOG_LEVEL_WARNING = 1;
static int const CHAT_LOG_LEVEL_INFO = 2;
static int const CHAT_LOG_LEVEL_DEBUG = 3;

typedef void (^ChatManagerCompletedBlock)(BOOL success, NSError *error);

@interface ChatManager : NSObject

// plist properties
@property (nonatomic, strong) NSString *tenant;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *archiveConversationURI;
@property (nonatomic, strong) NSString *archiveAndCloseSupportConversationURI;
@property (nonatomic, strong) NSString *deleteProfilePhotoURI;

@property (nonatomic, strong) ChatUser *loggedUser;
@property (nonatomic, strong) NSMutableDictionary<NSString*, ChatConversationHandler*> *handlers;
@property (nonatomic, strong) ChatConversationsHandler *conversationsHandler;
@property (nonatomic, strong) ChatPresenceHandler *presenceHandler;
@property (nonatomic, strong) ChatConnectionStatusHandler *connectionStatusHandler;
@property (nonatomic, strong) ChatGroupsHandler *groupsHandler;
@property (nonatomic, strong) ChatContactsSynchronizer *contactsSynchronizer;
@property (nonatomic, strong) ChatDiskImageCache *imageCache;
//@property (nonatomic, strong) ChatConversationsVC * conversationsVC;
@property (strong, nonatomic) FIRAuthStateDidChangeListenerHandle authStateDidChangeListenerHandle;
//@property (assign, nonatomic) FIRDatabaseHandle connectedRefHandle;
@property (assign, nonatomic) BOOL groupsMode;
@property (assign, nonatomic) BOOL synchronizeContacts;
@property (assign, nonatomic) NSInteger tabBarIndex;
@property (assign, nonatomic) NSInteger logLevel;

@property (nonatomic, copy) ChatMessage *(^onBeforeMessageSend)(ChatMessage *msg);
@property (nonatomic, copy) ChatMessage *(^onMessageNew)(ChatMessage *msg);
@property (nonatomic, copy) ChatMessage *(^onMessageUpdate)(ChatMessage *msg);
@property (nonatomic, copy) ChatConversation *(^onCoversationArrived)(ChatConversation *conv);
@property (nonatomic, copy) ChatConversation *(^onCoversationUpdated)(ChatConversation *conv);

+(void)configureWithAppId:(NSString *)app_id;
+(void)configure;
+(ChatManager *)getInstance;
-(void)getContactLocalDB:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback;
-(void)getUserInfoRemote:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback;

-(void)addConversationHandler:(ChatConversationHandler *)handler;
-(ChatConversationsHandler *)getAndStartConversationsHandler;
-(ChatConversationHandler *)getConversationHandlerForRecipient:(ChatUser *)recipient;
-(ChatConversationHandler *)getConversationHandlerForGroup:(ChatGroup *)group;
//-(void)startConversationHandler:(ChatConversation *)conv;

- (void)initPresenceHandler;

-(ChatConversationsHandler *)createConversationsHandler;
-(ChatPresenceHandler *)createPresenceHandler;
-(ChatGroupsHandler *)createGroupsHandlerForUser:(ChatUser *)user;
-(ChatContactsSynchronizer *)createContactsSynchronizerForUser:(ChatUser *)user;

//-(void)createGroupFromPushNotificationWithName:(NSString *)groupName groupId:(NSString *)groupId;
-(void)registerForNotifications:(NSData *)devToken;

-(void)startWithUser:(ChatUser *)user;
-(void)dispose;

// === GROUPS ===

// se errore aggiorna conversazione-gruppo locale (DB, creata dopo) con messaggio errore, stato "riprova" e menù "riprova" (vedi creazione gruppo whatsapp in modalità "aereo").

-(NSString *)newGroupId;
-(void)addMember:(NSString *)user_id toGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock;
-(void)removeMember:(NSString *)user_id fromGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock;
+(ChatGroup *)groupFromSnapshotFactory:(FIRDataSnapshot *)snapshot;
-(ChatGroup *)groupById:(NSString *)groupId;
-(void)createGroup:(ChatGroup *)group withCompletionBlock:(void (^)(ChatGroup *group, NSError* error))callback;
-(void)updateGroupName:(NSString *)name forGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock;
-(NSDictionary *)allGroups;

// === CONVERSATIONS ===

//-(void)createOrUpdateConversation:(ChatConversation *)conversation;
-(void)removeConversationForUser:(FIRDatabaseReference *)conversationRef userId:(NSInteger)otherUserId callback:(ChatManagerCompletedBlock)callback;
-(void)removeConversation:(ChatConversation *)conversation callback:(ChatManagerCompletedBlock)callback;
-(void)removeConversationFromDB:(NSString *)conversationId callback:(ChatManagerCompletedBlock)callback;
-(void)updateConversationIsNew:(FIRDatabaseReference *)conversationRef is_new:(int)is_new;

- (void)removeConversationMessage:(BOOL)removeBothMessages
                   conversationId:(NSString*)conversationId
                         senderId:(NSString*)senderId
                      recipientId:(NSString*)recipientId
                messagesRefSender:(FIRDatabaseReference *)messagesRefSender
              messagesRefReceiver:(FIRDatabaseReference *)messagesRefReceiver
                        messageId:(NSString*)messageId callback:(ChatManagerCompletedBlock)callback;

// === CONTACTS ===
-(void)createContactFor:(ChatUser *)user withCompletionBlock:(void (^)(NSError *))completionBlock;

-(void)removeInstanceId;
-(void)loadGroup:(NSString *)group_id completion:(void (^)(ChatGroup* group, BOOL error))callback;

// LOG
+(void)logDebug:(NSString*)text, ...;
+(void)logInfo:(NSString*)text, ...;
+(void)logError:(NSString*)text, ...;
+(void)logWarn:(NSString*)text, ...;

// profile image
// paths
+(NSString *)filePathOfProfile:(NSString *)profileId fileName:(NSString *)fileName;
+(NSString *)profileImagePathOf:(NSString *)profileId;
// URLs
+(NSString *)profileImageURLOf:(NSString *)profileId;
+(NSString *)profileThumbImageURLOf:(NSString *)profileId;
+(NSString *)fileURLOfProfile:(NSString *)profileId fileName:(NSString *)fileName;
+(NSString *)profileBaseURL:(NSString *)profileId;

@end

