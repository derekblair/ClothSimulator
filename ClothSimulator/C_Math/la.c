//
//  la.c
//  ClothSimulator
//
//  Created by Derek Blair on 2014-03-31.
//  Copyright (c) 2015 Derek Blair. All rights reserved.
//

#import "la.h"
#import <Accelerate/Accelerate.h>

void addVect(float* A, float* B, float alpha, int size) {
  cblas_saxpy(size, alpha, B, 1, A, 1);
}

float dotp(float* a, float* b, int size) {
  return cblas_sdot(size, a, 1, b, 1);
}

void scalarMultiply(float* A, float r, int size) { cblas_sscal(size, r, A, 1); }

void copyVect(float* dst, float* src, int size) {
  cblas_scopy(size, src, 1, dst, 1);
}

float norm3(float* a) { return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]); }

void sub3(float* a, float* b, float* c) {
  c[0] = a[0] - b[0];
  c[1] = a[1] - b[1];
  c[2] = a[2] - b[2];
}

void add3(float* a, float* b, float* c) {
  c[0] = a[0] + b[0];
  c[1] = a[1] + b[1];
  c[2] = a[2] + b[2];
}

float normalize3(float* a) {
  float nrm = norm3(a);
  a[0] /= nrm;
  a[1] /= nrm;
  a[2] /= nrm;
  return nrm;
}

void copy3(float* dst, float* src) {
  dst[0] = src[0];
  dst[1] = src[1];
  dst[2] = src[2];
}

void scalm3(float* a, float k) {
  a[0] *= k;
  a[1] *= k;
  a[2] *= k;
}

float dist3(float* a, float* b) {
  float s[3];
  s[0] = (a[0] - b[0]);
  s[1] = (a[1] - b[1]);
  s[2] = (a[2] - b[2]);
  return norm3(s);
}

void zero(float* a, int size) {
  int i;
  for (i = 0; i < size; i++) {
    a[i] = 0.0f;
  }
}

void cross3(float* a, float* b, float* c) {
  float t[3];
  t[0] = a[1] * b[2] - a[2] * b[1];
  t[1] = a[2] * b[0] - a[0] * b[2];
  t[2] = a[0] * b[1] - a[1] * b[0];
  c[0] = t[0];
  c[1] = t[1];
  c[2] = t[2];
}

float dot3(float* a, float* b) {
  return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}
