/*
   Copyright (C) 2005-2009 Clozure Associates
   This file is part of Clozure CL.  

   Clozure CL is licensed under the terms of the Lisp Lesser GNU Public
   License , known as the LLGPL and distributed with Clozure CL as the
   file "LICENSE".  The LLGPL consists of a preamble and the LGPL,
   which is distributed with Clozure CL as the file "LGPL".  Where these
   conflict, the preamble takes precedence.  

   Clozure CL is referenced in the preamble as the "LIBRARY."

   The LLGPL is also available online at
   http://opensource.franz.com/preamble.html
*/

#include "lispdcmd.h"
#include <stdio.h>
#include <signal.h>



void
print_lisp_frame(lisp_frame *frame)
{
  LispObj pc = frame->tra, fun=0;
  int delta = 0;

  if (pc == lisp_global(RET1VALN)) {
    pc = frame->xtra;
  }
#ifdef X8632
  if (fulltag_of(pc) == fulltag_tra) {
    if (*((unsigned char *)pc) == RECOVER_FN_OPCODE) {
      natural n = *((natural *)(pc + 1));
      fun = (LispObj)n;
    }
    if (fun && header_subtag(header_of(fun)) == subtag_function) {
      delta = pc - fun;
      Dprintf("(#x%08X) #x%08X : %s + %d", frame, pc, print_lisp_object(fun), delta);
      return;
    }
  }
  if (pc == 0) {
    fun = ((xcf *)frame)->nominal_function;
    Dprintf("(#x%08X) #x%08X : %s + ??", frame, pc, print_lisp_object(fun));
    return;
  }
#else
  if (tag_of(pc) == tag_tra) {
    if ((*((unsigned short *)pc) == RECOVER_FN_FROM_RIP_WORD0) &&
        (*((unsigned char *)(pc+2)) == RECOVER_FN_FROM_RIP_BYTE2)) {
      int sdisp = (*(int *) (pc+3));
      fun = RECOVER_FN_FROM_RIP_LENGTH+pc+sdisp;
    }
    if (fulltag_of(fun) == fulltag_function) {
      delta = pc - fun;
      Dprintf("(#x%016lX) #x%016lX : %s + %d", frame, pc, print_lisp_object(fun), delta);
      return;
    }
  }
  if (pc == 0) {
    fun = ((xcf *)frame)->nominal_function;
    Dprintf("(#x%016lX) #x%016lX : %s + ??", frame, pc, print_lisp_object(fun));
    return;
  }
#endif
}

Boolean
lisp_frame_p(lisp_frame *f)
{
  LispObj ra;

  if (f) {
    ra = f->tra;
    if (ra == lisp_global(RET1VALN)) {
      ra = f->xtra;
    }

#ifdef X8632
    if (fulltag_of(ra) == fulltag_tra) {
#else
    if (tag_of(ra) == tag_tra) {
#endif
      return true;
    } else if ((ra == lisp_global(LEXPR_RETURN)) ||
	       (ra == lisp_global(LEXPR_RETURN1V))) {
      return true;
    } else if (ra == 0) {
      return true;
    }
  }
  return false;
}

void
walk_stack_frames(lisp_frame *start, lisp_frame *end) 
{
  lisp_frame *next;
  Dprintf("\n");
  while (start < end) {

    if (lisp_frame_p(start)) {
      print_lisp_frame(start);
    } else {
      if (start->backlink) {
        fprintf(dbgout, "Bogus frame %lx\n", start);
      }
      return;
    }
    
    next = start->backlink;
    if (next == 0) {
      next = end;
    }
    if (next < start) {
      fprintf(dbgout, "Bad frame! (%x < %x)\n", next, start);
      break;
    }
    start = next;
  }
}

char *
interrupt_level_description(TCR *tcr)
{
  signed_natural level = (signed_natural) TCR_INTERRUPT_LEVEL(tcr);
  if (level < 0) {
    if (tcr->interrupt_pending) {
      return "disabled(pending)";
    } else {
      return "disabled";
    }
  } else {
    return "enabled";
  }
}

void
plbt_sp(LispObj current_fp)
{
  area *vs_area, *cs_area;
  TCR *tcr = (TCR *)get_tcr(true);
  char *ilevel = interrupt_level_description(tcr);

  vs_area = tcr->vs_area;
  cs_area = TCR_AUX(tcr)->cs_area;
  if ((((LispObj) ptr_to_lispobj(vs_area->low)) > current_fp) ||
      (((LispObj) ptr_to_lispobj(vs_area->high)) < current_fp)) {
    current_fp = (LispObj) (tcr->save_fp);
  }
  if ((((LispObj) ptr_to_lispobj(vs_area->low)) > current_fp) ||
      (((LispObj) ptr_to_lispobj(vs_area->high)) < current_fp)) {
    Dprintf("\nFrame pointer [#x" LISP "] in unknown area.", current_fp);
  } else {
    fprintf(dbgout, "current thread: tcr = 0x" LISP ", native thread ID = 0x" LISP ", interrupts %s\n", tcr, TCR_AUX(tcr)->native_thread_id, ilevel);

#ifndef WINDOWS
    if (lisp_global(BATCH_FLAG)) {
      /*
       * In batch mode, we will be exiting.  Reset some signal actions
       * to the default to avoid a loop of "Unhandled exception 11" or
       * whatever if we try to print some call stack that is totally
       * screwed up.  (Instead, we'll just die horribly and get it
       * over with.)
       */
      signal(SIGBUS, SIG_DFL);
      signal(SIGSEGV, SIG_DFL);
    }
#endif

    walk_stack_frames((lisp_frame *) ptr_from_lispobj(current_fp), (lisp_frame *) (vs_area->high));
    /*      walk_other_areas();*/
  }
}


void
plbt(ExceptionInformation *xp)
{
  plbt_sp(xpGPR(xp, Ifp));
}
