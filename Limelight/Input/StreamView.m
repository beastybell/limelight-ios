//
//  StreamView.m
//  Limelight
//
//  Created by Cameron Gutman on 10/19/14.
//  Copyright (c) 2014 Limelight Stream. All rights reserved.
//

#import "StreamView.h"
#include <Limelight.h>
#import "OnScreenControls.h"
#import "DataManager.h"
#import "ControllerSupport.h"

@implementation StreamView {
    CGPoint touchLocation;
    BOOL touchMoved;
    OnScreenControls* onScreenControls;
    
    float xDeltaFactor;
    float yDeltaFactor;
    float screenFactor;
}

- (void) setMouseDeltaFactors:(float)x y:(float)y {
    xDeltaFactor = x;
    yDeltaFactor = y;
    
    screenFactor = [[UIScreen mainScreen] scale];
}

- (void) setupOnScreenControls:(ControllerSupport*)controllerSupport {
    onScreenControls = [[OnScreenControls alloc] initWithView:self controllerSup:controllerSupport];
    DataManager* dataMan = [[DataManager alloc] init];
    OnScreenControlsLevel level = (OnScreenControlsLevel)[[dataMan retrieveSettings].onscreenControls integerValue];
    
    if (level == OnScreenControlsLevelAuto) {
        [controllerSupport initAutoOnScreenControlMode:onScreenControls];
    }
    else {
        NSLog(@"Setting manual on-screen controls level: %d", (int)level);
        [onScreenControls setLevel:level];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch down");
    if (![onScreenControls handleTouchDownEvent:touches]) {
        UITouch *touch = [[event allTouches] anyObject];
        touchLocation = [touch locationInView:self];
        touchMoved = false;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![onScreenControls handleTouchMovedEvent:touches]) {
        if ([[event allTouches] count] == 1) {
            UITouch *touch = [[event allTouches] anyObject];
            CGPoint currentLocation = [touch locationInView:self];
            
            if (touchLocation.x != currentLocation.x ||
                touchLocation.y != currentLocation.y)
            {
                int deltaX = currentLocation.x - touchLocation.x;
                int deltaY = currentLocation.y - touchLocation.y;
                
                deltaX *= xDeltaFactor * screenFactor;
                deltaY *= yDeltaFactor * screenFactor;
                
                LiSendMouseMoveEvent(deltaX, deltaY);

                touchMoved = true;
                touchLocation = currentLocation;
            }
        } else if ([[event allTouches] count] == 2) {
            CGPoint firstLocation = [[[[event allTouches] allObjects] objectAtIndex:0] locationInView:self];
            CGPoint secondLocation = [[[[event allTouches] allObjects] objectAtIndex:1] locationInView:self];

            CGPoint avgLocation = CGPointMake((firstLocation.x + secondLocation.x) / 2, (firstLocation.y + secondLocation.y) / 2);
            if (touchLocation.y != avgLocation.y) {
                LiSendScrollEvent(avgLocation.y - touchLocation.y);
            }
            touchMoved = true;
            touchLocation = avgLocation;
        }
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch up");
    if (![onScreenControls handleTouchUpEvent:touches]) {
        if (!touchMoved) {
            if ([[event allTouches] count]  == 2) {
                NSLog(@"Sending right mouse button press");

                LiSendMouseButtonEvent(BUTTON_ACTION_PRESS, BUTTON_RIGHT);

                // Wait 100 ms to simulate a real button press
                usleep(100 * 1000);

                LiSendMouseButtonEvent(BUTTON_ACTION_RELEASE, BUTTON_RIGHT);


            } else {
                NSLog(@"Sending left mouse button press");

                LiSendMouseButtonEvent(BUTTON_ACTION_PRESS, BUTTON_LEFT);

                // Wait 100 ms to simulate a real button press
                usleep(100 * 1000);

                LiSendMouseButtonEvent(BUTTON_ACTION_RELEASE, BUTTON_LEFT);
            }
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}


@end
