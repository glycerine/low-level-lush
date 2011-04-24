//===--- CGDeclCXX.cpp - Emit LLVM Code for C++ declarations --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This contains code dealing with code generation of C++ declarations
//
//===----------------------------------------------------------------------===//

#include "CodeGenFunction.h"
#include "CGObjCRuntime.h"
#include "CGCXXABI.h"
#include "clang/Frontend/CodeGenOptions.h"
#include "llvm/Intrinsics.h"

using namespace clang;
using namespace CodeGen;

static void EmitDeclInit(CodeGenFunction &CGF, const VarDecl &D,
                         llvm::Constant *DeclPtr) {
  assert(D.hasGlobalStorage() && "VarDecl must have global storage!");
  assert(!D.getType()->isReferenceType() && 
         "Should not call EmitDeclInit on a reference!");
  
  ASTContext &Context = CGF.getContext();
    
  const Expr *Init = D.getInit();
  QualType T = D.getType();
  bool isVolatile = Context.getCanonicalType(T).isVolatileQualified();

  unsigned Alignment = Context.getDeclAlign(&D).getQuantity();
  if (!CGF.hasAggregateLLVMType(T)) {
    llvm::Value *V = CGF.EmitScalarExpr(Init);
    CodeGenModule &CGM = CGF.CGM;
    Qualifiers::GC GCAttr = CGM.getContext().getObjCGCAttrKind(T);
    if (GCAttr == Qualifiers::Strong)
      CGM.getObjCRuntime().EmitObjCGlobalAssign(CGF, V, DeclPtr,
                                                D.isThreadSpecified());
    else if (GCAttr == Qualifiers::Weak)
      CGM.getObjCRuntime().EmitObjCWeakAssign(CGF, V, DeclPtr);
    else
      CGF.EmitStoreOfScalar(V, DeclPtr, isVolatile, Alignment, T);
  } else if (T->isAnyComplexType()) {
    CGF.EmitComplexExprIntoAddr(Init, DeclPtr, isVolatile);
  } else {
    CGF.EmitAggExpr(Init, AggValueSlot::forAddr(DeclPtr, isVolatile, true));
  }
}

/// Emit code to cause the destruction of the given variable with
/// static storage duration.
static void EmitDeclDestroy(CodeGenFunction &CGF, const VarDecl &D,
                            llvm::Constant *DeclPtr) {
  CodeGenModule &CGM = CGF.CGM;
  ASTContext &Context = CGF.getContext();
  
  QualType T = D.getType();
  
  // Drill down past array types.
  const ConstantArrayType *Array = Context.getAsConstantArrayType(T);
  if (Array)
    T = Context.getBaseElementType(Array);
  
  /// If that's not a record, we're done.
  /// FIXME:  __attribute__((cleanup)) ?
  const RecordType *RT = T->getAs<RecordType>();
  if (!RT)
    return;
  
  CXXRecordDecl *RD = cast<CXXRecordDecl>(RT->getDecl());
  if (RD->hasTrivialDestructor())
    return;
  
  CXXDestructorDecl *Dtor = RD->getDestructor();
  
  llvm::Constant *DtorFn;
  if (Array) {
    DtorFn = 
      CodeGenFunction(CGM).GenerateCXXAggrDestructorHelper(Dtor, Array, 
                                                           DeclPtr);
    const llvm::Type *Int8PtrTy =
      llvm::Type::getInt8PtrTy(CGM.getLLVMContext());
    DeclPtr = llvm::Constant::getNullValue(Int8PtrTy);
  } else
    DtorFn = CGM.GetAddrOfCXXDestructor(Dtor, Dtor_Complete);
  
  CGF.EmitCXXGlobalDtorRegistration(DtorFn, DeclPtr);
}

void CodeGenFunction::EmitCXXGlobalVarDeclInit(const VarDecl &D,
                                               llvm::Constant *DeclPtr) {

  const Expr *Init = D.getInit();
  QualType T = D.getType();

  if (!T->isReferenceType()) {
    EmitDeclInit(*this, D, DeclPtr);
    EmitDeclDestroy(*this, D, DeclPtr);
    return;
  }

  unsigned Alignment = getContext().getDeclAlign(&D).getQuantity();
  RValue RV = EmitReferenceBindingToExpr(Init, &D);
  EmitStoreOfScalar(RV.getScalarVal(), DeclPtr, false, Alignment, T);
}

void
CodeGenFunction::EmitCXXGlobalDtorRegistration(llvm::Constant *DtorFn,
                                               llvm::Constant *DeclPtr) {
  // Generate a global destructor entry if not using __cxa_atexit.
  if (!CGM.getCodeGenOpts().CXAAtExit) {
    CGM.AddCXXDtorEntry(DtorFn, DeclPtr);
    return;
  }

  std::vector<const llvm::Type *> Params;
  Params.push_back(Int8PtrTy);

  // Get the destructor function type
  const llvm::Type *DtorFnTy =
    llvm::FunctionType::get(llvm::Type::getVoidTy(getLLVMContext()),
                            Params, false);
  DtorFnTy = llvm::PointerType::getUnqual(DtorFnTy);

  Params.clear();
  Params.push_back(DtorFnTy);
  Params.push_back(Int8PtrTy);
  Params.push_back(Int8PtrTy);

  // Get the __cxa_atexit function type
  // extern "C" int __cxa_atexit ( void (*f)(void *), void *p, void *d );
  const llvm::FunctionType *AtExitFnTy =
    llvm::FunctionType::get(ConvertType(getContext().IntTy), Params, false);

  llvm::Constant *AtExitFn = CGM.CreateRuntimeFunction(AtExitFnTy,
                                                       "__cxa_atexit");

  llvm::Constant *Handle = CGM.CreateRuntimeVariable(Int8PtrTy,
                                                     "__dso_handle");
  llvm::Value *Args[3] = { llvm::ConstantExpr::getBitCast(DtorFn, DtorFnTy),
                           llvm::ConstantExpr::getBitCast(DeclPtr, Int8PtrTy),
                           llvm::ConstantExpr::getBitCast(Handle, Int8PtrTy) };
  Builder.CreateCall(AtExitFn, &Args[0], llvm::array_endof(Args));
}

void CodeGenFunction::EmitCXXGuardedInit(const VarDecl &D,
                                         llvm::GlobalVariable *DeclPtr) {
  CGM.getCXXABI().EmitGuardedInit(*this, D, DeclPtr);
}

static llvm::Function *
CreateGlobalInitOrDestructFunction(CodeGenModule &CGM,
                                   const llvm::FunctionType *FTy,
                                   llvm::StringRef Name) {
  llvm::Function *Fn =
    llvm::Function::Create(FTy, llvm::GlobalValue::InternalLinkage,
                           Name, &CGM.getModule());
  if (!CGM.getContext().getLangOptions().AppleKext) {
    // Set the section if needed.
    if (const char *Section = 
          CGM.getContext().Target.getStaticInitSectionSpecifier())
      Fn->setSection(Section);
  }

  if (!CGM.getLangOptions().Exceptions)
    Fn->setDoesNotThrow();

  return Fn;
}

void
CodeGenModule::EmitCXXGlobalVarDeclInitFunc(const VarDecl *D,
                                            llvm::GlobalVariable *Addr) {
  const llvm::FunctionType *FTy
    = llvm::FunctionType::get(llvm::Type::getVoidTy(VMContext),
                              false);

  // Create a variable initialization function.
  llvm::Function *Fn =
    CreateGlobalInitOrDestructFunction(*this, FTy, "__cxx_global_var_init");

  CodeGenFunction(*this).GenerateCXXGlobalVarDeclInitFunc(Fn, D, Addr);

  if (D->hasAttr<InitPriorityAttr>()) {
    unsigned int order = D->getAttr<InitPriorityAttr>()->getPriority();
    OrderGlobalInits Key(order, PrioritizedCXXGlobalInits.size());
    PrioritizedCXXGlobalInits.push_back(std::make_pair(Key, Fn));
    DelayedCXXInitPosition.erase(D);
  }
  else {
    llvm::DenseMap<const Decl *, unsigned>::iterator I =
      DelayedCXXInitPosition.find(D);
    if (I == DelayedCXXInitPosition.end()) {
      CXXGlobalInits.push_back(Fn);
    } else {
      assert(CXXGlobalInits[I->second] == 0);
      CXXGlobalInits[I->second] = Fn;
      DelayedCXXInitPosition.erase(I);
    }
  }
}

void
CodeGenModule::EmitCXXGlobalInitFunc() {
  while (!CXXGlobalInits.empty() && !CXXGlobalInits.back())
    CXXGlobalInits.pop_back();

  if (CXXGlobalInits.empty() && PrioritizedCXXGlobalInits.empty())
    return;

  const llvm::FunctionType *FTy
    = llvm::FunctionType::get(llvm::Type::getVoidTy(VMContext),
                              false);

  // Create our global initialization function.
  llvm::Function *Fn = 
    CreateGlobalInitOrDestructFunction(*this, FTy, "_GLOBAL__I_a");

  if (!PrioritizedCXXGlobalInits.empty()) {
    llvm::SmallVector<llvm::Constant*, 8> LocalCXXGlobalInits;
    llvm::array_pod_sort(PrioritizedCXXGlobalInits.begin(), 
                         PrioritizedCXXGlobalInits.end()); 
    for (unsigned i = 0; i < PrioritizedCXXGlobalInits.size(); i++) {
      llvm::Function *Fn = PrioritizedCXXGlobalInits[i].second;
      LocalCXXGlobalInits.push_back(Fn);
    }
    LocalCXXGlobalInits.append(CXXGlobalInits.begin(), CXXGlobalInits.end());
    CodeGenFunction(*this).GenerateCXXGlobalInitFunc(Fn,
                                                    &LocalCXXGlobalInits[0],
                                                    LocalCXXGlobalInits.size());
  }
  else
    CodeGenFunction(*this).GenerateCXXGlobalInitFunc(Fn,
                                                     &CXXGlobalInits[0],
                                                     CXXGlobalInits.size());
  AddGlobalCtor(Fn);
}

void CodeGenModule::EmitCXXGlobalDtorFunc() {
  if (CXXGlobalDtors.empty())
    return;

  const llvm::FunctionType *FTy
    = llvm::FunctionType::get(llvm::Type::getVoidTy(VMContext),
                              false);

  // Create our global destructor function.
  llvm::Function *Fn =
    CreateGlobalInitOrDestructFunction(*this, FTy, "_GLOBAL__D_a");

  CodeGenFunction(*this).GenerateCXXGlobalDtorFunc(Fn, CXXGlobalDtors);
  AddGlobalDtor(Fn);
}

/// Emit the code necessary to initialize the given global variable.
void CodeGenFunction::GenerateCXXGlobalVarDeclInitFunc(llvm::Function *Fn,
                                                       const VarDecl *D,
                                                 llvm::GlobalVariable *Addr) {
  StartFunction(GlobalDecl(), getContext().VoidTy, Fn, FunctionArgList(),
                SourceLocation());

  // Use guarded initialization if the global variable is weak due to
  // being a class template's static data member.
  if (Addr->hasWeakLinkage() && D->getInstantiatedFromStaticDataMember()) {
    EmitCXXGuardedInit(*D, Addr);
  } else {
    EmitCXXGlobalVarDeclInit(*D, Addr);
  }

  FinishFunction();
}

void CodeGenFunction::GenerateCXXGlobalInitFunc(llvm::Function *Fn,
                                                llvm::Constant **Decls,
                                                unsigned NumDecls) {
  StartFunction(GlobalDecl(), getContext().VoidTy, Fn, FunctionArgList(),
                SourceLocation());

  for (unsigned i = 0; i != NumDecls; ++i)
    if (Decls[i])
      Builder.CreateCall(Decls[i]);

  FinishFunction();
}

void CodeGenFunction::GenerateCXXGlobalDtorFunc(llvm::Function *Fn,
                  const std::vector<std::pair<llvm::WeakVH, llvm::Constant*> >
                                                &DtorsAndObjects) {
  StartFunction(GlobalDecl(), getContext().VoidTy, Fn, FunctionArgList(),
                SourceLocation());

  // Emit the dtors, in reverse order from construction.
  for (unsigned i = 0, e = DtorsAndObjects.size(); i != e; ++i) {
    llvm::Value *Callee = DtorsAndObjects[e - i - 1].first;
    llvm::CallInst *CI = Builder.CreateCall(Callee,
                                            DtorsAndObjects[e - i - 1].second);
    // Make sure the call and the callee agree on calling convention.
    if (llvm::Function *F = dyn_cast<llvm::Function>(Callee))
      CI->setCallingConv(F->getCallingConv());
  }

  FinishFunction();
}

/// GenerateCXXAggrDestructorHelper - Generates a helper function which when
/// invoked, calls the default destructor on array elements in reverse order of
/// construction.
llvm::Function * 
CodeGenFunction::GenerateCXXAggrDestructorHelper(const CXXDestructorDecl *D,
                                                 const ArrayType *Array,
                                                 llvm::Value *This) {
  FunctionArgList Args;
  ImplicitParamDecl *Dst =
    ImplicitParamDecl::Create(getContext(), 0,
                              SourceLocation(), 0,
                              getContext().getPointerType(getContext().VoidTy));
  Args.push_back(std::make_pair(Dst, Dst->getType()));
  
  const CGFunctionInfo &FI = 
    CGM.getTypes().getFunctionInfo(getContext().VoidTy, Args, 
                                   FunctionType::ExtInfo());
  const llvm::FunctionType *FTy = CGM.getTypes().GetFunctionType(FI, false);
  llvm::Function *Fn = 
    CreateGlobalInitOrDestructFunction(CGM, FTy, "__cxx_global_array_dtor");

  StartFunction(GlobalDecl(), getContext().VoidTy, Fn, Args, SourceLocation());

  QualType BaseElementTy = getContext().getBaseElementType(Array);
  const llvm::Type *BasePtr = ConvertType(BaseElementTy)->getPointerTo();
  llvm::Value *BaseAddrPtr = Builder.CreateBitCast(This, BasePtr);
  
  EmitCXXAggrDestructorCall(D, Array, BaseAddrPtr);
  
  FinishFunction();
  
  return Fn;
}
