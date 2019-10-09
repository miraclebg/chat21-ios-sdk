//
//  ChatStatusTitle.h
//  Chat21
//
//  Created by Andrea Sponziello on 13/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatStatusTitle;

@protocol ChatStatusTitleDelegate <NSObject>

@optional

- (void)didTapChatBackButton:(ChatStatusTitle*)view;

@end

@interface ChatStatusTitle : UIView

@property (nonatomic, assign) BOOL showsBackButton;
@property (nonatomic, weak) id<ChatStatusTitleDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *usernameButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
