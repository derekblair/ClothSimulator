//
//  ClothViewModel.h
//  ClothSimulator
//
//  Created by Derek Blair on 2015-08-16.
//  Copyright (c) 2018 Derek Blair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClothViewModel : NSObject {
 @public
  GLfloat picnic[8 * 3 + 4];
  GLushort indexArray[kNumberTriangles * 2 + 4];
  GLushort text_verts[kNumberParticles * 2 + 4];
  float table[128 * 128 * 3 + 4];
  float tablenorm[128 * 128 * 3 + 4];
  GLushort tableindex[127 * 127 * 4 + 4];
  GLushort tabletexverts[128 * 128 * 2 + 4];
  GLushort picnicindex[4 * 5 + 4];
  GLushort picnictexverts[8 * 2 + 4];
  GLuint clothtex;
  GLuint tiletex;
  GLuint picnictex;
}

@end
