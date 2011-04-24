//===--- CheckerManager.h - Static Analyzer Checker Manager -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Defines the Static Analyzer Checker Manager.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_SA_CORE_CHECKERMANAGER_H
#define LLVM_CLANG_SA_CORE_CHECKERMANAGER_H

#include "clang/Basic/LangOptions.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/FoldingSet.h"
#include <vector>

namespace clang {
  class Decl;
  class Stmt;
  class CallExpr;

namespace ento {
  class ExprEngine;
  class AnalysisManager;
  class BugReporter;
  class CheckerContext;
  class ObjCMessage;
  class SVal;
  class ExplodedNode;
  class ExplodedNodeSet;
  class ExplodedGraph;
  class GRState;
  class EndOfFunctionNodeBuilder;
  class BranchNodeBuilder;
  class MemRegion;
  class SymbolReaper;

class GraphExpander {
public:
  virtual ~GraphExpander();
  virtual void expandGraph(ExplodedNodeSet &Dst, ExplodedNode *Pred) = 0;
};

struct VoidCheckerFnParm {};
template <typename P1=VoidCheckerFnParm, typename P2=VoidCheckerFnParm,
          typename P3=VoidCheckerFnParm, typename P4=VoidCheckerFnParm>
class CheckerFn {
  typedef void (*Func)(void *, P1, P2, P3, P4);
  Func Fn;
public:
  void *Checker;
  CheckerFn(void *checker, Func fn) : Fn(fn), Checker(checker) { }
  void operator()(P1 p1, P2 p2, P3 p3, P4 p4) { Fn(Checker, p1, p2, p3, p4); } 
};

template <typename P1, typename P2, typename P3>
class CheckerFn<P1, P2, P3, VoidCheckerFnParm> {
  typedef void (*Func)(void *, P1, P2, P3);
  Func Fn;
public:
  void *Checker;
  CheckerFn(void *checker, Func fn) : Fn(fn), Checker(checker) { }
  void operator()(P1 p1, P2 p2, P3 p3) { Fn(Checker, p1, p2, p3); } 
};

template <typename P1, typename P2>
class CheckerFn<P1, P2, VoidCheckerFnParm, VoidCheckerFnParm> {
  typedef void (*Func)(void *, P1, P2);
  Func Fn;
public:
  void *Checker;
  CheckerFn(void *checker, Func fn) : Fn(fn), Checker(checker) { }
  void operator()(P1 p1, P2 p2) { Fn(Checker, p1, p2); } 
};

template <>
class CheckerFn<VoidCheckerFnParm, VoidCheckerFnParm, VoidCheckerFnParm,
                VoidCheckerFnParm> {
  typedef void (*Func)(void *);
  Func Fn;
public:
  void *Checker;
  CheckerFn(void *checker, Func fn) : Fn(fn), Checker(checker) { }
  void operator()() { Fn(Checker); } 
};

class CheckerManager {
  const LangOptions LangOpts;

public:
  CheckerManager(const LangOptions &langOpts) : LangOpts(langOpts) { }
  ~CheckerManager();

  bool hasPathSensitiveCheckers() const;

  void finishedCheckerRegistration();

  const LangOptions &getLangOptions() const { return LangOpts; }

  typedef void *CheckerRef;
  typedef void *CheckerTag;
  typedef CheckerFn<> CheckerDtor;

//===----------------------------------------------------------------------===//
// registerChecker
//===----------------------------------------------------------------------===//

  /// \brief Used to register checkers.
  ///
  /// \returns a pointer to the checker object.
  template <typename CHECKER>
  CHECKER *registerChecker() {
    CheckerTag tag = getTag<CHECKER>();
    CheckerRef &ref = CheckerTags[tag];
    if (ref)
      return static_cast<CHECKER *>(ref); // already registered.

    CHECKER *checker = new CHECKER();
    CheckerDtors.push_back(CheckerDtor(checker, destruct<CHECKER>));
    CHECKER::_register(checker, *this);
    ref = checker;
    return checker;
  }

//===----------------------------------------------------------------------===//
// Functions for running checkers for AST traversing..
//===----------------------------------------------------------------------===//

  /// \brief Run checkers handling Decls.
  void runCheckersOnASTDecl(const Decl *D, AnalysisManager& mgr,
                            BugReporter &BR);

  /// \brief Run checkers handling Decls containing a Stmt body.
  void runCheckersOnASTBody(const Decl *D, AnalysisManager& mgr,
                            BugReporter &BR);

//===----------------------------------------------------------------------===//
// Functions for running checkers for path-sensitive checking.
//===----------------------------------------------------------------------===//

  /// \brief Run checkers for pre-visiting Stmts.
  void runCheckersForPreStmt(ExplodedNodeSet &Dst,
                             const ExplodedNodeSet &Src,
                             const Stmt *S,
                             ExprEngine &Eng) {
    runCheckersForStmt(/*isPreVisit=*/true, Dst, Src, S, Eng);
  }

  /// \brief Run checkers for post-visiting Stmts.
  void runCheckersForPostStmt(ExplodedNodeSet &Dst,
                              const ExplodedNodeSet &Src,
                              const Stmt *S,
                              ExprEngine &Eng) {
    runCheckersForStmt(/*isPreVisit=*/false, Dst, Src, S, Eng);
  }

  /// \brief Run checkers for visiting Stmts.
  void runCheckersForStmt(bool isPreVisit,
                          ExplodedNodeSet &Dst, const ExplodedNodeSet &Src,
                          const Stmt *S, ExprEngine &Eng);

  /// \brief Run checkers for pre-visiting obj-c messages.
  void runCheckersForPreObjCMessage(ExplodedNodeSet &Dst,
                                    const ExplodedNodeSet &Src,
                                    const ObjCMessage &msg,
                                    ExprEngine &Eng) {
    runCheckersForObjCMessage(/*isPreVisit=*/true, Dst, Src, msg, Eng);
  }

  /// \brief Run checkers for post-visiting obj-c messages.
  void runCheckersForPostObjCMessage(ExplodedNodeSet &Dst,
                                     const ExplodedNodeSet &Src,
                                     const ObjCMessage &msg,
                                     ExprEngine &Eng) {
    runCheckersForObjCMessage(/*isPreVisit=*/false, Dst, Src, msg, Eng);
  }

  /// \brief Run checkers for visiting obj-c messages.
  void runCheckersForObjCMessage(bool isPreVisit,
                                 ExplodedNodeSet &Dst,
                                 const ExplodedNodeSet &Src,
                                 const ObjCMessage &msg, ExprEngine &Eng);

  /// \brief Run checkers for load/store of a location.
  void runCheckersForLocation(ExplodedNodeSet &Dst,
                              const ExplodedNodeSet &Src,
                              SVal location, bool isLoad,
                              const Stmt *S,
                              ExprEngine &Eng);

  /// \brief Run checkers for binding of a value to a location.
  void runCheckersForBind(ExplodedNodeSet &Dst,
                          const ExplodedNodeSet &Src,
                          SVal location, SVal val,
                          const Stmt *S, ExprEngine &Eng);

  /// \brief Run checkers for end of analysis.
  void runCheckersForEndAnalysis(ExplodedGraph &G, BugReporter &BR,
                                 ExprEngine &Eng);

  /// \brief Run checkers for end of path.
  void runCheckersForEndPath(EndOfFunctionNodeBuilder &B, ExprEngine &Eng);

  /// \brief Run checkers for branch condition.
  void runCheckersForBranchCondition(const Stmt *condition,
                                     BranchNodeBuilder &B, ExprEngine &Eng);

  /// \brief Run checkers for live symbols.
  void runCheckersForLiveSymbols(const GRState *state,
                                 SymbolReaper &SymReaper);

  /// \brief Run checkers for dead symbols.
  void runCheckersForDeadSymbols(ExplodedNodeSet &Dst,
                                 const ExplodedNodeSet &Src,
                                 SymbolReaper &SymReaper, const Stmt *S,
                                 ExprEngine &Eng);

  /// \brief True if at least one checker wants to check region changes.
  bool wantsRegionChangeUpdate(const GRState *state);

  /// \brief Run checkers for region changes.
  const GRState *runCheckersForRegionChanges(const GRState *state,
                                             const MemRegion * const *Begin,
                                             const MemRegion * const *End);

  /// \brief Run checkers for handling assumptions on symbolic values.
  const GRState *runCheckersForEvalAssume(const GRState *state,
                                          SVal Cond, bool Assumption);

  /// \brief Run checkers for evaluating a call.
  void runCheckersForEvalCall(ExplodedNodeSet &Dst,
                              const ExplodedNodeSet &Src,
                              const CallExpr *CE, ExprEngine &Eng,
                              GraphExpander *defaultEval = 0);

//===----------------------------------------------------------------------===//
// Internal registration functions for AST traversing.
//===----------------------------------------------------------------------===//

  // Functions used by the registration mechanism, checkers should not touch
  // these directly.

  typedef CheckerFn<const Decl *, AnalysisManager&, BugReporter &>
      CheckDeclFunc;

  typedef bool (*HandlesDeclFunc)(const Decl *D);
  void _registerForDecl(CheckDeclFunc checkfn, HandlesDeclFunc isForDeclFn);

  void _registerForBody(CheckDeclFunc checkfn);

//===----------------------------------------------------------------------===//
// Internal registration functions for path-sensitive checking.
//===----------------------------------------------------------------------===//

  typedef CheckerFn<const Stmt *, CheckerContext &> CheckStmtFunc;
  typedef CheckerFn<const ObjCMessage &, CheckerContext &> CheckObjCMessageFunc;
  typedef CheckerFn<const SVal &/*location*/, bool/*isLoad*/, CheckerContext &>
      CheckLocationFunc;
  typedef CheckerFn<const SVal &/*location*/, const SVal &/*val*/,
                    CheckerContext &> CheckBindFunc;
  typedef CheckerFn<ExplodedGraph &, BugReporter &, ExprEngine &>
      CheckEndAnalysisFunc;
  typedef CheckerFn<EndOfFunctionNodeBuilder &, ExprEngine &> CheckEndPathFunc;
  typedef CheckerFn<const Stmt *, BranchNodeBuilder &, ExprEngine &>
      CheckBranchConditionFunc;
  typedef CheckerFn<SymbolReaper &, CheckerContext &> CheckDeadSymbolsFunc;
  typedef CheckerFn<const GRState *, SymbolReaper &> CheckLiveSymbolsFunc;

  typedef bool (*HandlesStmtFunc)(const Stmt *D);
  void _registerForPreStmt(CheckStmtFunc checkfn,
                           HandlesStmtFunc isForStmtFn);
  void _registerForPostStmt(CheckStmtFunc checkfn,
                            HandlesStmtFunc isForStmtFn);

  void _registerForPreObjCMessage(CheckObjCMessageFunc checkfn);
  void _registerForPostObjCMessage(CheckObjCMessageFunc checkfn);

  void _registerForLocation(CheckLocationFunc checkfn);

  void _registerForBind(CheckBindFunc checkfn);

  void _registerForEndAnalysis(CheckEndAnalysisFunc checkfn);

  void _registerForEndPath(CheckEndPathFunc checkfn);

  void _registerForBranchCondition(CheckBranchConditionFunc checkfn);

  void _registerForLiveSymbols(CheckLiveSymbolsFunc checkfn);

  void _registerForDeadSymbols(CheckDeadSymbolsFunc checkfn);

  class CheckRegionChangesFunc {
    typedef const GRState * (*Func)(void *, const GRState *,
                                    const MemRegion * const *,
                                    const MemRegion * const *);
    Func Fn;
  public:
    void *Checker;
    CheckRegionChangesFunc(void *checker, Func fn) : Fn(fn), Checker(checker) {}
    const GRState *operator()(const GRState *state,
                              const MemRegion * const *begin,
                              const MemRegion * const *end) {
      return Fn(Checker, state, begin, end);
    }
  };

  class WantsRegionChangeUpdateFunc {
    typedef bool (*Func)(void *, const GRState *);
    Func Fn;
  public:
    void *Checker;
    WantsRegionChangeUpdateFunc(void *checker, Func fn)
      : Fn(fn), Checker(checker) { }
    bool operator()(const GRState *state) {
      return Fn(Checker, state);
    } 
  };

  void _registerForRegionChanges(CheckRegionChangesFunc checkfn,
                                 WantsRegionChangeUpdateFunc wantUpdateFn);

  class EvalAssumeFunc {
    typedef const GRState * (*Func)(void *, const GRState *,
                                    const SVal &/*cond*/, bool /*assumption*/);
    Func Fn;
  public:
    void *Checker;
    EvalAssumeFunc(void *checker, Func fn) : Fn(fn), Checker(checker) {}
    const GRState *operator()(const GRState *state,
                              const SVal &cond, bool assumption) {
      return Fn(Checker, state, cond, assumption);
    }
  };

  void _registerForEvalAssume(EvalAssumeFunc checkfn);

  class EvalCallFunc {
    typedef bool (*Func)(void *, const CallExpr *, CheckerContext &);
    Func Fn;
  public:
    void *Checker;
    EvalCallFunc(void *checker, Func fn) : Fn(fn), Checker(checker) { }
    bool operator()(const CallExpr *CE, CheckerContext &C) {
      return Fn(Checker, CE, C);
    } 
  };

  void _registerForEvalCall(EvalCallFunc checkfn);

//===----------------------------------------------------------------------===//
// Internal registration functions for events.
//===----------------------------------------------------------------------===//

  typedef void *EventTag;

  class CheckEventFunc {
    typedef void (*Func)(void *, const void *);
    Func Fn;
  public:
    void *Checker;
    CheckEventFunc(void *checker, Func fn)
      : Fn(fn), Checker(checker) { }
    void operator()(const void *event) const {
      return Fn(Checker, event);
    } 
  };

  template <typename EVENT>
  void _registerListenerForEvent(CheckEventFunc checkfn) {
    EventInfo &info = Events[getTag<EVENT>()];
    info.Checkers.push_back(checkfn);    
  }

  template <typename EVENT>
  void _registerDispatcherForEvent() {
    EventInfo &info = Events[getTag<EVENT>()];
    info.HasDispatcher = true;
  }

  template <typename EVENT>
  void _dispatchEvent(const EVENT &event) const {
    EventsTy::const_iterator I = Events.find(getTag<EVENT>());
    if (I == Events.end())
      return;
    const EventInfo &info = I->second;
    for (unsigned i = 0, e = info.Checkers.size(); i != e; ++i)
      info.Checkers[i](&event);
  }

//===----------------------------------------------------------------------===//
// Implementation details.
//===----------------------------------------------------------------------===//

private:
  template <typename CHECKER>
  static void destruct(void *obj) { delete static_cast<CHECKER *>(obj); }

  template <typename T>
  static void *getTag() { static int tag; return &tag; }

  llvm::DenseMap<CheckerTag, CheckerRef> CheckerTags;

  std::vector<CheckerDtor> CheckerDtors;

  struct DeclCheckerInfo {
    CheckDeclFunc CheckFn;
    HandlesDeclFunc IsForDeclFn;
  };
  std::vector<DeclCheckerInfo> DeclCheckers;

  std::vector<CheckDeclFunc> BodyCheckers;

  typedef llvm::SmallVector<CheckDeclFunc, 4> CachedDeclCheckers;
  typedef llvm::DenseMap<unsigned, CachedDeclCheckers> CachedDeclCheckersMapTy;
  CachedDeclCheckersMapTy CachedDeclCheckersMap;

  struct StmtCheckerInfo {
    CheckStmtFunc CheckFn;
    HandlesStmtFunc IsForStmtFn;
    bool IsPreVisit;
  };
  std::vector<StmtCheckerInfo> StmtCheckers;

  struct CachedStmtCheckersKey {
    unsigned StmtKind;
    bool IsPreVisit;

    CachedStmtCheckersKey() : StmtKind(0), IsPreVisit(0) { }
    CachedStmtCheckersKey(unsigned stmtKind, bool isPreVisit)
      : StmtKind(stmtKind), IsPreVisit(isPreVisit) { }

    static CachedStmtCheckersKey getSentinel() {
      return CachedStmtCheckersKey(~0U, 0);
    }
    unsigned getHashValue() const {
      llvm::FoldingSetNodeID ID;
      ID.AddInteger(StmtKind);
      ID.AddBoolean(IsPreVisit);
      return ID.ComputeHash();
    }
    bool operator==(const CachedStmtCheckersKey &RHS) const {
      return StmtKind == RHS.StmtKind && IsPreVisit == RHS.IsPreVisit;
    }
  };
  friend struct llvm::DenseMapInfo<CachedStmtCheckersKey>;

  typedef llvm::SmallVector<CheckStmtFunc, 4> CachedStmtCheckers;
  typedef llvm::DenseMap<CachedStmtCheckersKey, CachedStmtCheckers>
      CachedStmtCheckersMapTy;
  CachedStmtCheckersMapTy CachedStmtCheckersMap;

  CachedStmtCheckers *getCachedStmtCheckersFor(const Stmt *S, bool isPreVisit);

  std::vector<CheckObjCMessageFunc> PreObjCMessageCheckers;
  std::vector<CheckObjCMessageFunc> PostObjCMessageCheckers;

  std::vector<CheckLocationFunc> LocationCheckers;

  std::vector<CheckBindFunc> BindCheckers;

  std::vector<CheckEndAnalysisFunc> EndAnalysisCheckers;

  std::vector<CheckEndPathFunc> EndPathCheckers;

  std::vector<CheckBranchConditionFunc> BranchConditionCheckers;

  std::vector<CheckLiveSymbolsFunc> LiveSymbolsCheckers;

  std::vector<CheckDeadSymbolsFunc> DeadSymbolsCheckers;

  struct RegionChangesCheckerInfo {
    CheckRegionChangesFunc CheckFn;
    WantsRegionChangeUpdateFunc WantUpdateFn;
  };
  std::vector<RegionChangesCheckerInfo> RegionChangesCheckers;

  std::vector<EvalAssumeFunc> EvalAssumeCheckers;

  std::vector<EvalCallFunc> EvalCallCheckers;

  struct EventInfo {
    llvm::SmallVector<CheckEventFunc, 4> Checkers;
    bool HasDispatcher;
    EventInfo() : HasDispatcher(false) { }
  };
  
  typedef llvm::DenseMap<EventTag, EventInfo> EventsTy;
  EventsTy Events;
};

} // end ento namespace

} // end clang namespace

namespace llvm {
  /// Define DenseMapInfo so that CachedStmtCheckersKey can be used as key
  /// in DenseMap and DenseSets.
  template <>
  struct DenseMapInfo<clang::ento::CheckerManager::CachedStmtCheckersKey> {
    static inline clang::ento::CheckerManager::CachedStmtCheckersKey
        getEmptyKey() {
      return clang::ento::CheckerManager::CachedStmtCheckersKey();
    }
    static inline clang::ento::CheckerManager::CachedStmtCheckersKey
        getTombstoneKey() {
      return clang::ento::CheckerManager::CachedStmtCheckersKey::getSentinel();
    }

    static unsigned
        getHashValue(clang::ento::CheckerManager::CachedStmtCheckersKey S) {
      return S.getHashValue();
    }

    static bool isEqual(clang::ento::CheckerManager::CachedStmtCheckersKey LHS,
                       clang::ento::CheckerManager::CachedStmtCheckersKey RHS) {
      return LHS == RHS;
    }
  };
} // end namespace llvm

#endif
