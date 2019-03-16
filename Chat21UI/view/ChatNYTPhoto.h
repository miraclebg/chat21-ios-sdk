//
//  ChatNYTPhoto.h
//  chat21
//
//  Created by Andrea Sponziello on 07/05/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatNYTPhoto : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic) NSData *imageData;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSAttributedString *attributedCaptionTitle;
@property (nonatomic) NSAttributedString *attributedCaptionSummary;
@property (nonatomic) NSAttributedString *attributedCaptionCredit;

@end
