// DEPRECATED

//  NotificationAlertVC.m
//  Chat21
//
//  Created by Andrea Sponziello on 22/12/15.
//  Copyright © 2015 Frontiere21. All rights reserved.
//

#import "NotificationAlertVC.h"
#import "ChatConversationsVC.h"
#import "ChatManager.h"
#import "ChatUIManager.h"

@interface NotificationAlertVC () {
    SystemSoundID soundID;
}
@end

@implementation NotificationAlertVC

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"NotificationAlertVC loaded.");
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    
    // adjusting close button position on the right side of the view
    self.closeButton.translatesAutoresizingMaskIntoConstraints = YES;
    CGRect rect = self.closeButton.frame;
    float view_width = self.view.frame.size.width;
    float close_button_width = self.closeButton.frame.size.width;
    float close_button_x = view_width - close_button_width;
    CGRect close_rect = CGRectMake(close_button_x, rect.origin.y, rect.size.width, rect.size.height);
    [self.closeButton setFrame:close_rect];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"View tapped!! Moving to conversation tab.");
    [self animateClose];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

static float animationDurationShow = 0.5;
static float animationDurationClose = 0.3;
static float showTime = 4.0;

-(void)animateShow {
    self.animating = YES;
    
    [UIView animateWithDuration:animationDurationShow
              delay:0
            options: (UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
         animations:^{
             self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
         }
         completion:^(BOOL finished) {
             self.animating = NO;
             self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:showTime target:self selector:@selector(animateClose) userInfo:nil repeats:NO];
         }
     ];
}

-(void)animateClose {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.animating = YES;
    [UIView animateWithDuration:animationDurationClose
        delay:0
        options: (UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
        animations:^{
            self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
        } completion:^(BOOL finished) {
            self.animating = NO;
        }
    ];
}

- (IBAction)closeAction:(id)sender {
    NSLog(@"Closing alert");
    [self animateClose];
}

@end
