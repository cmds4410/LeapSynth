//
//  LSAppDelegate.m
//  LeapSynth
//
//  Created by Connor Smith on 12/21/13.
//  Copyright (c) 2013 Connor Smith. All rights reserved.
//

#import "LSAppDelegate.h"
#import "LSLeapManager.h"

@implementation LSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [LSLeapManager sharedLeapManager];
}

@end
