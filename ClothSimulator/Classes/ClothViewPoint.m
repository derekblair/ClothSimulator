//
//  ClothViewPoint.m
//  ClothSimulator
//
//  Created by Derek Blair on 2014-03-31.
//  Copyright (c) 2018 Derek Blair. All rights reserved.
//

#import "ClothViewPoint.h"
#include <OpenGL/gl.h>
#import "la.h"

#define DRAG_SENSITIVITY 200.0f

static void lookAt(float* viewer, float* center, float* up) {
  GLfloat m[16];
  GLfloat x[4], y[4], z[4];
  sub3(viewer, center, z);
  normalize3(z);
  copy3(y, up);
  cross3(y, z, x);
  cross3(z, x, y);
  normalize3(x);
  normalize3(y);
#define M(row, col) m[col * 4 + row]
  M(0, 0) = x[0];
  M(0, 1) = x[1];
  M(0, 2) = x[2];
  M(0, 3) = 0.0;
  M(1, 0) = y[0];
  M(1, 1) = y[1];
  M(1, 2) = y[2];
  M(1, 3) = 0.0;
  M(2, 0) = z[0];
  M(2, 1) = z[1];
  M(2, 2) = z[2];
  M(2, 3) = 0.0;
  M(3, 0) = 0.0;
  M(3, 1) = 0.0;
  M(3, 2) = 0.0;
  M(3, 3) = 1.0;
#undef M
  glMultMatrixf(m);
  glTranslatef(-viewer[0], -viewer[1], -viewer[2]);
}

static float up[3] = {0, 1, 0};

@implementation ClothViewPoint {
  float _viewer[4];
  float _theta;
  float _phi;
  float _rho;
  float _yoff;

  NSPoint _startPoint;
  float _startTheta;
  float _startPhi;
}

- (id)init {
  self = [super init];
  if (self != nil) {
    // Default initial conifg.
    _viewer[0] = kSide / 2;
    _viewer[1] = kSide / 2;
    _viewer[2] = kSide * 2;
    _rho = kSide * 2;
    _phi = 3.14159265359 / 2.0f;
    _theta = 0;
    _yoff = kSide / 2;
  }

  return self;
}

- (void)lookAt {
  float center[3];
  center[0] = kSide / 2;
  center[1] = _yoff;
  center[2] = 0;
  lookAt(_viewer, center, up);
}

- (void)zoom:(CGFloat)dp {
  _rho -= dp;
}

- (void)update {
  _viewer[2] = cos(_theta) * sin(_phi) * _rho;
  _viewer[0] = kSide / 2 + sin(_theta) * sin(_phi) * _rho;
  _viewer[1] = _yoff + cos(_phi) * _rho;
}

- (void)mouseDownWithPoint:(NSPoint)point {
  _startPoint = point;
  _startTheta = _theta;
  _startPhi = _phi;
}

- (void)mouseDraggedWithPoint:(NSPoint)point {
  NSPoint _curPoint = point;
  float dx = _curPoint.x - _startPoint.x;
  float dy = _curPoint.y - _startPoint.y;
  _theta = _startTheta - dx / DRAG_SENSITIVITY * M_PI / 2;
  _phi = _startPhi + dy / DRAG_SENSITIVITY * M_PI / 2;
}

- (void)setCameraHeight:(float)height {
  _yoff = kSide / 2 + height;
}
@end
