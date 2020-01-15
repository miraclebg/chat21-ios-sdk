//
//  ChatContactsDB.h
//
//
//  Created by Andrea Sponziello on 17/09/2017.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ChatMessage;
@class ChatConversation;
@class ChatGroup;
@class ChatUser;

@interface ChatContactsDB : NSObject

@property (nonatomic, strong) NSString *databasePath;
@property (assign, nonatomic) BOOL logQuery;

+(ChatContactsDB*)getSharedInstance;
-(BOOL)createDBWithName:(NSString *)name;

// contacts
-(void)insertOrUpdateContactSyncronized:(ChatUser *)contact completion:(void(^)(BOOL success)) callback;
-(void)getContactByIdSyncronized:(NSString *)contactId completion:(void(^)(ChatUser *)) callback;
-(void)getMultipleContactsByIdsSyncronized:(NSArray<NSString *> *)contactIds completion:(void(^)(NSArray<ChatUser *> *)) callback;
-(void)searchContactsByFullnameSynchronized:(NSString *)searchString completion:(void (^)(NSArray<ChatUser *> *))callback;
-(void)removeContactSynchronized:(NSString *)contactId completion:(void(^)(BOOL success)) callback;

-(void)getMostRecentContactSyncronizedWithCompletion:(void(^)(ChatUser *contact)) callback;
-(ChatUser *)getMostRecentContact;

-(NSArray*)getAllContacts;

@end


