//
//  ChatStatusTitle.m
//  Chat21
//
//  Created by Andrea Sponziello on 13/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatStatusTitle.h"

@interface ChatStatusTitle()

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation ChatStatusTitle

#pragma mark - Initialization / Finalization

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backButton.hidden = YES;
}

#pragma mark - Utils

- (CGSize)intrinsicContentSize {
    return UILayoutFittingExpandedSize;
}

#pragma mark - Getters / Setters

- (void)setShowsBackButton:(BOOL)showsBackButton {
    if (_showsBackButton != showsBackButton) {
        _showsBackButton = showsBackButton;
        self.backButton.hidden = !_showsBackButton;
    }
}

#pragma mark - Actions

- (IBAction)tappedBackButton:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(didTapChatBackButton:)]) {
        [_delegate didTapChatBackButton:self];
    }
}

@end
