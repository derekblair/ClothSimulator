//
//  ClothViewPoint.h
//  ClothSimulator
//
//  Created by Derek Blair on 2014-03-31.
//  Copyright (c) 2018 Derek Blair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClothViewPoint : NSObject

- (void)lookAt;
- (void)update;
- (void)mouseDownWithPoint:(NSPoint)point;
- (void)mouseDraggedWithPoint:(NSPoint)point;
- (void)zoom:(CGFloat)dp;
- (void)setCameraHeight:(float)height;

@end
