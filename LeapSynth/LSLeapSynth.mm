//
//  LSLeapSynth.m
//  LeapSynth
//
//  Created by Connor Smith on 12/22/13.
//  Copyright (c) 2013 Connor Smith. All rights reserved.
//

#import "LSLeapSynth.h"
#import "LeapObjectiveC.h"
#import "TonicSynthManager.h"
#include "Tonic.h"

#define kLSLeapSynthNumSinusoids        10

typedef enum
{
    LSLeapSynthModeSinusoids = 0,
    LSLeapSynthModeFourier
}LSLeapSynthMode;

using namespace Tonic;

@interface LSLeapSynth () <LeapListener>

@property (strong, nonatomic) LeapController *leapController;
@property (weak, nonatomic) TonicSynthManager *synthManager;
@property (assign, nonatomic) BOOL isPlayingTone;
@property (assign, nonatomic) Synth leapSynth;
@property (assign, nonatomic) int currentPitch;
@property (assign, nonatomic) Synth lotsOfSinusoids;

- (void)configureLeapMotion;
- (void)configureSynth;

- (NSString *)stringForState:(LeapGestureState)state;

@end

@implementation LSLeapSynth

- (void)run
{
    [self configureLeapMotion];
    [self configureSynth];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configure

- (void)configureLeapMotion
{
    self.leapController = [[LeapController alloc] init];
    [self.leapController addListener:self];
}

- (void)configureSynth
{
    self.synthManager = [TonicSynthManager sharedManager];
    
    [self.synthManager startSession];
    
    self.lotsOfSinusoids = Synth();
    
    [self.synthManager addSynth:self.lotsOfSinusoids forKey:@"lotsOfSinusoids"];
    
    ControlParameter pitch = self.lotsOfSinusoids.addParameter("pitch",0);
    
    Adder outputAdder;
    
    for (int s=0; s<kLSLeapSynthNumSinusoids; s++){
        
        ControlGenerator pitchGen = ((pitch * 220 + 220) * powf(2, (s - (kLSLeapSynthNumSinusoids/2)) * 5.0f / 12.0f));
        
        outputAdder.input(SineWave().freq( pitchGen.smoothed() ));
        
    }
    
    Generator outputGen = outputAdder * ((1.0f/kLSLeapSynthNumSinusoids) * 0.5f);
    
    self.lotsOfSinusoids.setOutputGen(outputGen);
}

#pragma mark - LeapListener

- (void)onConnect:(NSNotification *)notification
{
    LeapController *aController = (LeapController *)[notification object];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    //    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onFrame:(NSNotification *)notification
{
    LeapController *aController = (LeapController *)[notification object];
    
    // The most recent frame
    LeapFrame *frame = [aController frame:0];
    
    if ([[frame hands] count] != 0) {
        // Get the first hand
        LeapHand *hand = [[frame hands] objectAtIndex:0];
        
        // Check if the hand has any fingers
        /*
         NSArray *fingers = [hand fingers];
         if ([fingers count] != 0) {
         // Calculate the hand's average finger tip position
         LeapVector *avgPos = [[LeapVector alloc] init];
         for (int i = 0; i < [fingers count]; i++) {
         LeapFinger *finger = [fingers objectAtIndex:i];
         avgPos = [avgPos plus:[finger tipPosition]];
         }
         avgPos = [avgPos divide:[fingers count]];
         NSLog(@"Hand has %ld fingers, average finger tip position %@",
         [fingers count], avgPos);
         }
         */
        
        // Get the hand's sphere radius and palm position
        /*
        NSLog(@"Hand sphere radius: %f mm, palm position: %@",
              [hand sphereRadius], [hand palmPosition]);
        */
        
        // Get the hand's normal vector and direction
        const LeapVector *normal = [hand palmNormal];
        const LeapVector *direction = [hand direction];
        
        // Normalize again for Tonic
        CGFloat tonicNormalY = Tonic::map(normal.y, -1, 1, 0, 10, true);
        
        NSLog(@"Normal.y: %f", normal.y);
        NSLog(@"tonicNormalY: %f", tonicNormalY);
        
        self.lotsOfSinusoids.setParameter("pitch", tonicNormalY);
        
        // Calculate the hand's pitch, roll, and yaw angles
        
        /*
        NSLog(@"Hand pitch: %f degrees, roll: %f degrees, yaw: %f degrees\n",
              [direction pitch] * LEAP_RAD_TO_DEG,
              [normal roll] * LEAP_RAD_TO_DEG,
              [direction yaw] * LEAP_RAD_TO_DEG);
         */
    }
    
    // the most recent gesture
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
                      circleGesture.id, [self stringForState:gesture.state],
                      circleGesture.progress, circleGesture.radius,
                      sweptAngle * LEAP_RAD_TO_DEG, clockwiseness);
                break;
            }
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
                NSLog(@"Swipe id: %d, %@, position: %@, direction: %@, speed: %f",
                      swipeGesture.id, [self stringForState:swipeGesture.state],
                      swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
                LeapKeyTapGesture *keyTapGesture = (LeapKeyTapGesture *)gesture;
                NSLog(@"Key Tap id: %d, %@, position: %@, direction: %@",
                      keyTapGesture.id, [self stringForState:keyTapGesture.state],
                      keyTapGesture.position, keyTapGesture.direction);
                break;
            }
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                NSLog(@"Screen Tap id: %d, %@, position: %@, direction: %@",
                      screenTapGesture.id, [self stringForState:screenTapGesture.state],
                      screenTapGesture.position, screenTapGesture.direction);
                break;
            }
            default:
                NSLog(@"Unknown gesture type");
                break;
        }
    }
}

- (NSString *)stringForState:(LeapGestureState)state
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
