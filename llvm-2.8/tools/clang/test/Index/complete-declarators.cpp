// This test is line- and column-sensitive, so test commands are at the bottom.
namespace N {
  struct X {
    int f(X);
  };
}

int g(int a);

struct Y { };

struct Z {
  int member;
  friend int N::X::f(N::X);
};

// RUN: c-index-test -code-completion-at=%s:8:5 %s | FileCheck -check-prefix=CHECK-CC1 %s
// CHECK-CC1: NotImplemented:{TypedText const} (30)
// CHECK-CC1: Namespace:{TypedText N}{Text ::} (75)
// CHECK-CC1: NotImplemented:{TypedText operator} (30)
// CHECK-CC1: NotImplemented:{TypedText volatile} (30)
// RUN: c-index-test -code-completion-at=%s:8:11 %s | FileCheck -check-prefix=CHECK-CC2 %s
// CHECK-CC2: NotImplemented:{TypedText const} (30)
// CHECK-CC2-NOT: Namespace:{TypedText N}{Text ::} (75)
// CHECK-CC2-NOT: NotImplemented:{TypedText operator} (30)
// CHECK-CC2: NotImplemented:{TypedText volatile} (30)
// RUN: c-index-test -code-completion-at=%s:13:7 %s | FileCheck -check-prefix=CHECK-CC3 %s
// CHECK-CC3: NotImplemented:{TypedText const} (30)
// CHECK-CC3-NOT: Namespace:{TypedText N}{Text ::} (75)
// CHECK-CC3: NotImplemented:{TypedText operator} (30)
// CHECK-CC3: NotImplemented:{TypedText volatile} (30)
// RUN: c-index-test -code-completion-at=%s:14:14 %s | FileCheck -check-prefix=CHECK-CC4 %s
// CHECK-CC4: NotImplemented:{TypedText const} (30)
// CHECK-CC4: Namespace:{TypedText N}{Text ::} (75)
// CHECK-CC4: NotImplemented:{TypedText operator} (30)
// CHECK-CC4: NotImplemented:{TypedText volatile} (30)
// CHECK-CC4: StructDecl:{TypedText Y} (65)
// CHECK-CC4: StructDecl:{TypedText Z} (20)

