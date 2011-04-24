//===--- ClangSACheckerProvider.cpp - Clang SA Checkers Provider ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Defines the CheckerProvider for the checkers defined in
// libclangStaticAnalyzerCheckers.
//
//===----------------------------------------------------------------------===//

#include "ClangSACheckerProvider.h"
#include "ClangSACheckers.h"
#include "clang/StaticAnalyzer/Core/CheckerManager.h"
#include "clang/StaticAnalyzer/Core/CheckerProvider.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/DenseSet.h"
#include "map"

using namespace clang;
using namespace ento;

namespace {

/// \brief Provider for all the checkers in libclangStaticAnalyzerCheckers.
class ClangSACheckerProvider : public CheckerProvider {
public:
  virtual void registerCheckers(CheckerManager &checkerMgr,
                              CheckerOptInfo *checkOpts, unsigned numCheckOpts);
  virtual void printHelp(llvm::raw_ostream &OS);
};

}

CheckerProvider *ento::createClangSACheckerProvider() {
  return new ClangSACheckerProvider();
}

namespace {

struct StaticCheckerInfoRec {
  const char *FullName;
  void (*RegFunc)(CheckerManager &mgr);
  const char *HelpText;
  bool Hidden;
};

} // end anonymous namespace.

static const StaticCheckerInfoRec StaticCheckerInfo[] = {
#define GET_CHECKERS
#define CHECKER(FULLNAME,CLASS,DESCFILE,HELPTEXT,HIDDEN)    \
  { FULLNAME, register##CLASS, HELPTEXT, HIDDEN },
#include "Checkers.inc"
  { 0, 0, 0, 0}
#undef CHECKER
#undef GET_CHECKERS
};

static const unsigned NumCheckers =   sizeof(StaticCheckerInfo)
                                    / sizeof(StaticCheckerInfoRec) - 1;

namespace {

struct CheckNameOption {
  const char  *Name;
  const short *Members;
  const short *SubGroups;
  bool Hidden;
};

} // end anonymous namespace.

#define GET_MEMBER_ARRAYS
#include "Checkers.inc"
#undef GET_MEMBER_ARRAYS

// The table of check name options, sorted by name for fast binary lookup.
static const CheckNameOption CheckNameTable[] = {
#define GET_CHECKNAME_TABLE
#include "Checkers.inc"
#undef GET_CHECKNAME_TABLE
};
static const size_t
        CheckNameTableSize = sizeof(CheckNameTable) / sizeof(CheckNameTable[0]);

static bool CheckNameOptionCompare(const CheckNameOption &LHS,
                                   const CheckNameOption &RHS) {
  return strcmp(LHS.Name, RHS.Name) < 0;
}

static void collectCheckers(const CheckNameOption *checkName,
                            bool enable,
                         llvm::DenseSet<const StaticCheckerInfoRec *> &checkers,
                            bool collectHidden) {
  if (checkName->Hidden && !collectHidden)
    return;

  if (const short *member = checkName->Members) {
    if (enable) {
      if (collectHidden || !StaticCheckerInfo[*member].Hidden)
        checkers.insert(&StaticCheckerInfo[*member]);
    } else {
      for (; *member != -1; ++member)
        checkers.erase(&StaticCheckerInfo[*member]);
    }
  }

  // Enable/disable all subgroups along with this one.
  if (const short *subGroups = checkName->SubGroups) {
    for (; *subGroups != -1; ++subGroups) {
      const CheckNameOption *sub = &CheckNameTable[*subGroups];
      collectCheckers(sub, enable, checkers, collectHidden && !sub->Hidden);
    }
  }
}

static void collectCheckers(CheckerOptInfo &opt,
                       llvm::DenseSet<const StaticCheckerInfoRec *> &checkers) {
  const char *optName = opt.getName();
  CheckNameOption key = { optName, 0, 0, false };
  const CheckNameOption *found =
  std::lower_bound(CheckNameTable, CheckNameTable + CheckNameTableSize, key,
                   CheckNameOptionCompare);
  if (found == CheckNameTable + CheckNameTableSize ||
      strcmp(found->Name, optName) != 0)
    return;  // Check name not found.

  opt.claim();
  collectCheckers(found, opt.isEnabled(), checkers, /*collectHidden=*/true);
}

void ClangSACheckerProvider::registerCheckers(CheckerManager &checkerMgr,
                             CheckerOptInfo *checkOpts, unsigned numCheckOpts) {
  llvm::DenseSet<const StaticCheckerInfoRec *> enabledCheckers;
  for (unsigned i = 0; i != numCheckOpts; ++i)
    collectCheckers(checkOpts[i], enabledCheckers);
  for (llvm::DenseSet<const StaticCheckerInfoRec *>::iterator
         I = enabledCheckers.begin(), E = enabledCheckers.end(); I != E; ++I) {
    (*I)->RegFunc(checkerMgr);
  }
}

typedef std::map<std::string, const StaticCheckerInfoRec *> SortedCheckers;

static void printCheckerOption(llvm::raw_ostream &OS,SortedCheckers &checkers) {
  // Find the maximum option length.
  unsigned OptionFieldWidth = 0;
  for (SortedCheckers::iterator
         I = checkers.begin(), E = checkers.end(); I != E; ++I) {
    // Limit the amount of padding we are willing to give up for alignment.
    unsigned Length = strlen(I->second->FullName);
    if (Length <= 30)
      OptionFieldWidth = std::max(OptionFieldWidth, Length);
  }

  const unsigned InitialPad = 2;
  for (SortedCheckers::iterator
         I = checkers.begin(), E = checkers.end(); I != E; ++I) {
    const std::string &Option = I->first;
    int Pad = OptionFieldWidth - int(Option.size());
    OS.indent(InitialPad) << Option;

    // Break on long option names.
    if (Pad < 0) {
      OS << "\n";
      Pad = OptionFieldWidth + InitialPad;
    }
    OS.indent(Pad + 1) << I->second->HelpText << '\n';
  }
}

void ClangSACheckerProvider::printHelp(llvm::raw_ostream &OS) {
  // Sort checkers according to their full name.
  SortedCheckers checkers;
  for (unsigned i = 0; i != NumCheckers; ++i)
    checkers[StaticCheckerInfo[i].FullName] = &StaticCheckerInfo[i];

  printCheckerOption(OS, checkers);
}
