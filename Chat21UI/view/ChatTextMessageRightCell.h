//
//  ChatTextMessageRightCell.h
//  chat21
//
//  Created by Andrea Sponziello on 18/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatImageMessageCell.h"

@interface ChatTextMessageRightCell : ChatImageMessageCell

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

-(void)configure:(ChatMessage *)message messages:(NSArray *)messages indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController rowComponents:(NSMutableDictionary *)rowComponents;

@end
