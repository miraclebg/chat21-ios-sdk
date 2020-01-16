//
//  ChatConversationHandler.m
//  Soleto
//
//  Created by Andrea Sponziello on 19/12/14.
//

#import "ChatConversationHandler.h"
#import "ChatMessage.h"
#import "FirebaseCustomAuthHelper.h"
#import "ChatUtil.h"
#import "ChatDB.h"
#import "ChatConversation.h"
#import "ChatManager.h"
#import "ChatGroup.h"
#import "ChatUser.h"
#import <libkern/OSAtomic.h>
#import "ChatMessageMetadata.h"
#import "ChatImageDownloadManager.h"

@implementation ChatConversationHandler {
    dispatch_queue_t serialMessagesMemoryQueue;
}

-(id)init {
    if (self = [super init]) {
        [self basicInit];
    }
    return self;
}

-(void)basicInit {
    serialMessagesMemoryQueue = dispatch_queue_create("messagesQueue", DISPATCH_QUEUE_SERIAL);
    self.lastEventHandle = 1;
    self.lastEventHandle32 = 1;
    self.imageDownloader = [[ChatImageDownloadManager alloc] init];
}

-(id)initWithRecipient:(NSString *)recipientId recipientFullName:(NSString *)recipientFullName {
    if (self = [super init]) {
        [self basicInit];
        self.channel_type = MSG_CHANNEL_TYPE_DIRECT;
        self.recipientId = recipientId;
        self.recipientFullname = recipientFullName;
        self.user = [ChatManager getInstance].loggedUser;
        self.senderId = self.user.userId;
        self.conversationId = recipientId; //[ChatUtil conversationIdWithSender:user.userId receiver:recipient]; //conversationId;
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initWithGroupId:(NSString *)groupId groupName:(NSString *)groupName {
    if (self = [super init]) {
        [self basicInit];
        self.channel_type = MSG_CHANNEL_TYPE_GROUP;
        self.recipientId = groupId;
        self.recipientFullname = groupName;
        self.user = [ChatManager getInstance].loggedUser;
        self.senderId = self.user.userId;
        self.conversationId = groupId;
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dispose {
    [self.messagesRef removeAllObservers];
    [self removeAllObservers];
    self.messages_ref_handle = 0;
    self.updated_messages_ref_handle = 0;
}

-(void)restoreMessagesFromDBWithCompletion:(void(^)(void))callback {
    [ChatManager logDebug:@"RESTORING ALL MESSAGES FOR CONVERSATION %@", self.conversationId];
    [[ChatDB getSharedInstance] getAllMessagesForConversationSyncronized:self.conversationId start:0 count:200 completion:^(NSArray *messages) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *inverted_messages = [messages mutableCopy];
            NSEnumerator *enumerator = [inverted_messages reverseObjectEnumerator];
            for (id element in enumerator) {
                [self.messages addObject:element];
            }
            // set as status:"failed" all the messages in status: "sending"
            for (ChatMessage *m in self.messages) {
                if (m.status == MSG_STATUS_SENDING || m.status == MSG_STATUS_UPLOADING) {
                    m.status = MSG_STATUS_FAILED;
                }
            }
            callback();
        });
    }];
}

-(void)connect {
    // if already connected return
    if (self.messages_ref_handle) {
        return;
    }
    self.messagesRef = [ChatUtil conversationMessagesRef:self.recipientId];
    self.conversationOnSenderRef = [ChatUtil conversationRefForUser:self.senderId conversationId:self.conversationId];
    self.conversationOnReceiverRef = [ChatUtil conversationRefForUser:self.recipientId conversationId:self.conversationId];
    
    NSInteger lasttime = 0;
    if (self.messages && self.messages.count > 0) {
        ChatMessage *message = [self.messages lastObject];
        [ChatManager logDebug:@"****** MOST RECENT MESSAGE TIME %@ %@", message, message.date];
        lasttime = message.date.timeIntervalSince1970 * 1000; // objc returns time in seconds, firebase saves time in milliseconds. queryStartingAtValue: will respond to events at nodes with a value greater than or equal to startValue. So seconds is always < then milliseconds. * 1000 translates seconds in millis and the query is ok.
    } else {
        lasttime = 0;
    }
    
    self.messages_ref_handle = [[[[self.messagesRef queryOrderedByChild:@"timestamp"] queryStartingAtValue:@(lasttime)] queryLimitedToLast:40] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        // IMPORTANT: this query ignores messages without a timestamp.
        // IMPORTANT: This callback is called also for newly locally created messages still not sent.
        [ChatManager logDebug:@"NEW MESSAGE SNAPSHOT: %@", snapshot];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [ChatManager logDebug:@"Asynch message processing pipeline started...."];
            if (![self isValidMessageSnapshot:snapshot]) {
                [ChatManager logDebug:@"New Message handler. Discarding invalid snapshot: %@", snapshot];
                return;
            }
            else {
                [ChatManager logDebug:@"New Message handler. Valid snapshot."];
            }
            ChatMessage *message = [ChatMessage messageFromfirebaseSnapshotFactory:snapshot];
            message.conversationId = self.conversationId; // DB query is based on this attribute!!! (conversationID = Recipient)
            ChatManager *chatm = [ChatManager getInstance];
            if (chatm.onMessageNew) {
                message = chatm.onMessageNew(message);
                if (message == nil) {
                    [ChatManager logDebug:@"Handler returned null Message. Stopping pipeline."];
                    return;
                }
            }
            // This callback is also invoked by newly locally created messages (not still sent, also with network offline).
            // Then, for every "new" message received (also locally generated) we update onversation status to "read" (is_new = false).
            // Updates status only of messages not sent by me
            if (message.status < MSG_STATUS_RECEIVED && ![message.sender isEqualToString:self.senderId]) {
                // VERIFY... "message.status < MSG_STATUS_RECEIVED" IN ORDER TO AVOID THE COST OF RE-UPDATING CONTINUOUSLY THE STATE OF MESSAGES THAT ALREADY HAVE THE "RECEIVED" STATE (IT MAY BE THE SYNCHRONIZATION OF A NEW DEVICE THAT MUST NO LONGER COMMUNICATE ANYTHING TO THE SENDER BUT ONLY DOWNLOAD THE MESSAGES IN THE STATE IN WHICH THEY ARE FOUND).
                // NOT RECEIVED = NEW!
                if (message.isDirect) {
                    [message updateStatusOnFirebase:MSG_STATUS_RECEIVED]; // firebase
                } else {
                    // TODO: implement received status for group's messages
                }
            }
            // updates or inserts new messages
            // This check is necessary to avoid this message notified as "new" (...playing sound etc.)
            [self insertMessageIfNotExists:message completion:^{
                [ChatManager logDebug:@"New message saved. Notiying to subscribers..."];
                [self notifyEvent:ChatEventMessageAdded message:message];
            }];
        });
    } withCancelBlock:^(NSError *error) {
        [ChatManager logError:@"%@", error.description];
    }];
    
    self.updated_messages_ref_handle = [self.messagesRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        [ChatManager logDebug:@"UPDATED MESSAGE SNAPSHOT: %@", snapshot];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (![self isValidMessageSnapshot:snapshot]) {
                [ChatManager logDebug:@"Message Updated. Discarding invalid snapshot: %@", snapshot];
                return;
            }
            else {
                [ChatManager logDebug:@"Message Updated. Valid snapshot: %@", snapshot];
            }
            ChatMessage *message = [ChatMessage messageFromfirebaseSnapshotFactory:snapshot];
            ChatManager *chatm = [ChatManager getInstance];
            if (chatm.onMessageUpdate) {
                [ChatManager logDebug:@"onMessageUpdate found. Executing."];
                message = chatm.onMessageUpdate(message);
                if (message == nil) {
                    [ChatManager logDebug:@"onMessageUpdate returned null. Stopping update pipeline."];
                    return;
                }
                [ChatManager logDebug:@"onMessageUpdate successfully ended."];
            }
            if (message.status == MSG_STATUS_SENDING || message.status == MSG_STATUS_SENT || message.status == MSG_STATUS_RETURN_RECEIPT) {
                [[ChatDB getSharedInstance] getMessageByIdSyncronized:message.messageId completion:^(ChatMessage *saved_message) {
                    if (saved_message) {
                        [self updateMessageStatusSynchronized:message.messageId withStatus:message.status completion:^{
                            [self notifyEvent:ChatEventMessageChanged message:message];
                        }];
                    }
                    else {
                        [self insertMessageIfNotExists:message completion:^{
                            [self notifyEvent:ChatEventMessageAdded message:message];
                        }];
                    }
                }];
            }
        });
    } withCancelBlock:^(NSError *error) {
        [ChatManager logError:@"%@", error.description];
    }];
    
    self.messagesToDeleteRef = [[[self.messagesRef parent] parent] child:@"messagesToDelete"];
    
    [self.messagesToDeleteRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary *vals = snapshot.value;
        
        // delete all previously deleted messages from local cache
        // then wipe all data in this key
        if ([vals isKindOfClass:[NSDictionary class]]) {
            NSArray *messageIds = vals.allKeys;
            
            for(NSString *messageId in messageIds) {
                [self removeMessageFromMemory:messageId];
                
#warning fixme
                //  [[ChatDB getSharedInstance] removeMessage:messageId];
                
                ChatMessage *cm = [ChatMessage new];
                cm.messageId = messageId;
                [self notifyEvent:ChatEventMessageDeleted message:cm];
            }
        }
        
        [self.messagesToDeleteRef removeValue];
    }];
    
    self.deleted_messages_ref_handle = [self.messagesRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        //NSLog(@"UPDATED MESSAGE SNAPSHOT: %@", snapshot);
        if (![self isValidMessageSnapshot:snapshot]) {
            //NSLog(@"Discarding invalid snapshot: %@", snapshot);
            return;
        }
        
        ChatMessage *message = [ChatMessage messageFromfirebaseSnapshotFactory:snapshot];
        
        [self removeMessageFromMemory:message.messageId];
        
        [[ChatDB getSharedInstance] removeMessage:message.messageId completion:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self notifyEvent:ChatEventMessageDeleted message:message];
                });
            }
        }];
        
    } withCancelBlock:^(NSError *error) {
        //NSLog(@"%@", error.description);
    }];
}

-(void)insertMessageIfNotExists:(ChatMessage *)message completion:(void(^)(void)) callback {
    [[ChatDB getSharedInstance] insertMessageIfNotExistsSyncronized:message completion:^(BOOL success) {
        if (success) {
            // TODO! Serial queue needed to avoid conflicting in writing on the same, shared, object!
            [self insertMessageInMemoryIfNotExists:message completion:^{
                if (callback != nil) callback();
            }];
        } else {
            if (callback) {
                callback();
            }
        }
    }];
}

-(BOOL)isValidMessageSnapshot:(FIRDataSnapshot *)snapshot {
    // TODO VALIDATE ALSO THE OPTIONAL "ATTRIBUTES" SECTION. IF EXISTS MUST BE A "DICTIONARY"
    if (snapshot.value[MSG_FIELD_TYPE] == nil) {
        [ChatManager logDebug:@"MSG:TYPE is mandatory. Discarding message."];
        return NO;
    }
    else if (snapshot.value[MSG_FIELD_TEXT] == nil) {
        [ChatManager logDebug:@"MSG:TEXT is mandatory. Discarding message."];
        return NO;
    }
    else if (snapshot.value[MSG_FIELD_SENDER] == nil) {
        [ChatManager logDebug:@"MSG:SENDER is mandatory. Discarding message."];
        return NO;
    }
    else if (snapshot.value[MSG_FIELD_TIMESTAMP] == nil) {
        [ChatManager logDebug:@"MSG:TIMESTAMP is mandatory. Discarding message."];
        return NO;
    }
    //    else if (snapshot.value[MSG_FIELD_STATUS] == nil) {
    //        NSLog(@"MSG:STATUS is mandatory. Discarding message.");
    //        return NO;
    //    }
    
    return YES;
}

-(ChatMessage *)newBaseMessage {
    ChatMessage *message = [[ChatMessage alloc] init];
    FIRDatabaseReference *messageRef = [self.messagesRef childByAutoId]; // CHILD'S AUTOGEN UNIQUE ID
    message.messageId = messageRef.key;
    message.sender = self.senderId;
    message.senderFullname = self.user.fullname;
    NSDate *now = [[NSDate alloc] init];
    message.date = now;
    message.status = MSG_STATUS_SENDING;
    message.conversationId = self.conversationId; // = intelocutor-id, for local-db queries
    NSString *langID = [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode];
    message.lang = langID;
    return message;
}

//-(void)sendMessage:(NSString *)text image:(UIImage *)image binary:(NSData *)data type:(NSString *)type attributes:(NSDictionary *)attributes {

-(void)appendImagePlaceholderMessageWithImage:(UIImage *)image attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    // TODO: validate metadata > specialize for image: ChatMessageImageMetadata to simplify validation
    ChatMessage *message = [self newBaseMessage];
    
    // save image
    NSString *image_file_name = message.imageFilename;
    [self saveImageToRecipientMediaFolderAsPNG:image imageFileName:image_file_name];
    ChatMessageMetadata *imageMetadata = [[ChatMessageMetadata alloc] init];
    imageMetadata.width = image.size.width;
    imageMetadata.height = image.size.height;
    
    message.status = MSG_STATUS_UPLOADING;
    message.text = [[NSString alloc] initWithFormat:@"Uploading image: %@...", image_file_name];
    message.mtype = MSG_TYPE_IMAGE;
    message.metadata = imageMetadata;
    message.attributes = [attributes mutableCopy];
    message.recipient = self.recipientId;
    message.recipientFullName = self.recipientFullname;
    message.channel_type = self.channel_type;
    [self createLocalMessage:message completion:^(NSString *messageId, NSError *error) {
        message.messageId = messageId;
        [self notifyEvent:ChatEventMessageAdded message:message];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(message, nil);
        });
    }];
}

-(void)sendImagePlaceholderMessage:(ChatMessage *)message completion:(void (^)(ChatMessage *, NSError *))callback {
    [[ChatDB getSharedInstance] updateMessage:message.messageId status:MSG_STATUS_SENDING text:message.text snapshotAsJSONString:message.snapshotAsJSONString];
    [self updateMessageInMemory:message.messageId status:MSG_STATUS_SENDING text:message.text imageURL:message.metadata.src]; // TODO. in memory save synchronized, queued on a background thread
    [self notifyEvent:ChatEventMessageChanged message:message];
    [self sendMessage:message completion:^(ChatMessage *message, NSError *error) {
        callback(message, error);
    }];
}

-(void)sendTextMessage:(NSString *)text completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    [self sendTextMessage:text
                  subtype:nil
               attributes:nil
               completion:^(ChatMessage *m, NSError *error) {
        callback(m, error);
    }
     ];
}

-(void)sendTextMessage:(NSString *)text subtype:(NSString *)subtype attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    [self sendMessageType:MSG_TYPE_TEXT
                  subtype:nil
                     text:text
                 imageURL:nil
                 metadata:nil
               attributes:attributes
               completion:^(ChatMessage *m, NSError *error) {
        callback(m, error);
    }
     ];
}

-(void)sendMessageType:(NSString *)type subtype:(NSString *)subtype text:(NSString *)text imageURL:(NSString *)imageURL metadata:(ChatMessageMetadata *)metadata attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    ChatMessage *message = [self newBaseMessage];
    [ChatManager logDebug:@"Created base message type: %@ with id: %@", message.mtype, message.messageId];
    if (text) {
        message.text = text;
    }
    if (imageURL) {
        message.metadata.src = imageURL;
    }
    message.mtype = type;
    if (subtype) {
        message.subtype = subtype;
    }
    if (metadata) {
        message.metadata = metadata;
    }
    message.attributes = [attributes mutableCopy];
    message.recipient = self.recipientId;
    message.recipientFullName = self.recipientFullname;
    message.channel_type = self.channel_type;
    // ON-BEFORE-MESSAGE-SAVE (IMPLEMENT) > I.E. SAVE ENCRYPTED
    [self createLocalMessage:message completion:^(NSString *messageId, NSError *error) {
        [ChatManager logDebug:@"Sending message type: %@ with id: %@", message.mtype, message.messageId];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self sendMessage:message completion:^(ChatMessage *message, NSError *error) {
                callback(message, error);
            }];
        });
    }];
}

-(void)sendMessage:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    ChatManager *chatm = [ChatManager getInstance];
    if (chatm.onBeforeMessageSend) {
        message = chatm.onBeforeMessageSend(message);
    }
    
    // custom handler can return a status = failed
    if (message.status == MSG_STATUS_SENDING) {
        if ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
            [ChatManager logDebug:@"Sending Group message. User: %@", [FIRAuth auth].currentUser.uid];
            [self sendMessageToGroup:message completion:^(ChatMessage *m, NSError *error) {
                callback(m, error);
            }];
        } else {
            [ChatManager logDebug:@"Sending Direct message. User: %@", [FIRAuth auth].currentUser.uid];
            [self sendDirect:message completion:^(ChatMessage *m, NSError *error) {
                callback(m, error);
            }];
        }
    }
    else { // status != sending stops sending pipeline
        [self updateMessageStatusInMemorySynchronized:message.messageId withStatus:message.status completion:^{
            [self notifyEvent:ChatEventMessageChanged message:message];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(message, nil);
            });
        }];
    }
}

-(void)createLocalMessage:(ChatMessage *)message completion:(void(^)(NSString *messageId, NSError *error))callback {
    // save message locally
    [[ChatDB getSharedInstance] insertMessageIfNotExistsSyncronized:message completion:^(BOOL success) {
        if (success) {
            [self insertMessageInMemoryIfNotExists:message completion:^{
                [self notifyEvent:ChatEventMessageAdded message:message];
                
                if (callback) {
                    callback(message.messageId, nil);
                }
            }];
        } else {
            if (callback) {
                callback(nil, [NSError new]);
            }
        }
    }];
}

-(void)sendDirect:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error))callback {
    // create firebase reference
    FIRDatabaseReference *messageRef = [self.messagesRef child:message.messageId];
    
    // save message to firebase
    NSMutableDictionary *message_dict = [message asFirebaseMessage];
    [ChatManager logDebug:@"Sending message to Firebase: %@ %@ %d", message.text, message.messageId, message.status];
    [messageRef setValue:message_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        [ChatManager logDebug:@"messageRef.setValue callback. %@", message_dict];
        if (error) {
            [ChatManager logError:@"Data could not be saved because of an occurred error: %@", error];
            int status = MSG_STATUS_FAILED;
            [self updateMessageStatusInMemorySynchronized:message.messageId withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(message, error);
                });
            }];
        } else {
            [ChatManager logDebug:@"Data saved successfully. Updating status & reloading tableView."];
            int status = MSG_STATUS_SENT;
            NSAssert([ref.key isEqualToString:message.messageId], @"REF.KEY %@ different by MESSAGE.ID %@",ref.key, message.messageId);
            [self updateMessageStatusInMemorySynchronized:message.messageId withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(message, error);
                });
            }];
        }
    }];
}

-(void)updateMessageStatus:(int)status forMessage:(ChatMessage *)message {
    [self updateMessageStatusInMemorySynchronized:message.messageId withStatus:status completion:^{
        [self updateMessageStatusOnDB:message.messageId withStatus:status];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyEvent:ChatEventMessageChanged message:message];
        });
    }];
}

-(void)sendMessageToGroup:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error))callback {
    // create firebase reference
    FIRDatabaseReference *messageRef = [self.messagesRef child:message.messageId];
    // save message to firebase
    NSMutableDictionary *message_dict = [message asFirebaseMessage];
    [ChatManager logDebug:@"(Group) Sending message to Firebase:(%@) %@ %@ %d dict: %@",messageRef, message.text, message.messageId, message.status, message_dict];
    [messageRef setValue:message_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        [ChatManager logDebug:@"messageRef.setValue callback. %@", message_dict];
        if (error) {
            [ChatManager logError:@"Data could not be saved with error: %@", error];
            int status = MSG_STATUS_FAILED;
            [self updateMessageStatusInMemorySynchronized:ref.key withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(callback != nil) callback(message, error);
                });
            }];
        } else {
            [ChatManager logDebug:@"Data saved successfully. Updating status & reloading tableView."];
            int status = MSG_STATUS_SENT;
            [self updateMessageStatusInMemorySynchronized:ref.key withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(callback != nil) callback(message, error);
                });
            }];
        }
    }];
}

// Updates a just-sent memory-message with the new status: MSG_STATUS_FAILED or MSG_STATUS_SENT
-(void)updateMessageStatusInMemorySynchronized:(NSString *)messageId withStatus:(int)status completion:(void(^)(void))callback {
    dispatch_async(serialMessagesMemoryQueue, ^{
        ChatMessage *message = [self findMessageInMemoryById:messageId];
        message.status = status;
        if (callback != nil) callback();
    });
}

-(void)updateMessageInMemory:(NSString *)messageId status:(int)status text:(NSString *)text imageURL:(NSString *)imageURL {
    ChatMessage *m = [self findMessageInMemoryById:messageId];
    m.status = status;
    m.text = text;
    m.metadata.src = imageURL;
}

-(ChatMessage *)findMessageInMemoryById:(NSString *)messageId {
    for (ChatMessage* msg in self.messages) {
        if([msg.messageId isEqualToString: messageId]) {
            return msg;
        }
    }
    return nil;
}

-(void)updateMessageStatusOnDB:(NSString *)messageId withStatus:(int)status {
    [[ChatDB getSharedInstance] updateMessageSynchronized:messageId withStatus:status completion:nil];
}

-(void)insertMessageOnDBIfNotExists:(ChatMessage *)message {
    [[ChatDB getSharedInstance] insertMessageIfNotExistsSyncronized:message completion:nil];
}

-(void)insertMessageInMemoryIfNotExists:(ChatMessage *)message completion:(void(^)(void))callback {
    dispatch_async(serialMessagesMemoryQueue, ^{
        // find message...
        BOOL found = NO;
        for (ChatMessage* msg in self.messages) {
            if([msg.messageId isEqualToString: message.messageId]) {
                [ChatManager logDebug:@"message found, skipping insert"];
                found = YES;
                break;
            }
        }
        
        if (found) {
            return;
        }
        else {
            NSUInteger newIndex = [self.messages indexOfObject:message
                                                 inSortedRange:(NSRange){0, [self.messages count]}
                                                       options:NSBinarySearchingInsertionIndex
                                               usingComparator:^NSComparisonResult(id a, id b) {
                NSDate *first = [(ChatMessage *)a date];
                NSDate *second = [(ChatMessage *)b date];
                return [first compare:second];
            }];
            [self.messages insertObject:message atIndex:newIndex];
        }
        if (callback != nil) callback();
    });
}

-(void)removeMessageFromMemory:(NSString*)messageId {
    // find message...
    NSInteger index = NSNotFound;
    NSInteger i = 0;
    
    for (ChatMessage* msg in self.messages) {
        if([msg.messageId isEqualToString:messageId]) {
            index = i;
            break;
        }
        i++;
    }
    
    if (index == NSNotFound) {
        return;
    }
    
    [self.messages removeObjectAtIndex:index];
}

// observer

-(void)notifyEvent:(ChatMessageEventType)event message:(ChatMessage *)message {
    if (!self.eventObservers) {
        return;
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(event)];
    if (!eventCallbacks) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSNumber *event_handle_key in eventCallbacks.allKeys) {
            void (^callback)(ChatMessage *message) = [eventCallbacks objectForKey:event_handle_key];
            callback(message);
        }
    });
}

// v2

-(NSUInteger)observeEvent:(ChatMessageEventType)eventType withCallback:(void (^)(ChatMessage *message))callback {
    if (!self.eventObservers) {
        self.eventObservers = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(eventType)];
    if (!eventCallbacks) {
        eventCallbacks = [[NSMutableDictionary alloc] init];
        [self.eventObservers setObject:eventCallbacks forKey:@(eventType)];
    }
    NSUInteger callback_handle = (NSUInteger) OSAtomicIncrement64Barrier(&_lastEventHandle);
    [eventCallbacks setObject:callback forKey:@(callback_handle)];
    return callback_handle;
}

-(void)removeObserverWithHandle:(NSUInteger)event_handle {
    if (!self.eventObservers) {
        return;
    }
    
    // iterate all keys (events)
    for (NSNumber *event_key in self.eventObservers) {
        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
        [eventCallbacks removeObjectForKey:@(event_handle)];
    }
}

-(void)removeAllObservers {
    if (!self.eventObservers) {
        return;
    }
    
    // iterate all keys (events)
    for (NSNumber *event_key in self.eventObservers) {
        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
        [eventCallbacks removeAllObjects];
    }
}

+(NSString *)mediaFolderPathOfRecipient:(NSString *)recipiendId {
    // path: chatConversationsMedia/{recipient-id}/media/{image-name}
    NSURL *urlPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *mediaPath = [[[urlPath.path stringByAppendingPathComponent:@"chatConversationsMedia"] stringByAppendingPathComponent:recipiendId] stringByAppendingPathComponent:@"media"];
    return mediaPath;
}

-(NSString *)mediaFolderPath {
    return [ChatConversationHandler mediaFolderPathOfRecipient:self.recipientId];
}

-(void)saveImageToRecipientMediaFolderAsPNG:(UIImage *)image imageFileName:(NSString *)imageFileName {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *mediaPath = [self mediaFolderPath];
    if (![filemgr fileExistsAtPath:mediaPath]) {
        NSError *error;
        [filemgr createDirectoryAtPath:mediaPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            [ChatManager logError:@"error creating mediaPath folder (%@): %@",mediaPath, error];
        }
    }
    NSString *imagePath = [mediaPath stringByAppendingPathComponent:imageFileName];
    [ChatManager logDebug:@"Image path: %@", imagePath];
    NSError *error;
    [UIImagePNGRepresentation(image) writeToFile:imagePath options:NSDataWritingAtomic error:&error];
    [ChatManager logDebug:@"error saving image to media path (%@): %@",imagePath, error];
    // test
    if ([filemgr fileExistsAtPath: imagePath ] == NO) {
        [ChatManager logError:@"Error. Image not saved."];
    }
    else {
        [ChatManager logDebug:@"Image saved to gallery."];
    }
    //    NSArray *directoryList = [filemgr contentsOfDirectoryAtPath:mediaPath error:nil];
    //    for (id file in directoryList) {
    //        NSLog(@"file: %@", file);
    //    }
}

@end
