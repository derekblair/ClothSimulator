//
//  ClothSim.h
//  ClothSimulator
//
//  Created by Derek Blair on 2014-03-31.
//  Copyright (c) 2018 Derek Blair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClothSim: NSObject

- (void)stepForewardClothSimulation;
- (void)setupClothSimulation;
- (void)shutDownClothSimulation;
- (float *)getParticles;
- (float *)getNormals;
- (float *)getForce;
- (float *)getVel;
- (void)setFreeCloth;
- (void)removeFloor;
- (void)setWind:(float)wd;

@end
