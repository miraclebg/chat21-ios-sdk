//
//  ChatDB.h
//  Soleto
//
//  Created by Andrea Sponziello on 05/12/14.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ChatMessage;
@class ChatConversation;
@class ChatGroup;
//@class ChatUser;

@interface ChatDB : NSObject

@property (nonatomic, strong) NSString *databasePath;
@property (assign, nonatomic) BOOL logQuery;

+(ChatDB*)getSharedInstance;
//-(BOOL)createDB;
-(BOOL)createDBWithName:(NSString *)name;

// messages

-(void)updateMessageSynchronized:(NSString *)messageId withStatus:(int)status completion:(void(^)(BOOL success)) callback;
-(BOOL)updateMessage:(NSString *)messageId status:(int)status text:(NSString *)text snapshotAsJSONString:(NSString *)snapshotAsJSONString; // TODO hide. only call synchroninzed
-(void)removeAllMessagesForConversationSynchronized:(NSString *)conversationId completion:(void(^)(BOOL success)) callback;
-(void)insertMessageIfNotExistsSyncronized:(ChatMessage *)message completion:(void(^)(BOOL success)) callback;
-(void)getMessageByIdSyncronized:(NSString *)messageId completion:(void(^)(ChatMessage *)) callback;
-(void)getAllMessagesForConversationSyncronized:(NSString *)conversationId start:(int)start count:(int)count completion:(void(^)(NSArray *messages)) callback;
-(void)updateLastMessageInConversation:(NSString*)conversationId completion:(void(^)(BOOL success)) callback;
-(void)resetLastMessageInConversation:(NSString*)conversationId completion:(void(^)(BOOL success)) callback;
-(void)removeMessage:(NSString*)conversationId completion:(void(^)(BOOL success)) callback;

// conversations

-(void)insertOrUpdateConversationSyncronized:(ChatConversation *)conversation completion:(void(^)(BOOL success)) callback;
- (void)removeConversationSynchronized:(NSString *)conversationId completion:(void(^)(BOOL success)) callback;
- (void)getConversationByIdSynchronized:(NSString *)conversationId completion:(void(^)(ChatConversation *)) callback;
// NO SYNCH
- (NSArray*)getAllConversationsForUser:(NSString *)user archived:(BOOL)archived limit:(int)limit;

@end
