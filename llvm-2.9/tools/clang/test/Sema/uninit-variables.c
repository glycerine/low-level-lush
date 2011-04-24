// RUN: %clang_cc1 -fsyntax-only -Wuninitialized-experimental -fsyntax-only -fblocks %s -verify

int test1() {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

int test2() {
  int x = 0;
  return x; // no-warning
}

int test3() {
  int x;
  x = 0;
  return x; // no-warning
}

int test4() {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  ++x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
  return x; 
}

int test5() {
  int x, y; // expected-note{{variable 'y' is declared here}} expected-note{{add initialization to silence this warning}}
  x = y; // expected-warning{{variable 'y' is possibly uninitialized when used here}}
  return x;
}

int test6() {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  x += 2; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
  return x;
}

int test7(int y) {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  if (y)
    x = 1;
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

int test8(int y) {
  int x;
  if (y)
    x = 1;
  else
    x = 0;
  return x;
}

int test9(int n) {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  for (unsigned i = 0 ; i < n; ++i) {
    if (i == n - 1)
      break;
    x = 1;
  }
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

int test10(unsigned n) {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  for (unsigned i = 0 ; i < n; ++i) {
    x = 1;
  }
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

int test11(unsigned n) {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  for (unsigned i = 0 ; i <= n; ++i) {
    x = 1;
  }
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

void test12(unsigned n) {
  for (unsigned i ; n ; ++i) ; // expected-warning{{variable 'i' is possibly uninitialized when used here}} expected-note{{variable 'i' is declared here}} expected-note{{add initialization to silence this warning}}
}

int test13() {
  static int i;
  return i; // no-warning
}

// Simply don't crash on this test case.
void test14() {
  const char *p = 0;
  for (;;) {}
}

void test15() {
  int x = x; // expected-warning{{variable 'x' is possibly uninitialized when used here}} expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
}

// Don't warn in the following example; shows dataflow confluence.
char *test16_aux();
void test16() {
  char *p = test16_aux();
  for (unsigned i = 0 ; i < 100 ; i++)
    p[i] = 'a'; // no-warning
}

void test17() {
  // Don't warn multiple times about the same uninitialized variable
  // along the same path.
  int *x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  *x = 1; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
  *x = 1; // no-warning
}

int test18(int x, int y) {
  int z;
  if (x && y && (z = 1)) {
    return z; // no-warning
  }
  return 0;
}

int test19_aux1();
int test19_aux2();
int test19_aux3(int *x);
int test19() {
  int z;
  if (test19_aux1() + test19_aux2() && test19_aux1() && test19_aux3(&z))
    return z; // no-warning
  return 0;
}

int test20() {
  int z; // expected-note{{variable 'z' is declared here}} expected-note{{add initialization to silence this warning}}
  if ((test19_aux1() + test19_aux2() && test19_aux1()) || test19_aux3(&z))
    return z; // expected-warning{{variable 'z' is possibly uninitialized when used here}}
  return 0;
}

int test21(int x, int y) {
  int z; // expected-note{{variable 'z' is declared here}} expected-note{{add initialization to silence this warning}}
  if ((x && y) || test19_aux3(&z) || test19_aux2())
    return z; // expected-warning{{variable 'z' is possibly uninitialized when used here}}
  return 0;
}

int test22() {
  int z;
  while (test19_aux1() + test19_aux2() && test19_aux1() && test19_aux3(&z))
    return z; // no-warning
  return 0;
}

int test23() {
  int z;
  for ( ; test19_aux1() + test19_aux2() && test19_aux1() && test19_aux3(&z) ; )
    return z; // no-warning
  return 0;
}

// The basic uninitialized value analysis doesn't have enough path-sensitivity
// to catch initializations relying on control-dependencies spanning multiple
// conditionals.  This possibly can be handled by making the CFG itself
// represent such control-dependencies, but it is a niche case.
int test24(int flag) {
  unsigned val; // expected-note{{variable 'val' is declared here}} expected-note{{add initialization to silence this warning}}
  if (flag)
    val = 1;
  if (!flag)
    val = 1;
  return val; // expected-warning{{variable 'val' is possibly uninitialized when used here}}
}

float test25() {
  float x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

typedef int MyInt;
MyInt test26() {
  MyInt x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

// Test handling of sizeof().
int test27() {
  struct test_27 { int x; } *y;
  return sizeof(y->x); // no-warning
}

int test28() {
  int len; // expected-note{{variable 'len' is declared here}} expected-note{{add initialization to silence this warning}}
  return sizeof(int[len]); // expected-warning{{variable 'len' is possibly uninitialized when used here}}
}

void test29() {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  (void) ^{ (void) x; }; // expected-warning{{variable 'x' is possibly uninitialized when captured by block}}
}

void test30() {
  static int x; // no-warning
  (void) ^{ (void) x; };
}

void test31() {
  __block int x; // no-warning
  (void) ^{ (void) x; };
}

int test32_x;
void test32() {
  (void) ^{ (void) test32_x; }; // no-warning
}

void test_33() {
  int x; // no-warning
  (void) x;
}

int test_34() {
  int x; // expected-note{{variable 'x' is declared here}} expected-note{{add initialization to silence this warning}}
  (void) x;
  return x; // expected-warning{{variable 'x' is possibly uninitialized when used here}}
}

// Test that this case doesn't crash.
void test35(int x) {
  __block int y = 0;
  ^{ y = (x == 0); }();
}

// Test handling of indirect goto.
void test36()
{
  void **pc; // expected-note{{variable 'pc' is declared here}} expected-note{{add initialization to silence this warning}}
  void *dummy[] = { &&L1, &&L2 };
 L1:
    goto *pc; // expected-warning{{variable 'pc' is possibly uninitialized when used here}}
 L2:
    goto *pc;
}

// Test && nested in ||.
int test37_a();
int test37_b();
int test37()
{
    int identifier;
    if ((test37_a() && (identifier = 1)) ||
        (test37_b() && (identifier = 2))) {
        return identifier; // no-warning
    }
    return 0;
}

// Test merging of path-specific dataflow values (without asserting).
int test38(int r, int x, int y)
{
  int z;
  return ((r < 0) || ((r == 0) && (x < y)));
}

