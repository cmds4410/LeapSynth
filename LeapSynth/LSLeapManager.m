//
//  LSLeapManager.m
//  LeapSynth
//
//  Created by Connor Smith on 12/22/13.
//  Copyright (c) 2013 Connor Smith. All rights reserved.
//

#import "LSLeapManager.h"
#import "LeapObjectiveC.h"

NSString * const kLSLeapManagerNotification =                    @"LSLeapManagerNotification";
NSString * const kLSLeapManagerNotificationControllerKey =       @"LSLeapManagerNotificationControllerKey";
NSString * const kLSLeapManagerNotificationNumHandsKey =         @"LSLeapManagerNotificationNumHandsKey";
NSString * const kLSLeapManagerNotificationNumFingersKey =       @"LSLeapManagerNotificationNumFingersKey";
NSString * const kLSLeapManagerNotificationNumToolsKey =         @"LSLeapManagerNotificationNumToolsKey";
NSString * const kLSLeapManagerNotificationPalmPositionKey =     @"LSLeapManagerNotificationPalmPositionKey";
NSString * const kLSLeapManagerNotificationPalmDirectionKey =    @"LSLeapManagerNotificationPalmDirectionKey";
NSString * const kLSLeapManagerNotificationSphereRadiusKey =     @"LSLeapManagerNotificationSphereRadiusKey";
NSString * const kLSLeapManagerNotificationHandPitchKey =        @"LSLeapManagerNotificationHandPitchKey";
NSString * const kLSLeapManagerNotificationHandRollKey =         @"LSLeapManagerNotificationHandRollKey";
NSString * const kLSLeapManagerNotificationHandYawKey =          @"LSLeapManagerNotificationHandYawKey";

@interface LSLeapManager () <LeapListener>

@property (strong, nonatomic) LeapController *leapController;

@end

@implementation LSLeapManager

+ (instancetype)sharedLeapManager
{
    static dispatch_once_t once;
    static LSLeapManager *shared;
    dispatch_once(&once, ^ { shared = [[self alloc] init]; });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    [self run];
    
    return self;
}

- (void)run
{
    self.leapController = [[LeapController alloc] init];
    [self.leapController addListener:self];
    NSLog(@"running");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - LeapListener

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Initialized");
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Connected");
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification
{
    //Note: not dispatched when running in a debugger.
    NSLog(@"Disconnected");
}

- (void)onExit:(NSNotification *)notification
{
    NSLog(@"Exited");
}

- (void)onFrame:(NSNotification *)notification
{
    // This will be the user info in our custom NSNotification
    NSMutableDictionary *userInfoForNotification = [[NSMutableDictionary alloc] init];
    
    LeapController *aController = (LeapController *)[notification object];
    
    // I'm adding this to the dictionary just in case the listener needs to do some custom handling of ther Leap Data
    // In order to make use of it, then listener will have to know the Leap API itself, which is not the intention of this manager
    [userInfoForNotification setObject:aController forKey:kLSLeapManagerNotificationControllerKey];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    // set the number of hands on the userInfo
    [userInfoForNotification setObject:@([[frame hands] count]) forKey:kLSLeapManagerNotificationNumHandsKey];
    
    // set the number of fingers on the userInfo
    [userInfoForNotification setObject:@([[frame fingers] count]) forKey:kLSLeapManagerNotificationNumFingersKey];
    
    // set the number of tools on the userInfo
    [userInfoForNotification setObject:@([[frame tools] count]) forKey:kLSLeapManagerNotificationNumToolsKey];
    
    /*
    NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
          [frame id], [frame timestamp], [[frame hands] count],
          [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);
     */
    
    if ([[frame hands] count] != 0) {
        // Get the first hand
        LeapHand *hand = [[frame hands] objectAtIndex:0];
        
        // Get the hand's normal vector and direction
        LeapVector *normal = [hand palmNormal];
        LeapVector *direction = [hand direction];
        NSNumber *sphereRadius = @([hand sphereRadius]);
        NSNumber *degreesPitch = @([direction pitch]);
        NSNumber *degreesRoll = @([normal roll]);
        NSNumber *degreesYaw = @([direction yaw]);
        
        [userInfoForNotification setObject:normal forKey:kLSLeapManagerNotificationPalmPositionKey];
        [userInfoForNotification setObject:direction forKey:kLSLeapManagerNotificationPalmDirectionKey];
        [userInfoForNotification setObject:sphereRadius forKey:kLSLeapManagerNotificationSphereRadiusKey];
        [userInfoForNotification setObject:degreesPitch forKey:kLSLeapManagerNotificationHandPitchKey];
        [userInfoForNotification setObject:degreesRoll forKey:kLSLeapManagerNotificationHandRollKey];
        [userInfoForNotification setObject:degreesYaw forKey:kLSLeapManagerNotificationHandYawKey];
        
        // Get the hand's sphere radius and palm position
        /*
         NSLog(@"Hand sphere radius: %f mm, palm position: %@",
         [hand sphereRadius], [hand palmPosition]);
         
         // Get the hand's normal vector and direction
         const LeapVector *normal = [hand palmNormal];
         const LeapVector *direction = [hand direction];
         
         // Calculate the hand's pitch, roll, and yaw angles
         
         NSLog(@"Hand pitch: %f degrees, roll: %f degrees, yaw: %f degrees\n",
         [direction pitch] * LEAP_RAD_TO_DEG,
         [normal roll] * LEAP_RAD_TO_DEG,
         [direction yaw] * LEAP_RAD_TO_DEG);
         */
        
        // Check if the hand has any fingers
        NSArray *fingers = [hand fingers];
        
        if ([fingers count] != 0) {
            // Calculate the hand's average finger tip position
            LeapVector *avgPos = [[LeapVector alloc] init];
            for (int i = 0; i < [fingers count]; i++) {
                LeapFinger *finger = [fingers objectAtIndex:i];
                avgPos = [avgPos plus:[finger tipPosition]];
            }
            avgPos = [avgPos divide:[fingers count]];
            /*
            NSLog(@"Hand has %ld fingers, average finger tip position %@",
                  [fingers count], avgPos);
             */
            
        }
    }
    
    NSArray *gestures = [frame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        switch (gesture.type) {
            case LEAP_GESTURE_TYPE_CIRCLE: {
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                
                NSString *clockwiseness;
                if ([[[circleGesture pointable] direction] angleTo:[circleGesture normal]] <= LEAP_PI/4) {
                    clockwiseness = @"clockwise";
                } else {
                    clockwiseness = @"counterclockwise";
                }
                
                // Calculate the angle swept since the last frame
                float sweptAngle = 0;
                if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                    LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[[aController frame:1] gesture:gesture.id];
                    sweptAngle = (circleGesture.progress - previousUpdate.progress) * 2 * LEAP_PI;
                }
                
                NSLog(@"Circle id: %d, %@, progress: %f, radius %f, angle: %f degrees %@",
                      circleGesture.id, [LSLeapManager stringForState:gesture.state],
                      circleGesture.progress, circleGesture.radius,
                      sweptAngle * LEAP_RAD_TO_DEG, clockwiseness);
                break;
            }
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
                NSLog(@"Swipe id: %d, %@, position: %@, direction: %@, speed: %f",
                      swipeGesture.id, [LSLeapManager stringForState:swipeGesture.state],
                      swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
                LeapKeyTapGesture *keyTapGesture = (LeapKeyTapGesture *)gesture;
                NSLog(@"Key Tap id: %d, %@, position: %@, direction: %@",
                      keyTapGesture.id, [LSLeapManager stringForState:keyTapGesture.state],
                      keyTapGesture.position, keyTapGesture.direction);
                break;
            }
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                NSLog(@"Screen Tap id: %d, %@, position: %@, direction: %@",
                      screenTapGesture.id, [LSLeapManager stringForState:screenTapGesture.state],
                      screenTapGesture.position, screenTapGesture.direction);
                break;
            }
            default:
                NSLog(@"Unknown gesture type");
                break;
        }
    }
    /*
    if (([[frame hands] count] > 0) || [[frame gestures:nil] count] > 0) {
        NSLog(@" ");
    }
     */
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:self userInfo:userInfoForNotification];
}

- (void)onFocusGained:(NSNotification *)notification
{
    NSLog(@"Focus Gained");
}

- (void)onFocusLost:(NSNotification *)notification
{
    NSLog(@"Focus Lost");
}

+ (NSString *)stringForState:(LeapGestureState)state
{
    switch (state) {
        case LEAP_GESTURE_STATE_INVALID:
            return @"STATE_INVALID";
        case LEAP_GESTURE_STATE_START:
            return @"STATE_START";
        case LEAP_GESTURE_STATE_UPDATE:
            return @"STATE_UPDATED";
        case LEAP_GESTURE_STATE_STOP:
            return @"STATE_STOP";
        default:
            return @"STATE_INVALID";
    }
}

@end
