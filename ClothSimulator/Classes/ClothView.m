//
//  ClothView.m
//  ClothSimulator
//
//  Created by Derek Blair on 12/3/2013.
//  Copyright (c) 2015 Derek Blair. All rights reserved.
//

#import "ClothView.h"
#import "ClothViewPoint.h"
#import "ClothSim.h"
#import "ClothViewModel.h"
#include <OpenGL/gl.h>

// Perspective Helper
static void perspective(GLdouble fovy, GLdouble aspect, GLdouble zNear,
                        GLdouble zFar) {
  GLdouble xmin, xmax, ymin, ymax;
  ymax = zNear * tan(fovy * M_PI / 360.0);
  ymin = -ymax;
  xmin = ymin * aspect;
  xmax = ymax * aspect;
  glFrustum(xmin, xmax, ymin, ymax, zNear, zFar);
}

@interface ClothView ()
- (void)activateContext;
- (void)flushContext;
- (void)update;
- (void)tick;
@end

@implementation ClothView {
  BOOL _active;
  ClothViewPoint *_viewPoint;
  ClothViewModel *_arrays;
  ClothSim *_sim;
}

#pragma mark - NSObject

- (void)dealloc {
  [_sim shutDownClothSimulation];
  [super dealloc];
}

#pragma mark - NSResponder

- (BOOL)acceptsFirstResponder {
  return YES;
}

#pragma mark - UIView

- (void)drawRect:(NSRect)dirtyRect {
  [self activateContext];
  GLfloat lightPos0[4] = {kSide / 2, kSide / 2, kSide / 2, 1.0f};
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);
  GLfloat whiteMaterial[] = {1.0, 1.0, 1.0};
  GLfloat lightColor0[] = {1.0f, 1.0f, 1.0f, 1.0f};
  GLfloat lightPos1[] = {kSide / 2, kSide, -2 * kSide, 1.0f};
  GLfloat lightDir[] = {0, -1, 1, 1};
  GLfloat blankMaterial[] = {0, 0, 0};
  GLfloat mShininess[] = {500};
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lightColor0);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, lightColor0);
  glLightfv(GL_LIGHT0, GL_SPECULAR, lightColor0);
  glLightfv(GL_LIGHT0, GL_POSITION, lightPos0);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, lightColor0);
  glLightfv(GL_LIGHT1, GL_SPECULAR, lightColor0);
  glLightfv(GL_LIGHT1, GL_POSITION, lightPos1);
  glLightfv(GL_LIGHT1, GL_SPOT_DIRECTION, lightDir);
  glLightf(GL_LIGHT1, GL_SPOT_CUTOFF, 85.f);
  glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, whiteMaterial);
  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, blankMaterial);
  glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, blankMaterial);
  glBindTexture(GL_TEXTURE_2D, _arrays->clothtex);
  glVertexPointer(3, GL_FLOAT, 0, [_sim getParticles]);
  glTexCoordPointer(2, GL_SHORT, 0, _arrays->text_verts);
  glNormalPointer(GL_FLOAT, 0, [_sim getNormals]);
  glClearColor(0.6, 0.6, 1.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  [_viewPoint lookAt];
  glDrawElements(GL_QUADS, kNumberTriangles * 2, GL_UNSIGNED_SHORT,
                 _arrays->indexArray);
  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, whiteMaterial);
  glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, mShininess);
  glBindTexture(GL_TEXTURE_2D, _arrays->tiletex);
  glVertexPointer(3, GL_FLOAT, 0, _arrays->table);
  glTexCoordPointer(2, GL_SHORT, 0, _arrays->tabletexverts);
  glNormalPointer(GL_FLOAT, 0, _arrays->tablenorm);
  glDrawElements(GL_QUADS, 4 * 127 * 127, GL_UNSIGNED_SHORT,
                 _arrays->tableindex);
  glBindTexture(GL_TEXTURE_2D, _arrays->picnictex);
  glVertexPointer(3, GL_FLOAT, 0, _arrays->picnic);
  glTexCoordPointer(2, GL_SHORT, 0, _arrays->picnictexverts);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDrawElements(GL_QUADS, 4 * 5, GL_UNSIGNED_SHORT, _arrays->picnicindex);
  glEnableClientState(GL_NORMAL_ARRAY);
  glColor4f(1.0, 0, 0, 1.0);
  glLineWidth(10);
  glBegin(GL_LINES);
  glVertex3f(0, kSide - 1, 0);
  glVertex3f(kSide - 1, kSide - 1, 0);
  glVertex3f(0, kSide - 1, 0);
  glVertex3f(0, 50 * kSide, 0);
  glVertex3f(kSide - 1, kSide - 1, 0);
  glVertex3f(kSide - 1, 50 * kSide, 0);
  glEnd();
  glLineWidth(1.0);
  glColor4f(1.0, 1.0, 1.0, 1.0);
  [self flushContext];
}

#pragma mark - NSOpenGLView

- (void)activateContext {
  [[self openGLContext] makeCurrentContext];
}

- (void)flushContext {
  [[self openGLContext] flushBuffer];
}

- (void)reshape {
  [self activateContext];
  float w = self.bounds.size.width;
  float h = self.bounds.size.height;
  glViewport(0, 0, (GLsizei)w, (GLsizei)h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  perspective(60, (GLfloat)w / (GLfloat)h, 0.5, 800.0);
  glMatrixMode(GL_MODELVIEW);
  [self setNeedsDisplay:YES];
}

- (void)prepareOpenGL {
  glEnable(GL_DEPTH_TEST);
  glDepthMask(GL_TRUE);
  glClearColor(0.0, 0.0, 0.0, 1.0);
  _active = YES;
  _viewPoint = [[ClothViewPoint alloc] init];
  _arrays = [[ClothViewModel alloc] init];
  _sim = [[ClothSim alloc] init];
  [_sim setupClothSimulation];
  glEnable(GL_TEXTURE_2D);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glVertexPointer(3, GL_FLOAT, 0, [_sim getParticles]);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glTexCoordPointer(2, GL_SHORT, 0, _arrays->text_verts);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHT1);
  glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);
  glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
  [NSTimer scheduledTimerWithTimeInterval:0.02
                                   target:self
                                 selector:@selector(update)
                                 userInfo:nil
                                  repeats:YES];
}

#pragma mark - ClothView
#pragma mark - Private

- (void)tick {
  [_viewPoint update];
  if (_active) {
    [_sim stepForewardClothSimulation];
  }
}

- (void)update {
  [self tick];
  [self setNeedsDisplay:YES];
}

#pragma mark - Event Responders

- (void)keyDown:(NSEvent *)theEvent {
}

- (void)mouseDown:(NSEvent *)theEvent {
  [_viewPoint mouseDownWithPoint:[self convertPoint:[theEvent locationInWindow]
                                           fromView:nil]];
}

- (void)mouseDragged:(NSEvent *)theEvent {
  [_viewPoint
      mouseDraggedWithPoint:[self convertPoint:[theEvent locationInWindow]
                                      fromView:nil]];
}

- (void)mouseUp:(NSEvent *)theEvent {
}

- (void)scrollWheel:(NSEvent *)theEvent {
  [_viewPoint zoom:[theEvent deltaY] / 2.0f];
}

#pragma mark - IBAction

- (IBAction)windChanged:(NSSlider *)sender {
  [_sim setWind:[sender floatValue]];
}

- (IBAction)cameraHeightChanged:(NSSlider *)sender {
  [_viewPoint setCameraHeight:[sender floatValue]];
}

- (IBAction)releaseCloth:(id)sender {
  [_sim setFreeCloth];
}

- (IBAction)toggleActive:(NSSegmentedControl *)sender {
  _active = (sender.selectedSegment == 0);
}

@end
