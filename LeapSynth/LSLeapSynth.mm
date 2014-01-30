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
#import "LSLeapManager.h"

#define kLSLeapSynthNumOscilatorsSinusoid           10
#define kLSLeapSynthNumOscilatorsDubstep            5

#define kLSTonicSynthManagerSynthKey                @"mySynth"

typedef enum
{
    LSLeapSynthModeSinusoids = 0,
    LSLeapSynthModeDubstep,
    LSLeapSynthModeParamsTest
}LSLeapSynthMode;

using namespace Tonic;

@interface LSLeapSynth () <LeapListener>

@property (strong, nonatomic) LeapController *leapController;
@property (weak, nonatomic) TonicSynthManager *synthManager;
@property (assign, nonatomic) Synth leapSynth;
@property (assign, nonatomic) LSLeapSynthMode mode;

- (void)configureLeapMotion;
- (void)configureSynthWithMode:(LSLeapSynthMode)mode;
- (NSString *)stringForState:(LeapGestureState)state;

- (void)handleLeapEventWithVectors:(NSArray *)vectors;
- (LeapVector *)normalTonicLeapVectorWithVector:(LeapVector *)vectorIn;
- (TonicFloat)maxNormalX;
- (TonicFloat)maxNormalY;
- (TonicFloat)maxNormalZ;

@end

@implementation LSLeapSynth

- (void)run
{
//    [self configureLeapMotion];
    [self configureSynthWithMode:LSLeapSynthModeParamsTest];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveLeapNotification:)
                                                 name:@"TestNotification"
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receiveLeapNotification:(NSNotification *)notification
{
    if (notification)
    {
        NSNumber *numHands = [notification.userInfo objectForKey:kLSLeapManagerNotificationNumHandsKey];
        LeapVector *palmPosition = [self normalTonicLeapVectorWithVector:[notification.userInfo objectForKey:kLSLeapManagerNotificationPalmPositionKey]];
        LeapVector *palmDirection = [notification.userInfo objectForKey:kLSLeapManagerNotificationPalmDirectionKey];
        NSLog(@"Direction: %@", palmDirection);
//        ControlGenerator outputGen = ControlGenerator();
        
//        ControlGenerator freq = ControlRandom().trigger(metro).min(0).max(1);
        /*
        TonicFloat freq =
        
        Generator tone = SquareWaveBL().freq(
                                             freq * 0.25 + 100
                                             + 400
                                             ) * SineWave().freq(500);
        ADSR env = ADSR()
        .attack(0.1)
        .decay( 0.4 )
        .sustain(0)
        .release(0)
        .doesSustain(false)
        .trigger(metro);
        
        StereoDelay delay = StereoDelay(3.0f,3.0f)
        .delayTimeLeft( 0.5 + SineWave().freq(0.2) * 0.1)
        .delayTimeRight(0.55 + SineWave().freq(0.23) * 0.11)
        .feedback(0.3)
        .dryLevel(0.8)
        .wetLevel(0.8);
        
        Generator filterFreq = (SineWave().freq(0.1) + 1) * 1200 + 225;
        
        LPF24 filter = LPF24().Q(5).cutoff( filterFreq ).normalizesGain(false);
        
        Generator output = (( tone * env ) >> filter >> delay) * dBToLin(-30);
        
        outputGen = output;
         */
    }
}

#pragma mark - Configure

- (void)configureLeapMotion
{
    self.leapController = [[LeapController alloc] init];
    [self.leapController addListener:self];
}

- (void)configureSynthWithMode:(LSLeapSynthMode)mode
{
    self.mode = mode;
    
    self.synthManager = [TonicSynthManager sharedManager];
    
    [self.synthManager startSession];
    
    Generator outputGen = nil;
    
    switch (mode) {
        case LSLeapSynthModeSinusoids:
        {
            self.leapSynth = Synth();
            
            [self.synthManager addSynth:self.leapSynth forKey:kLSTonicSynthManagerSynthKey];
            
            ControlParameter pitch = self.leapSynth.addParameter("pitch",0);
            
            Adder outputAdder;
            
            for (int s=0; s<kLSLeapSynthNumOscilatorsSinusoid; s++){
                
                ControlGenerator pitchGen = ((pitch * 220 + 220) * powf(2, (s - (kLSLeapSynthNumOscilatorsSinusoid/2)) * 5.0f / 12.0f));
                
                outputAdder.input(SineWave().freq( pitchGen.smoothed() ));
                
            }
            
            outputGen = outputAdder * ((1.0f/kLSLeapSynthNumOscilatorsSinusoid) * 0.5f);
            break;
        }
            
        case LSLeapSynthModeDubstep:
        {
            self.leapSynth = Synth();
            
            [self.synthManager addSynth:self.leapSynth forKey:kLSTonicSynthManagerSynthKey];
            
            ControlParameter pitch = self.leapSynth.addParameter("pitch",0);
            
            Adder outputAdder;
            
            for (int s=0; s<kLSLeapSynthNumOscilatorsDubstep; s++){
                
                ControlGenerator pitchGen = ((pitch * 220 + 20) * powf(2, (s - (kLSLeapSynthNumOscilatorsDubstep/2)) * 0.05f / 12.0f));
                
                outputAdder.input(SquareWave().freq( pitchGen.smoothed()) + SineWave().freq( pitchGen.smoothed()));
            }
            
            outputGen = outputAdder * ((1.0f/(kLSLeapSynthNumOscilatorsDubstep)) * 0.5f);
            break;
        }
            
        case LSLeapSynthModeParamsTest:
        {
            self.leapSynth = Synth();
            
            [self.synthManager addSynth:self.leapSynth forKey:kLSTonicSynthManagerSynthKey];
            
            ControlMetro metro = ControlMetro().bpm(200);
            
            ControlGenerator freq = ControlRandom().trigger(metro).min(0).max(1);
            
            Generator tone = SquareWaveBL().freq(
                                                 freq * 0.25 + 100
                                                 + 400
                                                 ) * SineWave().freq(500);
            ADSR env = ADSR()
            .attack(0.1)
            .decay( 0.4 )
            .sustain(0)
            .release(0)
            .doesSustain(false)
            .trigger(metro);
            
            StereoDelay delay = StereoDelay(3.0f,3.0f)
            .delayTimeLeft( 0.5 + SineWave().freq(0.2) * 0.1)
            .delayTimeRight(0.55 + SineWave().freq(0.23) * 0.11)
            .feedback(0.3)
            .dryLevel(0.8)
            .wetLevel(0.8);
            
            Generator filterFreq = (SineWave().freq(0.1) + 1) * 1200 + 225;
            
            LPF24 filter = LPF24().Q(5).cutoff( filterFreq ).normalizesGain(false);
            
            Generator output = (( tone * env ) >> filter >> delay) * dBToLin(-30);
            
            outputGen = output;
            
            break;
        }
            
        default:
            break;
    }
    
    
    
    self.leapSynth.setOutputGen(outputGen);
}

- (void)endCurrentSession
{
    [self.synthManager removeAllSynths];
    [self.synthManager endSession];
}

#pragma mark - Leap -> Synth

- (void)handleLeapEventWithVectors:(NSArray *)vectors
{
    switch (self.mode) {
        case LSLeapSynthModeSinusoids:
        {
            id leapNormal = [vectors firstObject];
            if ([leapNormal isKindOfClass:[LeapVector class]])
            {
                LeapVector *tonicNormal = [self normalTonicLeapVectorWithVector:leapNormal];
                self.leapSynth.setParameter("pitch", tonicNormal.y);
            }
            break;
        }
        case LSLeapSynthModeDubstep:
        {
            id leapNormal = [vectors firstObject];
            if ([leapNormal isKindOfClass:[LeapVector class]])
            {
                LeapVector *tonicNormal = [self normalTonicLeapVectorWithVector:leapNormal];
                self.leapSynth.setParameter("pitch", tonicNormal.y);
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Normal/Scale

- (LeapVector *)normalTonicLeapVectorWithVector:(LeapVector *)vectorIn
{
    TonicFloat tonicNormalX = Tonic::map(vectorIn.x, -1, 1, 0, [self maxNormalX], true);
    TonicFloat tonicNormalY = Tonic::map(vectorIn.y, -1, 1, 0, [self maxNormalY], true);
    TonicFloat tonicNormalZ = Tonic::map(vectorIn.z, -1, 1, 0, [self maxNormalZ], true);
    
    LeapVector *vectorOut = [[LeapVector alloc] initWithX:tonicNormalX y:tonicNormalY z:tonicNormalZ];
    
    return vectorOut;
}

- (TonicFloat)maxNormalX
{
    TonicFloat ret = 0;
    
    switch (self.mode) {
        case LSLeapSynthModeSinusoids:
        {
            ret = 10;
            break;
        }
        case LSLeapSynthModeDubstep:
        {
            ret = 5;
            break;
        }
            
        default:
            break;
    }
    
    return ret;
}

- (TonicFloat)maxNormalY
{
    TonicFloat ret = 0;
    
    switch (self.mode) {
        case LSLeapSynthModeSinusoids:
        {
            ret = 10;
            break;
        }
        case LSLeapSynthModeDubstep:
        {
            ret = 5;
            break;
        }
            
        default:
            break;
    }
    
    return ret;
}

- (TonicFloat)maxNormalZ
{
    TonicFloat ret = 0;
    
    switch (self.mode) {
        case LSLeapSynthModeSinusoids:
        {
            ret = 10;
            break;
        }
        case LSLeapSynthModeDubstep:
        {
            ret = 5;
            break;
        }
            
        default:
            break;
    }
    
    return ret;
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
        LeapVector *normal = [hand palmNormal];
        LeapVector *direction = [hand direction];
        
        // Hand the normal off to be dealth with
        [self handleLeapEventWithVectors:@[normal, direction]];
        
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
