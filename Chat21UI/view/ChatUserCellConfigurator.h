//
//  ChatUserCellConfigurator.h
//  chat21
//
//  Created by Andrea Sponziello on 10/09/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ChatImageCache;
@class ChatDiskImageCache;
@class ChatUser;
@class ChatGroup;
@class ChatSelectUserLocalVC;
@class NSURLSessionDataTask;

@interface ChatUserCellConfigurator : NSObject

@property(strong, nonatomic) ChatSelectUserLocalVC *vc;
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) ChatDiskImageCache *imageCache;
@property (strong, nonatomic) ChatGroup *group;
@property(strong, nonatomic) NSMutableDictionary<NSString*, NSURLSessionDataTask*> *tasks;

-(id)initWith:(ChatSelectUserLocalVC *)vc;
-(UITableViewCell *)configureCellAtIndexPath:(NSIndexPath *)indexPath;
-(void)teminatePendingTasks;

@end
