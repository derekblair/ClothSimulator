//
//  ClothViewModel.m
//  ClothSimulator
//
//  Created by Derek Blair on 2015-08-16.
//  Copyright (c) 2015 Derek Blair. All rights reserved.
//

#import "ClothViewModel.h"
#include <OpenGL/gl.h>

static void getTrianglePoints(int tri, int *x0, int *x1, int *x2, int size) {
  if ((tri & 1) == 0) {  // type A : even index
    (*x0) = tri / 2 + tri / (2 * (size - 1));
    (*x1) = (*x0) + 1;
    (*x2) = (*x0) + size;
  } else {  // type B : odd index
    (*x2) = (tri - 1) / 2 + (tri - 1) / (2 * (size - 1)) + 1;
    (*x0) = (*x2) + size;
    (*x1) = (*x2) + size - 1;
  }
}

static GLuint loadTexture(NSString *name, GLuint width, GLuint height) {
  GLuint tex;
  glGenTextures(1, &tex);
  glBindTexture(GL_TEXTURE_2D, tex);
  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  CGImageRef im;
  NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
  NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
  NSImage *image = [[NSImage alloc] initWithData:texData];
  if (image == nil) NSLog(@"Error loading texture image");
  CGImageSourceRef source;
  source = CGImageSourceCreateWithData(
      (__bridge CFDataRef)[image TIFFRepresentation], NULL);
  im = CGImageSourceCreateImageAtIndex(source, 0, NULL);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  void *imageData = malloc(height * width * 4);
  CGContextRef context = CGBitmapContextCreate(
      imageData, width, height, 8, 4 * width, colorSpace,
      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);
  CGContextClearRect(context, CGRectMake(0, 0, width, height));
  CGContextTranslateCTM(context, 0, height - height);
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), im);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                  GL_LINEAR_MIPMAP_NEAREST);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, imageData);
  glGenerateMipmap(GL_TEXTURE_2D);
  CGContextRelease(context);
  free(imageData);
  return tex;
}

@implementation ClothViewModel

- (id)init {
  self = [super init];
  if (self != nil) {
    int i, j, row, column, x0, x1, x2;
    for (j = 0; j < 128; j++) {
      for (i = 0; i < 128; i++) {
        table[3 * (i + 128 * j)] = 30 * (i - 64);
        table[3 * (i + 128 * j) + 2] = 30 * (64 - j);
        table[3 * (i + 128 * j) + 1] = ztable;

        tablenorm[3 * (i + 128 * j)] = 0;
        tablenorm[3 * (i + 128 * j) + 2] = 0;
        tablenorm[3 * (i + 128 * j) + 1] = 1;
      }
    }
    for (i = 0; i < 127 * 127; ++i) {
      getTrianglePoints(2 * i, &x0, &x1, &x2, 128);

      tableindex[4 * i] = x0;
      tableindex[4 * i + 1] = x1;
      tableindex[4 * i + 2] = x1 + 128;
      tableindex[4 * i + 3] = x2;
    }
    for (i = 0; i < 128 * 128; i++) {
      row = i / 128;
      column = i % 128;
      tabletexverts[2 * i] = (column & 1);
      tabletexverts[2 * i + 1] = (row & 1);
    }
    for (i = 0; i < kNumberTriangles / 2; ++i) {
      getTrianglePoints(2 * i, &x0, &x1, &x2, kSide);

      indexArray[4 * i] = x0;
      indexArray[4 * i + 1] = x1;
      indexArray[4 * i + 2] = x1 + kSide;
      indexArray[4 * i + 3] = x2;
    }
    for (i = 0; i < kNumberParticles; i++) {
      row = i / kSide;
      column = i % kSide;
      text_verts[2 * i] = (column & 1);
      text_verts[2 * i + 1] = (row & 1);
    }
    i = 0;
    picnic[i++] = 0 + kSide * 0.2;
    picnic[i++] = -kSide / 2;
    picnic[i++] = -kSide * 0.2;
    picnic[i++] = kSide * 0.6 + kSide * 0.2;
    picnic[i++] = -kSide / 2;
    picnic[i++] = -kSide * 0.2;
    picnic[i++] = kSide * 0.6 + kSide * 0.2;
    picnic[i++] = -kSide / 2;
    picnic[i++] = -kSide * 0.6 - kSide * 0.2;
    picnic[i++] = 0 + kSide * 0.2;
    picnic[i++] = -kSide / 2;
    picnic[i++] = -kSide * 0.6 - kSide * 0.2;
    picnic[i++] = 0 + kSide * 0.2;
    picnic[i++] = kSide / 2 - kSide / 2;
    picnic[i++] = 0 - kSide * 0.2;
    picnic[i++] = kSide * 0.6 + kSide * 0.2;
    picnic[i++] = kSide / 2 - kSide / 2;
    picnic[i++] = 0 - kSide * 0.2;
    picnic[i++] = kSide * 0.6 + kSide * 0.2;
    picnic[i++] = kSide / 2 - kSide / 2;
    picnic[i++] = -kSide * 0.6 - kSide * 0.2;
    picnic[i++] = 0 + kSide * 0.2;
    picnic[i++] = kSide / 2 - kSide / 2;
    picnic[i++] = -kSide * 0.6 - kSide * 0.2;
    i = 0;
    picnicindex[i++] = 4;
    picnicindex[i++] = 5;  // top
    picnicindex[i++] = 6;
    picnicindex[i++] = 7;
    picnicindex[i++] = 0;
    picnicindex[i++] = 1;  //  front
    picnicindex[i++] = 5;
    picnicindex[i++] = 4;
    picnicindex[i++] = 2;
    picnicindex[i++] = 3;  //  back
    picnicindex[i++] = 7;
    picnicindex[i++] = 6;
    picnicindex[i++] = 1;
    picnicindex[i++] = 2;  // right side
    picnicindex[i++] = 6;
    picnicindex[i++] = 5;
    picnicindex[i++] = 3;
    picnicindex[i++] = 0;  // left side
    picnicindex[i++] = 4;
    picnicindex[i++] = 7;
    i = 0;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 1;
    picnictexverts[i++] = 0;
    picnictexverts[i++] = 1;

    // Load textures

    tiletex = loadTexture(@"sand", 256, 256);
    clothtex = loadTexture(@"gran", 256, 256);
    picnictex = loadTexture(@"picnic", 32, 32);
  }

  return self;
}

@end