//
//  la.h
//  ClothSimulator
//
//  Created by Derek Blair on 2014-03-31.
//  Copyright (c) 2015 Derek Blair. All rights reserved.
//

// A+B*alpha -> A.
void addVect(float* A, float* B, float alpha, int size);

// returns dot product of (a) and (b).
float dotp(float* a, float* b, int size);

// r*A -> A
void scalarMultiply(float* A, float r, int size);

// copies size elements from src to dst
void copyVect(float* dst, float* src, int size);

// returns norm of vector (a) with length (size)
float norm3(float* a);

// normalizes a, returns the norm
float normalize3(float* a);

// returns distance between a and b
float dist3(float* a, float* b);

void sub3(float* a, float* b, float* c);

void add3(float* a, float* b, float* c);

void copy3(float* dst, float* src);
// src->dst

void cross3(float* a, float* b, float* c);
// axb->c

void cross4(float* a, float* b, float* c);

void scalm3(float* a, float k);
// k*a->a

void zero(float* a, int size);
// 0->a

float dot3(float* a, float* b);

float dot4(float* a, float* b);
