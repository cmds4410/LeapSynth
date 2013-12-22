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

using namespace Tonic;

@interface LSLeapSynth () <LeapListener>

@property (strong, nonatomic) LeapController *leapController;
@property (weak, nonatomic) TonicSynthManager *synthManager;

- (void)configureLeapMotion;
- (void)configureSynth;
- (void)toggleTone;
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
}

#pragma mark - Tonic

- (void)toggleTone
{
    Synth mySynth = Synth();
    
    [self.synthManager addSynth:mySynth forKey:@"mySynth"];
    
    ControlMetro metro = ControlMetro().bpm(200);
    ControlGenerator freq = ControlRandom().trigger(metro).min(0).max(1);
    
    //Tonic is a collection of signal generators and processors
    TriangleWave tone1 = TriangleWave();
    SineWave tone2 = SineWave().freq(mtof(60));
    SineWave vibrato = SineWave().freq(10);
    SineWave tremelo = SineWave().freq(1);
    //    ControlMidiToFreq
    Noise click = Noise();
    
    ADSR env = ADSR()
    .attack(.0001)
    .decay( 0.05 )
    .sustain(0)
    .release(0)
    .doesSustain(false)
    .trigger(1);
    
    //that you can combine using intuitive operators
    Generator combinedSignal = (tone1 + tone2) * tremelo;
    Generator triangle = tone1;
    
    Generator clickGen;
    
    clickGen = tone2 * env;
    
    mySynth.setOutputGen(clickGen);
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
                [self toggleTone];
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
