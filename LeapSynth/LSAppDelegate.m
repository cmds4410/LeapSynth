//
//  LSAppDelegate.m
//  LeapSynth
//
//  Created by Connor Smith on 12/21/13.
//  Copyright (c) 2013 Connor Smith. All rights reserved.
//

#import "LSAppDelegate.h"
#import "LSLeapManager.h"
#import "LSLeapSynth.h"

@interface LSAppDelegate ()

@property (strong, nonatomic) LSLeapSynth *leapSynth;

@end

@implementation LSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.leapSynth = [[LSLeapSynth alloc] init];
    [self.leapSynth run];
}

@end
