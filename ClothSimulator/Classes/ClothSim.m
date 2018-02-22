//
//  ClothSim.m
//  ClothSimulator
//
//  Created by Derek Blair on 2014-03-31.
//  Copyright (c) 2018 Derek Blair. All rights reserved.
//

#import "ClothSim.h"
#import "la.h"

typedef struct State {
  float *x;  // position
  float *v;  // velocity
  float *n;  // normals
  float *f;  // force
} State;

typedef struct Derivative {
  float *dx;  // derivative of position: velocity
  float *dv;  // derivative of velocity: acceleration
} Derivative;

//** Contants

static const float kS = 60.0f;   // stretch constant
static const float kSD = 15.0f;  // diagonal stretch constant
static const float kH = 0.015f;  // step size in seconds
static const float kG = -9.81f;  // acceleration due to gravity m/s^2
static const float kM = 0.05f;   // 50 grams
static const float kD = 0.02f;   // damping constant
static const float kDW = 0.1f;   // wind damping constant
static const float kSB = 12.0f;  // bend stretch constant
static const float kFric = 1.0f;
static const float kFricfloor = 0.50f;
static float normaltop[4] = {0, 1, 0, 0};

//** Static Helper Methods
static void addComponent(int i, int j, float bas, float stretch, float *targ,
                         float *xc) {
  float forc;
  float c[4];
  float *a = xc + 3 * i;
  float *b = xc + 3 * j;
  float bb;
  sub3(b, a, c);
  bb = normalize3(c) - bas;
  forc = stretch * (bb);
  scalm3(c, forc);
  add3(targ, c, targ);
}

static void addNormal(int i, int j, int k, float *targ, float *xc) {
  float d[4];
  float a[4];
  float b[4];
  float c[4];
  copy3(a, xc + 3 * i);
  copy3(b, xc + 3 * j);
  copy3(c, xc + 3 * k);
  sub3(c, a, c);
  sub3(b, a, b);
  normalize3(c);
  normalize3(b);
  cross3(b, c, d);
  add3(targ, d, targ);
}

static void computeNormals(float *xc, float *nc) {
  int i;
  float nrml[4];
  for (i = 0; i < kNumberParticles; i++) {
    zero(nrml, 3);

    if (((i % kSide) != (kSide - 1)) && (i < kSide * (kSide - 1))) {
      addNormal(i, i + 1, i + 1 + kSide, nrml, xc);
      addNormal(i, i + 1 + kSide, i + kSide, nrml, xc);
    }
    if (((i % kSide) != (kSide - 1)) && (i >= kSide)) {
      addNormal(i, i - kSide + 1, i + 1, nrml, xc);
      addNormal(i, i - kSide, i - kSide + 1, nrml, xc);
    }
    if (((i % kSide) != 0) && (i < kSide * (kSide - 1))) {
      addNormal(i, i + kSide, i + kSide - 1, nrml, xc);
      addNormal(i, i + kSide - 1, i - 1, nrml, xc);
    }
    if (((i % kSide) != 0) && (i >= kSide)) {
      addNormal(i, i - 1, i - kSide - 1, nrml, xc);
      addNormal(i, i - kSide - 1, i - kSide, nrml, xc);
    }

    normalize3(nrml);
    copy3(nc + 3 * i, nrml);
  }
}

@interface ClothSim ()

- (void)evaluate:(State *)initial
              dt:(float)dt
      derivative:(Derivative *)d
          output:(Derivative *)output;
- (void)integrate:(State *)state dt:(float)dt;
- (void)forceWithPosition:(float *)xc
                 velocity:(float *)vc
                    force:(float *)fc
                  normals:(float *)nc
                     wind:(float *)windc;
- (void)applyConstraints;

@end

@implementation ClothSim {
  State _mstate;
  State _tempstate;

  Derivative _ka;
  Derivative _kb;
  Derivative _kc;
  Derivative _kd;

  float *_dxdt;
  float *_dvdt;
  float _windvec[4];
  float _xmin, _xmax, _ymin, _ymax, _zmin, _zmax;

  BOOL _release;
  BOOL _floor;
}

#pragma mark - Computation

- (void)evaluate:(State *)initial
              dt:(float)dt
      derivative:(Derivative *)d
          output:(Derivative *)output {
  int i;
  State state = _tempstate;

  float windloc[4];

  if (d != NULL) {
    for (i = 0; i < kNumberFloats; i++) {
      state.x[i] = initial->x[i] + d->dx[i] * dt;
      state.v[i] = initial->v[i] + d->dv[i] * dt;
    }
  } else {
    copyVect(state.x, initial->x, kNumberFloats);
    copyVect(state.v, initial->v, kNumberFloats);
  }

  copyVect(output->dx, state.v, kNumberFloats);

  copy3(windloc, _windvec);

  windloc[2] += (arc4random() % 100) / 100.0f;

  [self forceWithPosition:state.x
                 velocity:state.v
                    force:output->dv
                  normals:state.n
                     wind:windloc];

  scalarMultiply(output->dv, 1.0f / kM, kNumberFloats);
}

- (void)applyConstraints {
  int i;

  if (!_release) {
    _mstate.x[3 * (kSide * (kSide - 1))] = 0;
    _mstate.x[3 * (kSide * (kSide - 1)) + 1] = kSide - 1;
    _mstate.x[3 * (kSide * (kSide - 1)) + 2] = 0;

    _mstate.x[3 * (kSide * kSide - 1)] = kSide - 1;
    _mstate.x[3 * (kSide * kSide - 1) + 1] = kSide - 1;
    _mstate.x[3 * (kSide * kSide - 1) + 2] = 0;

    _mstate.v[3 * (kSide * (kSide - 1))] = 0;
    _mstate.v[3 * (kSide * (kSide - 1)) + 1] = 0;
    _mstate.v[3 * (kSide * (kSide - 1)) + 2] = 0;

    _mstate.v[3 * (kSide * kSide - 1)] = 0;
    _mstate.v[3 * (kSide * kSide - 1) + 1] = 0;
    _mstate.v[3 * (kSide * kSide - 1) + 2] = 0;
  }
  if (_floor) {
    for (i = 0; i < kNumberParticles; i++) {
      if (_mstate.x[3 * i + 1] < ztable + 0.2)
        _mstate.x[3 * i + 1] = ztable + 0.2;
    }

    for (i = 0; i < kNumberParticles; i++) {
      if (_mstate.x[3 * i] > _xmin && _mstate.x[3 * i] < _xmax &&
          _mstate.x[3 * i + 1] > _ymin && _mstate.x[3 * i + 1] < _ymax &&
          _mstate.x[3 * i + 2] > _zmin && _mstate.x[3 * i + 2] < _zmax) {
        float xl = _mstate.x[3 * i] - _xmin;
        float xr = _xmax - _mstate.x[3 * i];

        float yl = _mstate.x[3 * i + 1] - _ymin;
        float yr = _ymax - _mstate.x[3 * i + 1];

        float zl = _mstate.x[3 * i + 2] - _zmin;
        float zr = _zmax - _mstate.x[3 * i + 2];

        if (xl <= xr && xl <= yl && xl <= yr && xl <= zl && xl <= zr) {
          _mstate.x[3 * i] = _xmin;
        } else if (xr <= xl && xr <= yl && xr <= yr && xr <= zl && xr <= zr) {
          _mstate.x[3 * i] = _xmax;
        } else if (yl <= xl && yl <= xr && yl <= yr && yl <= zl && yl <= zr) {
          _mstate.x[3 * i + 1] = _ymin;

        } else if (yr <= xl && yr <= xr && yr <= yl && yr <= zl && yr <= zr) {
          _mstate.x[3 * i + 1] = _ymax;

        } else if (zl <= xl && zl <= xr && zl <= yl && zl <= yr && zl <= zr) {
          _mstate.x[3 * i + 2] = _zmin;

        } else if (zr <= xl && zr <= xr && zr <= yl && zr <= yr && zr <= zl) {
          _mstate.x[3 * i + 2] = _zmax;
        }
      }
    }
  }
}

- (void)integrate:(State *)state dt:(float)dt {
  [self evaluate:state dt:0.0f derivative:NULL output:&_ka];
  [self evaluate:state dt:dt * 0.5f derivative:&_ka output:&_kb];
  [self evaluate:state dt:dt * 0.5f derivative:&_kb output:&_kc];
  [self evaluate:state dt:dt derivative:&_kc output:&_kd];

  for (NSUInteger i = 0; i < kNumberFloats; i++) {
    _dxdt[i] = (1.0f / 6.0f) *
               (_ka.dx[i] + 2.0f * (_kb.dx[i] + _kc.dx[i]) + _kd.dx[i]);
    _dvdt[i] = (1.0f / 6.0f) *
               (_ka.dv[i] + 2.0f * (_kb.dv[i] + _kc.dv[i]) + _kd.dv[i]);
  }
  addVect(state->x, _dxdt, dt, kNumberFloats);
  addVect(state->v, _dvdt, dt, kNumberFloats);
}

- (void)forceWithPosition:(float *)xc
                 velocity:(float *)vc
                    force:(float *)fc
                  normals:(float *)nc
                     wind:(float *)windc {
  int i;
  float speed;
  float fact;
  float a[3];
  float b[3];

  zero(fc, kNumberFloats);

  computeNormals(xc, nc);

  for (i = 0; i < kNumberParticles; i++) {
    fc[3 * i + 1] += kG * kM;
  }

  if (windc) {
    for (i = 0; i < kNumberParticles; i++) {
      speed = norm3(windc);
      fact = dot3(windc, nc + 3 * i);
      copy3(a, nc + 3 * i);
      scalm3(a, fact * speed * kDW);
      add3(a, fc + 3 * i, fc + 3 * i);
    }
  }

  for (i = 0; i < kNumberParticles; i++) {
    float *targ = fc + 3 * i;
    // stretch
    if ((i % kSide) != (kSide - 1)) addComponent(i, i + 1, 1.0, kS, targ, xc);
    if ((i % kSide) != 0) addComponent(i, i - 1, 1.0, kS, targ, xc);
    if (i >= kSide) addComponent(i, i - kSide, 1.0, kS, targ, xc);
    if (i < kSide * (kSide - 1)) addComponent(i, i + kSide, 1.0, kS, targ, xc);
    // shear
    if (((i % kSide) != (kSide - 1)) && (i < kSide * (kSide - 1)))
      addComponent(i, i + 1 + kSide, sqrtf(2), kSD, targ, xc);
    if (((i % kSide) != (kSide - 1)) && (i >= kSide))
      addComponent(i, i - kSide + 1, sqrtf(2), kSD, targ, xc);
    if (((i % kSide) != 0) && (i < kSide * (kSide - 1)))
      addComponent(i, i + kSide - 1, sqrtf(2), kSD, targ, xc);
    if (((i % kSide) != 0) && (i >= kSide))
      addComponent(i, i - kSide - 1, sqrtf(2), kSD, targ, xc);

    // bend
    if ((i % kSide) < (kSide - 2)) addComponent(i, i + 2, 2.0, kSB, targ, xc);
    if ((i % kSide) > 1) addComponent(i, i - 2, 2.0, kSB, targ, xc);
    if (i >= 2 * kSide) addComponent(i, i - 2 * kSide, 2.0, kSB, targ, xc);
    if (i < kSide * (kSide - 2))
      addComponent(i, i + 2 * kSide, 2.0, kSB, targ, xc);
  }

  for (i = 0; i < kNumberParticles; i++) {
    copy3(a, vc + 3 * i);
    copy3(b, nc + 3 * i);
    fact = dot3(a, b);
    scalm3(b, -fact * norm3(a) * kDW);
    scalm3(a, -kD);
    add3(b, fc + 3 * i, fc + 3 * i);
    add3(a, fc + 3 * i, fc + 3 * i);
  }

  if (_floor) {
    for (i = 0; i < kNumberParticles; i++) {
      if (xc[3 * i + 1] < ztable + 0.4) {
        copy3(a, vc + 3 * i);
        speed = norm3(a);
        if (speed > 0) {
          normalize3(a);
          fact = 1.0f - dot3(normaltop, a);
          scalm3(a, -kFricfloor * fact);
          add3(a, fc + 3 * i, fc + 3 * i);
        }
      }

      if (((xc[3 * i] > _xmin - 0.2)) && ((xc[3 * i] < _xmax + 0.2)) &&
          ((xc[3 * i + 1] > _ymin - 0.2)) && ((xc[3 * i + 1] < _ymax + 0.2)) &&
          ((xc[3 * i + 2] > _zmin - 0.2)) && ((xc[3 * i + 2] < _zmax + 0.2))) {
        float xl = xc[3 * i] - _xmin + 0.2;
        float xr = 0.2 + _xmax - xc[3 * i];

        float yl = xc[3 * i + 1] - _ymin + 0.2;
        float yr = 0.2 + _ymax - xc[3 * i + 1];

        float zl = 0.2 + xc[3 * i + 2] - _zmin;
        float zr = 0.2 + _zmax - xc[3 * i + 2];

        if (yr <= xl && yr <= xr && yr <= yl && yr <= zl &&
            yr <= zr)  // top face
        {
          copy3(a, vc + 3 * i);
          speed = norm3(a);
          if (speed > 0) {
            normalize3(a);
            fact = 1.0f - dot3(normaltop, a);
            scalm3(a, -kFric * fact);
            add3(a, fc + 3 * i, fc + 3 * i);
          }
        }
      }
    }
  }
}

- (void)stepForewardClothSimulation {
  [self integrate:&_mstate dt:kH];
  [self applyConstraints];
  computeNormals(_mstate.x, _mstate.n);
}

- (void)setupClothSimulation {
  _floor = YES;
  _mstate.x = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _mstate.v = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _mstate.f = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _mstate.n = (float *)calloc(kNumberFloats + 1, sizeof(float));

  _ka.dv = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _ka.dx = (float *)malloc((kNumberFloats + 1) * sizeof(float));

  _kb.dv = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _kb.dx = (float *)malloc((kNumberFloats + 1) * sizeof(float));

  _kc.dv = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _kc.dx = (float *)malloc((kNumberFloats + 1) * sizeof(float));

  _kd.dv = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _kd.dx = (float *)malloc((kNumberFloats + 1) * sizeof(float));

  _tempstate.x = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _tempstate.v = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _tempstate.f = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _tempstate.n = (float *)malloc((kNumberFloats + 1) * sizeof(float));

  _dxdt = (float *)malloc((kNumberFloats + 1) * sizeof(float));
  _dvdt = (float *)malloc((kNumberFloats + 1) * sizeof(float));

  int i;
  for (i = 0; i < kNumberParticles; i++) {
    _mstate.x[3 * i] = (float)(i % kSide);
    _mstate.x[3 * i + 1] = (float)(i / kSide);
    _mstate.x[3 * i + 2] = 0;

    _mstate.v[3 * i] = 0;
    _mstate.v[3 * i + 1] = 0;
    _mstate.v[3 * i + 2] = 0;

    _mstate.f[3 * i] = 0;
    _mstate.f[3 * i + 1] = kM * kG;
    _mstate.f[3 * i + 2] = 0;
  }
  _xmin = 0 + kSide * 0.2 - 0.5;
  _ymin = -kSide / 2 - 0.5;
  _zmax = -kSide * 0.2 + 0.5;
  _xmax = kSide * 0.6 + kSide * 0.2 + 0.5;
  _zmin = -kSide * 0.6 - kSide * 0.2 - 0.5;
  _ymax = kSide / 2 - kSide / 2 + 0.5;

  _windvec[0] = 0;
  _windvec[1] = 0;
  _windvec[2] = 0.f;
  computeNormals(_mstate.x, _mstate.n);
}

- (void)shutDownClothSimulation {
  free(_mstate.x);
  _mstate.x = NULL;
  free(_mstate.v);
  _mstate.v = NULL;
  free(_mstate.f);
  _mstate.f = NULL;
  free(_mstate.n);
  _mstate.n = NULL;
  free(_tempstate.x);
  _tempstate.x = NULL;
  free(_tempstate.v);
  _tempstate.v = NULL;
  free(_tempstate.f);
  _tempstate.f = NULL;
  free(_tempstate.n);
  _tempstate.n = NULL;
  free(_ka.dv);
  _ka.dv = NULL;
  free(_ka.dx);
  _ka.dx = NULL;
  free(_kb.dv);
  _kb.dv = NULL;
  free(_kb.dx);
  _kb.dx = NULL;
  free(_kc.dv);
  _kc.dv = NULL;
  free(_kc.dx);
  _kc.dx = NULL;
  free(_kd.dv);
  _kd.dv = NULL;
  free(_kd.dx);
  _kd.dx = NULL;
  free(_dxdt);
  _dxdt = NULL;
  free(_dvdt);
  _dvdt = NULL;
}

- (float *)getParticles {
  return _mstate.x;
}

- (float *)getNormals {
  return _mstate.n;
}

- (float *)getForce {
  return _mstate.f;
}

- (float *)getVel {
  return _mstate.v;
}

- (void)setFreeCloth {
  _release = YES;
}

- (void)removeFloor {
  _floor = NO;
}

- (void)setWind:(float)wd {
  _windvec[2] = wd;
}

@end
