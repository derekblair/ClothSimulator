//
//  ClothView.h
//  ClothSimulator
//
//  Created by Derek Blair on 12/3/2013.
//  Copyright (c) 2015 Derek Blair. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ClothView : NSOpenGLView

- (IBAction)windChanged:(NSSlider *)sender;
- (IBAction)cameraHeightChanged:(NSSlider *)sender;
- (IBAction)releaseCloth:(id)sender;
- (IBAction)toggleActive:(NSSegmentedControl *)sender;

@end
