//
//  ChatConversation.m
//  Soleto
//
//  Created by Andrea Sponziello on 22/11/14.
//
//

#import "ChatConversation.h"
//#import "ChatDB.h"
#import "ChatUser.h"
#import "ChatUtil.h"
#import "ChatMessage.h"
#import "Common.h"
#import "ChatManager.h"
#import <Firebase/Firebase.h>

@implementation ChatConversation

-(NSString *)dateFormattedForListView {
    NSString *date = [ChatUtil timeFromNowToStringFormattedForConversation:self.date];
    return date;
}

-(NSString *)textForLastMessage:(NSString *)me {
    if ([self.sender isEqualToString:me]) {
        NSString *you = [LI18n localizedString:@"You"];
        return [[NSString alloc] initWithFormat:@"%@: %@", you, self.last_message_text];
    } else {
        return self.last_message_text;
    }
}

-(FIRDatabaseReference *)ref {
    NSString *conversations_path;
    if (self.archived) {
        conversations_path = [ChatUtil archivedConversationsPathForUserId:self.user];
    }
    else {
        conversations_path = [ChatUtil conversationsPathForUserId:self.user];
    }
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *ref = [[rootRef child: conversations_path] child:self.conversationId];
    //NSLog(@"Conversation ref: %@", ref);
    return ref;
}

+(ChatConversation *)conversationFromSnapshotFactory:(FIRDataSnapshot *)snapshot me:(ChatUser *)me {
    NSString *text = snapshot.value[CONV_LAST_MESSAGE_TEXT_KEY];
    NSString *recipient = snapshot.value[CONV_RECIPIENT_KEY];
    NSString *sender = snapshot.value[CONV_SENDER_KEY];
    NSString *senderFullname = snapshot.value[CONV_SENDER_FULLNAME_KEY];
    NSString *recipientFullname = snapshot.value[CONV_RECIPIENT_FULLNAME_KEY];
    NSString *channel_type = snapshot.value[CONV_CHANNEL_TYPE_KEY];
    //    NSString *groupId = snapshot.value[CONV_GROUP_ID_KEY];
    //    NSString *groupName = snapshot.value[CONV_GROUP_NAME_KEY];
    NSNumber *timestamp = snapshot.value[CONV_TIMESTAMP_KEY];
    NSNumber *is_new = snapshot.value[CONV_IS_NEW_KEY];
    NSNumber *status = snapshot.value[CONV_STATUS_KEY];
    NSMutableDictionary *attributes = snapshot.value[CONV_ATTRIBUTES_KEY];
    
    NSString *conversWith = nil;
    NSString *conversWithFullName = nil;
    if ([channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
        conversWith = recipient;
        conversWithFullName = recipientFullname;
    }
    else { // direct
        if ([me.userId isEqualToString:sender]) {
            conversWith = recipient;
            conversWithFullName = recipientFullname;
        }
        else {
            conversWith = sender;
            conversWithFullName = senderFullname;
        }
    }
    
    ChatConversation *conversation = [[ChatConversation alloc] init];
    conversation.key = snapshot.key;
    conversation.ref = snapshot.ref;
    conversation.conversationId = snapshot.key;
    conversation.last_message_text = text;
    conversation.recipient = recipient;
    conversation.recipientFullname = recipientFullname;
    conversation.sender = sender;
    conversation.senderFullname = senderFullname;
    conversation.date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue/1000];
    conversation.is_new = [is_new boolValue];
    conversation.conversWith = conversWith;
    conversation.conversWith_fullname = conversWithFullName;
    conversation.channel_type = channel_type;
    //    conversation.groupId = groupId;
    //    conversation.groupName = groupName;
    conversation.status = (int)[status integerValue];
    conversation.attributes = attributes;
    conversation.user = me.userId;
    return conversation;
}

-(BOOL)isDirect {
    //    //NSLog(@"conv: %@, self.channel_type: %@",self.last_message_text, self.channel_type);
    return ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_DIRECT] || self.channel_type == nil) ? YES : NO;
}

/*
 -(NSString *)thumbImageURL {
 if (!self.isDirect) {
 NSString *groupId = self.recipient;
 return [ChatManager profileThumbImageURLOf:groupId];
 } else {
 return [ChatManager profileThumbImageURLOf:self.conversWith];
 }
 }*/

//- (BOOL)isEqual:(id)object {
//    ChatConversation *conv = (ChatConversation *)object;
//    return [self.conversationId isEqual:conv.conversationId] ? true : false;
//}

@end

