//=- AnalysisBasedWarnings.cpp - Sema warnings based on libAnalysis -*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines analysis_warnings::[Policy,Executor].
// Together they are used by Sema to issue warnings based on inexpensive
// static analysis algorithms in libAnalysis.
//
//===----------------------------------------------------------------------===//

#include "clang/Sema/AnalysisBasedWarnings.h"
#include "clang/Sema/SemaInternal.h"
#include "clang/Sema/ScopeInfo.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Lex/Preprocessor.h"
#include "clang/AST/DeclObjC.h"
#include "clang/AST/DeclCXX.h"
#include "clang/AST/ExprObjC.h"
#include "clang/AST/ExprCXX.h"
#include "clang/AST/StmtObjC.h"
#include "clang/AST/StmtCXX.h"
#include "clang/Analysis/AnalysisContext.h"
#include "clang/Analysis/CFG.h"
#include "clang/Analysis/Analyses/ReachableCode.h"
#include "clang/Analysis/Analyses/CFGReachabilityAnalysis.h"
#include "clang/Analysis/CFGStmtMap.h"
#include "clang/Analysis/Analyses/UninitializedValuesV2.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/Support/Casting.h"

using namespace clang;

//===----------------------------------------------------------------------===//
// Unreachable code analysis.
//===----------------------------------------------------------------------===//

namespace {
  class UnreachableCodeHandler : public reachable_code::Callback {
    Sema &S;
  public:
    UnreachableCodeHandler(Sema &s) : S(s) {}

    void HandleUnreachable(SourceLocation L, SourceRange R1, SourceRange R2) {
      S.Diag(L, diag::warn_unreachable) << R1 << R2;
    }
  };
}

/// CheckUnreachable - Check for unreachable code.
static void CheckUnreachable(Sema &S, AnalysisContext &AC) {
  UnreachableCodeHandler UC(S);
  reachable_code::FindUnreachableCode(AC, UC);
}

//===----------------------------------------------------------------------===//
// Check for missing return value.
//===----------------------------------------------------------------------===//

enum ControlFlowKind {
  UnknownFallThrough,
  NeverFallThrough,
  MaybeFallThrough,
  AlwaysFallThrough,
  NeverFallThroughOrReturn
};

/// CheckFallThrough - Check that we don't fall off the end of a
/// Statement that should return a value.
///
/// \returns AlwaysFallThrough iff we always fall off the end of the statement,
/// MaybeFallThrough iff we might or might not fall off the end,
/// NeverFallThroughOrReturn iff we never fall off the end of the statement or
/// return.  We assume NeverFallThrough iff we never fall off the end of the
/// statement but we may return.  We assume that functions not marked noreturn
/// will return.
static ControlFlowKind CheckFallThrough(AnalysisContext &AC) {
  CFG *cfg = AC.getCFG();
  if (cfg == 0) return UnknownFallThrough;

  // The CFG leaves in dead things, and we don't want the dead code paths to
  // confuse us, so we mark all live things first.
  llvm::BitVector live(cfg->getNumBlockIDs());
  unsigned count = reachable_code::ScanReachableFromBlock(cfg->getEntry(),
                                                          live);

  bool AddEHEdges = AC.getAddEHEdges();
  if (!AddEHEdges && count != cfg->getNumBlockIDs())
    // When there are things remaining dead, and we didn't add EH edges
    // from CallExprs to the catch clauses, we have to go back and
    // mark them as live.
    for (CFG::iterator I = cfg->begin(), E = cfg->end(); I != E; ++I) {
      CFGBlock &b = **I;
      if (!live[b.getBlockID()]) {
        if (b.pred_begin() == b.pred_end()) {
          if (b.getTerminator() && isa<CXXTryStmt>(b.getTerminator()))
            // When not adding EH edges from calls, catch clauses
            // can otherwise seem dead.  Avoid noting them as dead.
            count += reachable_code::ScanReachableFromBlock(b, live);
          continue;
        }
      }
    }

  // Now we know what is live, we check the live precessors of the exit block
  // and look for fall through paths, being careful to ignore normal returns,
  // and exceptional paths.
  bool HasLiveReturn = false;
  bool HasFakeEdge = false;
  bool HasPlainEdge = false;
  bool HasAbnormalEdge = false;

  // Ignore default cases that aren't likely to be reachable because all
  // enums in a switch(X) have explicit case statements.
  CFGBlock::FilterOptions FO;
  FO.IgnoreDefaultsWithCoveredEnums = 1;

  for (CFGBlock::filtered_pred_iterator
	 I = cfg->getExit().filtered_pred_start_end(FO); I.hasMore(); ++I) {
    const CFGBlock& B = **I;
    if (!live[B.getBlockID()])
      continue;

    // Destructors can appear after the 'return' in the CFG.  This is
    // normal.  We need to look pass the destructors for the return
    // statement (if it exists).
    CFGBlock::const_reverse_iterator ri = B.rbegin(), re = B.rend();
    bool hasNoReturnDtor = false;
    
    for ( ; ri != re ; ++ri) {
      CFGElement CE = *ri;

      // FIXME: The right solution is to just sever the edges in the
      // CFG itself.
      if (const CFGImplicitDtor *iDtor = ri->getAs<CFGImplicitDtor>())
        if (iDtor->isNoReturn(AC.getASTContext())) {
          hasNoReturnDtor = true;
          HasFakeEdge = true;
          break;
        }
      
      if (isa<CFGStmt>(CE))
        break;
    }
    
    if (hasNoReturnDtor)
      continue;
    
    // No more CFGElements in the block?
    if (ri == re) {
      if (B.getTerminator() && isa<CXXTryStmt>(B.getTerminator())) {
        HasAbnormalEdge = true;
        continue;
      }
      // A labeled empty statement, or the entry block...
      HasPlainEdge = true;
      continue;
    }

    CFGStmt CS = cast<CFGStmt>(*ri);
    Stmt *S = CS.getStmt();
    if (isa<ReturnStmt>(S)) {
      HasLiveReturn = true;
      continue;
    }
    if (isa<ObjCAtThrowStmt>(S)) {
      HasFakeEdge = true;
      continue;
    }
    if (isa<CXXThrowExpr>(S)) {
      HasFakeEdge = true;
      continue;
    }
    if (const AsmStmt *AS = dyn_cast<AsmStmt>(S)) {
      if (AS->isMSAsm()) {
        HasFakeEdge = true;
        HasLiveReturn = true;
        continue;
      }
    }
    if (isa<CXXTryStmt>(S)) {
      HasAbnormalEdge = true;
      continue;
    }

    bool NoReturnEdge = false;
    if (CallExpr *C = dyn_cast<CallExpr>(S)) {
      if (std::find(B.succ_begin(), B.succ_end(), &cfg->getExit())
            == B.succ_end()) {
        HasAbnormalEdge = true;
        continue;
      }
      Expr *CEE = C->getCallee()->IgnoreParenCasts();
      if (getFunctionExtInfo(CEE->getType()).getNoReturn()) {
        NoReturnEdge = true;
        HasFakeEdge = true;
      } else if (DeclRefExpr *DRE = dyn_cast<DeclRefExpr>(CEE)) {
        ValueDecl *VD = DRE->getDecl();
        if (VD->hasAttr<NoReturnAttr>()) {
          NoReturnEdge = true;
          HasFakeEdge = true;
        }
      }
    }
    // FIXME: Add noreturn message sends.
    if (NoReturnEdge == false)
      HasPlainEdge = true;
  }
  if (!HasPlainEdge) {
    if (HasLiveReturn)
      return NeverFallThrough;
    return NeverFallThroughOrReturn;
  }
  if (HasAbnormalEdge || HasFakeEdge || HasLiveReturn)
    return MaybeFallThrough;
  // This says AlwaysFallThrough for calls to functions that are not marked
  // noreturn, that don't return.  If people would like this warning to be more
  // accurate, such functions should be marked as noreturn.
  return AlwaysFallThrough;
}

namespace {

struct CheckFallThroughDiagnostics {
  unsigned diag_MaybeFallThrough_HasNoReturn;
  unsigned diag_MaybeFallThrough_ReturnsNonVoid;
  unsigned diag_AlwaysFallThrough_HasNoReturn;
  unsigned diag_AlwaysFallThrough_ReturnsNonVoid;
  unsigned diag_NeverFallThroughOrReturn;
  bool funMode;
  SourceLocation FuncLoc;

  static CheckFallThroughDiagnostics MakeForFunction(const Decl *Func) {
    CheckFallThroughDiagnostics D;
    D.FuncLoc = Func->getLocation();
    D.diag_MaybeFallThrough_HasNoReturn =
      diag::warn_falloff_noreturn_function;
    D.diag_MaybeFallThrough_ReturnsNonVoid =
      diag::warn_maybe_falloff_nonvoid_function;
    D.diag_AlwaysFallThrough_HasNoReturn =
      diag::warn_falloff_noreturn_function;
    D.diag_AlwaysFallThrough_ReturnsNonVoid =
      diag::warn_falloff_nonvoid_function;

    // Don't suggest that virtual functions be marked "noreturn", since they
    // might be overridden by non-noreturn functions.
    bool isVirtualMethod = false;
    if (const CXXMethodDecl *Method = dyn_cast<CXXMethodDecl>(Func))
      isVirtualMethod = Method->isVirtual();
    
    if (!isVirtualMethod)
      D.diag_NeverFallThroughOrReturn =
        diag::warn_suggest_noreturn_function;
    else
      D.diag_NeverFallThroughOrReturn = 0;
    
    D.funMode = true;
    return D;
  }

  static CheckFallThroughDiagnostics MakeForBlock() {
    CheckFallThroughDiagnostics D;
    D.diag_MaybeFallThrough_HasNoReturn =
      diag::err_noreturn_block_has_return_expr;
    D.diag_MaybeFallThrough_ReturnsNonVoid =
      diag::err_maybe_falloff_nonvoid_block;
    D.diag_AlwaysFallThrough_HasNoReturn =
      diag::err_noreturn_block_has_return_expr;
    D.diag_AlwaysFallThrough_ReturnsNonVoid =
      diag::err_falloff_nonvoid_block;
    D.diag_NeverFallThroughOrReturn =
      diag::warn_suggest_noreturn_block;
    D.funMode = false;
    return D;
  }

  bool checkDiagnostics(Diagnostic &D, bool ReturnsVoid,
                        bool HasNoReturn) const {
    if (funMode) {
      return (ReturnsVoid ||
              D.getDiagnosticLevel(diag::warn_maybe_falloff_nonvoid_function,
                                   FuncLoc) == Diagnostic::Ignored)
        && (!HasNoReturn ||
            D.getDiagnosticLevel(diag::warn_noreturn_function_has_return_expr,
                                 FuncLoc) == Diagnostic::Ignored)
        && (!ReturnsVoid ||
            D.getDiagnosticLevel(diag::warn_suggest_noreturn_block, FuncLoc)
              == Diagnostic::Ignored);
    }

    // For blocks.
    return  ReturnsVoid && !HasNoReturn
            && (!ReturnsVoid ||
                D.getDiagnosticLevel(diag::warn_suggest_noreturn_block, FuncLoc)
                  == Diagnostic::Ignored);
  }
};

}

/// CheckFallThroughForFunctionDef - Check that we don't fall off the end of a
/// function that should return a value.  Check that we don't fall off the end
/// of a noreturn function.  We assume that functions and blocks not marked
/// noreturn will return.
static void CheckFallThroughForBody(Sema &S, const Decl *D, const Stmt *Body,
                                    const BlockExpr *blkExpr,
                                    const CheckFallThroughDiagnostics& CD,
                                    AnalysisContext &AC) {

  bool ReturnsVoid = false;
  bool HasNoReturn = false;

  if (const FunctionDecl *FD = dyn_cast<FunctionDecl>(D)) {
    ReturnsVoid = FD->getResultType()->isVoidType();
    HasNoReturn = FD->hasAttr<NoReturnAttr>() ||
       FD->getType()->getAs<FunctionType>()->getNoReturnAttr();
  }
  else if (const ObjCMethodDecl *MD = dyn_cast<ObjCMethodDecl>(D)) {
    ReturnsVoid = MD->getResultType()->isVoidType();
    HasNoReturn = MD->hasAttr<NoReturnAttr>();
  }
  else if (isa<BlockDecl>(D)) {
    QualType BlockTy = blkExpr->getType();
    if (const FunctionType *FT =
          BlockTy->getPointeeType()->getAs<FunctionType>()) {
      if (FT->getResultType()->isVoidType())
        ReturnsVoid = true;
      if (FT->getNoReturnAttr())
        HasNoReturn = true;
    }
  }

  Diagnostic &Diags = S.getDiagnostics();

  // Short circuit for compilation speed.
  if (CD.checkDiagnostics(Diags, ReturnsVoid, HasNoReturn))
      return;

  // FIXME: Function try block
  if (const CompoundStmt *Compound = dyn_cast<CompoundStmt>(Body)) {
    switch (CheckFallThrough(AC)) {
      case UnknownFallThrough:
        break;

      case MaybeFallThrough:
        if (HasNoReturn)
          S.Diag(Compound->getRBracLoc(),
                 CD.diag_MaybeFallThrough_HasNoReturn);
        else if (!ReturnsVoid)
          S.Diag(Compound->getRBracLoc(),
                 CD.diag_MaybeFallThrough_ReturnsNonVoid);
        break;
      case AlwaysFallThrough:
        if (HasNoReturn)
          S.Diag(Compound->getRBracLoc(),
                 CD.diag_AlwaysFallThrough_HasNoReturn);
        else if (!ReturnsVoid)
          S.Diag(Compound->getRBracLoc(),
                 CD.diag_AlwaysFallThrough_ReturnsNonVoid);
        break;
      case NeverFallThroughOrReturn:
        if (ReturnsVoid && !HasNoReturn && CD.diag_NeverFallThroughOrReturn)
          S.Diag(Compound->getLBracLoc(),
                 CD.diag_NeverFallThroughOrReturn);
        break;
      case NeverFallThrough:
        break;
    }
  }
}

//===----------------------------------------------------------------------===//
// -Wuninitialized
//===----------------------------------------------------------------------===//

namespace {
struct SLocSort {
  bool operator()(const Expr *a, const Expr *b) {
    SourceLocation aLoc = a->getLocStart();
    SourceLocation bLoc = b->getLocStart();
    return aLoc.getRawEncoding() < bLoc.getRawEncoding();
  }
};

class UninitValsDiagReporter : public UninitVariablesHandler {
  Sema &S;
  typedef llvm::SmallVector<const Expr *, 2> UsesVec;
  typedef llvm::DenseMap<const VarDecl *, UsesVec*> UsesMap;
  UsesMap *uses;
  
public:
  UninitValsDiagReporter(Sema &S) : S(S), uses(0) {}
  ~UninitValsDiagReporter() { 
    flushDiagnostics();
  }
  
  void handleUseOfUninitVariable(const Expr *ex, const VarDecl *vd) {
    if (!uses)
      uses = new UsesMap();
    
    UsesVec *&vec = (*uses)[vd];
    if (!vec)
      vec = new UsesVec();
    
    vec->push_back(ex);
  }
  
  void flushDiagnostics() {
    if (!uses)
      return;
    
    for (UsesMap::iterator i = uses->begin(), e = uses->end(); i != e; ++i) {
      const VarDecl *vd = i->first;
      UsesVec *vec = i->second;

      bool fixitIssued = false;
            
      // Sort the uses by their SourceLocations.  While not strictly
      // guaranteed to produce them in line/column order, this will provide
      // a stable ordering.
      std::sort(vec->begin(), vec->end(), SLocSort());
      
      for (UsesVec::iterator vi = vec->begin(), ve = vec->end(); vi != ve; ++vi)
      {
        if (const DeclRefExpr *dr = dyn_cast<DeclRefExpr>(*vi)) {
          S.Diag(dr->getLocStart(), diag::warn_uninit_var)
            << vd->getDeclName() << dr->getSourceRange();          
        }
        else {
          const BlockExpr *be = cast<BlockExpr>(*vi);
          S.Diag(be->getLocStart(), diag::warn_uninit_var_captured_by_block)
            << vd->getDeclName();
        }
        
        // Report where the variable was declared.
        S.Diag(vd->getLocStart(), diag::note_uninit_var_def)
          << vd->getDeclName();

        // Only report the fixit once.
        if (fixitIssued)
          continue;
      
        fixitIssued = true;

        // Suggest possible initialization (if any).
        const char *initialization = 0;
        QualType vdTy = vd->getType().getCanonicalType();

        if (vdTy->getAs<ObjCObjectPointerType>()) {
          // Check if 'nil' is defined.
          if (S.PP.getMacroInfo(&S.getASTContext().Idents.get("nil")))
            initialization = " = nil";
          else
            initialization = " = 0";
        }
        else if (vdTy->isRealFloatingType())
          initialization = " = 0.0";
        else if (vdTy->isBooleanType() && S.Context.getLangOptions().CPlusPlus)
          initialization = " = false";
        else if (vdTy->isEnumeralType())
          continue;
        else if (vdTy->isScalarType())
          initialization = " = 0";
      
        if (initialization) {
          SourceLocation loc = S.PP.getLocForEndOfToken(vd->getLocEnd());
          S.Diag(loc, diag::note_var_fixit_add_initialization)
            << FixItHint::CreateInsertion(loc, initialization);
        }
      }
      delete vec;
    }
    delete uses;
  }
};
}

//===----------------------------------------------------------------------===//
// AnalysisBasedWarnings - Worker object used by Sema to execute analysis-based
//  warnings on a function, method, or block.
//===----------------------------------------------------------------------===//

clang::sema::AnalysisBasedWarnings::Policy::Policy() {
  enableCheckFallThrough = 1;
  enableCheckUnreachable = 0;
}

clang::sema::AnalysisBasedWarnings::AnalysisBasedWarnings(Sema &s) : S(s) {
  Diagnostic &D = S.getDiagnostics();
  DefaultPolicy.enableCheckUnreachable = (unsigned)
    (D.getDiagnosticLevel(diag::warn_unreachable, SourceLocation()) !=
        Diagnostic::Ignored);
}

static void flushDiagnostics(Sema &S, sema::FunctionScopeInfo *fscope) {
  for (llvm::SmallVectorImpl<sema::PossiblyUnreachableDiag>::iterator
       i = fscope->PossiblyUnreachableDiags.begin(),
       e = fscope->PossiblyUnreachableDiags.end();
       i != e; ++i) {
    const sema::PossiblyUnreachableDiag &D = *i;
    S.Diag(D.Loc, D.PD);
  }
}

void clang::sema::
AnalysisBasedWarnings::IssueWarnings(sema::AnalysisBasedWarnings::Policy P,
                                     sema::FunctionScopeInfo *fscope,
                                     const Decl *D, const BlockExpr *blkExpr) {

  // We avoid doing analysis-based warnings when there are errors for
  // two reasons:
  // (1) The CFGs often can't be constructed (if the body is invalid), so
  //     don't bother trying.
  // (2) The code already has problems; running the analysis just takes more
  //     time.
  Diagnostic &Diags = S.getDiagnostics();

  // Do not do any analysis for declarations in system headers if we are
  // going to just ignore them.
  if (Diags.getSuppressSystemWarnings() &&
      S.SourceMgr.isInSystemHeader(D->getLocation()))
    return;

  // For code in dependent contexts, we'll do this at instantiation time.
  if (cast<DeclContext>(D)->isDependentContext())
    return;

  if (Diags.hasErrorOccurred() || Diags.hasFatalErrorOccurred()) {
    // Flush out any possibly unreachable diagnostics.
    flushDiagnostics(S, fscope);
    return;
  }
  
  const Stmt *Body = D->getBody();
  assert(Body);

  // Don't generate EH edges for CallExprs as we'd like to avoid the n^2
  // explosion for destrutors that can result and the compile time hit.
  AnalysisContext AC(D, 0, /*useUnoptimizedCFG=*/false, /*addehedges=*/false,
                     /*addImplicitDtors=*/true, /*addInitializers=*/true);

  // Emit delayed diagnostics.
  if (!fscope->PossiblyUnreachableDiags.empty()) {
    bool analyzed = false;
    if (CFGReachabilityAnalysis *cra = AC.getCFGReachablityAnalysis())
      if (CFGStmtMap *csm = AC.getCFGStmtMap()) {
        analyzed = true;
        for (llvm::SmallVectorImpl<sema::PossiblyUnreachableDiag>::iterator
             i = fscope->PossiblyUnreachableDiags.begin(),
             e = fscope->PossiblyUnreachableDiags.end();
             i != e; ++i) {
          const sema::PossiblyUnreachableDiag &D = *i;
          if (const CFGBlock *blk = csm->getBlock(D.stmt)) {
            // Can this block be reached from the entrance?
            if (cra->isReachable(&AC.getCFG()->getEntry(), blk))
              S.Diag(D.Loc, D.PD);
          }
          else {
            // Emit the warning anyway if we cannot map to a basic block.
            S.Diag(D.Loc, D.PD);
          }
        }
      }

    if (!analyzed)
      flushDiagnostics(S, fscope);
  }
  
  
  // Warning: check missing 'return'
  if (P.enableCheckFallThrough) {
    const CheckFallThroughDiagnostics &CD =
      (isa<BlockDecl>(D) ? CheckFallThroughDiagnostics::MakeForBlock()
                         : CheckFallThroughDiagnostics::MakeForFunction(D));
    CheckFallThroughForBody(S, D, Body, blkExpr, CD, AC);
  }

  // Warning: check for unreachable code
  if (P.enableCheckUnreachable)
    CheckUnreachable(S, AC);
  
  if (Diags.getDiagnosticLevel(diag::warn_uninit_var, D->getLocStart())
      != Diagnostic::Ignored) {
    ASTContext &ctx = D->getASTContext();
    llvm::OwningPtr<CFG> tmpCFG;
    bool useAlternateCFG = false;
    if (ctx.getLangOptions().CPlusPlus) {
      // Temporary workaround: implicit dtors in the CFG can confuse
      // the path-sensitivity in the uninitialized values analysis.
      // For now create (if necessary) a separate CFG without implicit dtors.
      // FIXME: We should not need to do this, as it results in multiple
      // CFGs getting constructed.
      CFG::BuildOptions B;
      B.AddEHEdges = false;
      B.AddImplicitDtors = false;
      B.AddInitializers = true;
      tmpCFG.reset(CFG::buildCFG(D, AC.getBody(), &ctx, B));
      useAlternateCFG = true;
    }
    CFG *cfg = useAlternateCFG ? tmpCFG.get() : AC.getCFG();
    if (cfg) {
      UninitValsDiagReporter reporter(S);
      runUninitializedVariablesAnalysis(*cast<DeclContext>(D), *cfg, AC,
                                        reporter);
    }
  }
}
