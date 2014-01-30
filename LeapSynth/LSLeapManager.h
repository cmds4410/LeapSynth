//
//  LSLeapManager.h
//  LeapSynth
//
//  Created by Connor Smith on 12/22/13.
//  Copyright (c) 2013 Connor Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kLSLeapManagerNotification;
extern NSString * const kLSLeapManagerNotificationControllerKey;
extern NSString * const kLSLeapManagerNotificationNumHandsKey;
extern NSString * const kLSLeapManagerNotificationNumFingersKey;
extern NSString * const kLSLeapManagerNotificationNumToolsKey;
extern NSString * const kLSLeapManagerNotificationPalmPositionKey;
extern NSString * const kLSLeapManagerNotificationPalmDirectionKey;
extern NSString * const kLSLeapManagerNotificationSphereRadiusKey;
extern NSString * const kLSLeapManagerNotificationHandPitchKey;
extern NSString * const kLSLeapManagerNotificationHandRollKey;
extern NSString * const kLSLeapManagerNotificationHandYawKey;

@interface LSLeapManager : NSObject

+ (instancetype)sharedLeapManager;

@end
