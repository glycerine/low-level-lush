#
#   Copyright (C) 2005-2006 Clozure Associates
#   This file is part of Clozure CL.  
#
#   Clozure CL is licensed under the terms of the Lisp Lesser GNU Public
#   License , known as the LLGPL and distributed with Clozure CL as the
#   file "LICENSE".  The LLGPL consists of a preamble and the LGPL,
#   which is distributed with Clozure CL as the file "LGPL".  Where these
#   conflict, the preamble takes precedence.  
#
#   Clozure CL is referenced in the preamble as the "LIBRARY."
#
#   The LLGPL is also available online at
#   http://opensource.franz.com/preamble.html

SVN_REVISION=$(shell svnversion || echo "unknown")

VPATH = ..
RM = /bin/rm
AS = as
M4 = m4
ASFLAGS = --32
M4FLAGS = -DFREEBSD -DX86 -DX8632 -DHAVE_TLS
CDEFINES = -DFREEBSD -D_REENTRANT -DX86 -DX8632 -D_GNU_SOURCE -DHAVE_TLS -DSVN_REVISION=$(SVN_REVISION)
CDEBUG = -g
COPT = #-O2
# Once in a while, -Wformat says something useful.  The odds are against that,
# however.
WFORMAT = -Wno-format
PLATFORM_H = platform-freebsdx8632.h



SPOBJ = pad.o x86-spjump32.o x86-spentry32.o x86-subprims32.o
ASMOBJ = x86-asmutils32.o imports.o

COBJ  = pmcl-kernel.o gc-common.o  x86-gc.o bits.o  x86-exceptions.o \
	image.o thread_manager.o lisp-debug.o memory.o unix-calls.o

DEBUGOBJ = lispdcmd.o plprint.o plsym.o xlbt.o x86_print.o
KERNELOBJ= $(COBJ) x86-asmutils32.o  imports.o

PLATFORM_OBJ = e_exp.o e_expf.o
PLATFORM_HEADERS = fdlibm.h

SPINC =	lisp.s m4macros.m4 x86-constants.s x86-macros.s errors.s x86-uuo.s \
	x86-constants32.s

CHEADERS = area.h bits.h x86-constants.h lisp-errors.h gc.h lisp.h \
	lisp-exceptions.h lisp_globals.h macros.h memprotect.h image.h \
	threads.h x86-constants32.h x86-exceptions.h $(PLATFORM_H)

.if $(MACHINE) == "amd64"
CROSS = -B/usr/lib32
.endif

KSPOBJ = $(SPOBJ)
all:	../../fx86cl


OSLIBS = -lm -lthr $(CROSS)

.s.o:
	$(M4) $(M4FLAGS) -I../ $< | $(AS)  $(ASFLAGS) -o $@
.c.o:
	$(CC) -include ../$(PLATFORM_H) -c $< $(CDEFINES) $(CDEBUG) $(COPT) $(WFORMAT) -m32 -o $@

LINKSCRIPTFILE = # 
LINKSCRIPT =  # -T $(LINKSCRIPTFILE)

../../fx86cl:	$(KSPOBJ) $(KERNELOBJ) $(DEBUGOBJ) $(PLATFORM_OBJ) $(LINKSCRIPTFILE)
	$(CC) -m32 $(CDEBUG)  -Wl,--export-dynamic  $(LINKSCRIPT)  -o $@  $(KSPOBJ) $(KERNELOBJ) $(DEBUGOBJ) $(PLATFORM_OBJ) $(OSLIBS)


$(SPOBJ): $(SPINC)
$(ASMOBJ): $(SPINC)
$(COBJ): $(CHEADERS)
$(DEBUGOBJ): $(CHEADERS) lispdcmd.h
$(PLATFORM_OBJ): $(PLATFORM_HEADERS)


cclean:
	$(RM) -f $(KERNELOBJ) $(DEBUGOBJ) $(PLATFORM_OBJ) ../../fx86cl

clean:	cclean
	$(RM) -f $(SPOBJ)

strip:	../../fx86cl
	strip -g ../../fx86cl
