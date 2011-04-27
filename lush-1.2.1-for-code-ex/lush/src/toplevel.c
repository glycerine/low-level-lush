/***********************************************************************
 * 
 *  LUSH Lisp Universal Shell
 *    Copyright (C) 2002 Leon Bottou, Yann Le Cun, AT&T Corp, NECI.
 *  Includes parts of TL3:
 *    Copyright (C) 1987-1999 Leon Bottou and Neuristique.
 *  Includes selected parts of SN3.2:
 *    Copyright (C) 1991-2001 AT&T Corp.
 * 
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA
 * 
 ***********************************************************************/

/***********************************************************************
 * $Id: toplevel.c,v 1.38 2006/04/12 22:52:55 leonb Exp $
 **********************************************************************/


#include "header.h"
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

struct error_doc error_doc;
struct recur_doc recur_doc;
struct context *context;

static struct context first_context;
static at* at_startup;
static at* at_toplevel;
static at* at_break;
static at* at_debug;
static at* at_file;
static at *result;
static int quiet;

/* initialization functions */
#ifdef UNIX
extern void init_unix (void);
extern void fini_unix (void);
extern void init_user (void);
#endif
#ifdef WIN32
extern void init_win32(void);
#endif
extern void init_oostruct (void);
extern void init_symbol (void);
extern void init_eval (void);
extern void init_function (void);
extern void init_at (void);
extern void init_calls (void);
extern void init_arith (void);
extern void init_string (void);
extern void init_fileio (char *);
extern void init_io (void);
extern void init_htable(void);
extern void init_toplevel (void);
extern void init_classify (void);
extern void init_nan (void);
extern void init_binary (void);
extern void init_dump (void);
extern void init_module (char *);
extern void init_date (void);
extern void init_dz (void);
extern void init_storage (void);
extern void init_index (void);
extern void init_idx1 (void);
extern void init_idx2 (void);
extern void init_idx3 (void);
extern void init_idx4 (void);
extern void init_dh (void);
extern void init_lisp_c (void);
extern void init_event (void);
extern void init_graphics (void);
extern void init_ps_driver (void);
extern void init_lisp_driver (void);
extern void init_comdraw_driver (void);
#ifndef NOGRAPHICS
#ifdef UNIX
#ifndef X_DISPLAY_MISSING
extern void init_x11_driver (void);
#endif
#endif
#ifdef WIN32
extern void init_win_driver(void);
#endif
#endif
#ifdef WIN32
int isatty (int);
#endif

/* From AT.C */
extern int compute_bump_active;

/* From DUMP.C */
extern int isdump (char *s);
extern void undump (char *s);

/* From BINARY.C */
extern int in_bwrite;

/* FORWARD */
static void recur_doc_init(void);


/********************************************/

/*
 * Exiting Lush quickly
 */

void
abort(char *s)
{
  clean_tmp_files();
  FINI_MACHINE;
  FMODE_TEXT(stderr);
  fprintf(stderr,"\nLush Fatal Error: %s\n", s);
  exit(10);
  while(1);
}


/*
 * Exiting Lush cleanly
 */

void 
clean_up(void)
{
  set_script(NIL);
  error_doc.ready_to_an_error = FALSE;
  clean_tmp_files();
  garbage(FALSE);
  FINI_MACHINE;
  FMODE_TEXT(stderr);
  if (! quiet)
    fprintf(stderr,"Bye!\n");
}



/********************************************/

void 
init_lush(char *program_name)
{
  at *p,*version;
  INIT_MACHINE;
  init_oostruct();
  init_symbol();
  init_eval();
  init_function();
  init_string();
  init_fileio(program_name);
  init_at();
  init_calls();
  init_arith();
  init_io();
  init_htable();
  init_toplevel();
  init_classify();
  init_nan();
  init_binary();
  init_module(program_name);
  init_date();
  init_dz();
  init_storage();
  init_index();
  init_idx1();
  init_idx2();
  init_idx3();
  init_idx4();
  init_dh();
  init_lisp_c();
  init_dump();
  init_event();
#ifdef UNIX
  init_user();
#endif
#ifndef NOGRAPHICS
  init_graphics();
  init_ps_driver();
  init_lisp_driver();
  init_comdraw_driver();
#ifdef UNIX
#ifndef X_DISPLAY_MISSING
  init_x11_driver();
#endif
#endif
#ifdef WIN32
  init_win_driver();
#endif
#endif
  /* Very simple way to define version :-) */
  version = var_define("version");
  p = new_string("lush");
  var_set(version,p);
  var_lock(version);
  UNLOCK(p);
}



/*
 * start_lisp 
 * Calls the lisp interpretor 
 * - load startup files
 * - launch an interactive toplevel with the user
 */


void 
start_lisp(int argc, char **argv, int quietflag)
{
  at *p, *q;
  at **where;
  int i;
  char *s, *r;
  error_doc.script_file = NIL;
  error_doc.script_mode = SCRIPT_OFF;
  error_doc.error_prefix = NIL;
  error_doc.error_text = NIL;
  error_doc.error_suffix = NIL;
  error_doc.ready_to_an_error = FALSE;
  error_doc.debug_toplevel = FALSE;
  error_doc.this_call = NIL;
  error_doc.error_call = NIL;
  recur_doc_init();
  dx_sp = dx_stack - 1;

  context = &first_context;
  context->next = NIL;
  context->input_file = stdin;
  context->output_file = stdout;
  context->input_tab = context->output_tab = 0;

  quiet = quietflag;
  if (! sigsetjmp(context->error_jump, 1)) 
    {
      s = "stdenv";
      /* Check @-argument */
      if (argc>1 && argv[1][0]=='@')
	{
	  argc--; argv++;
          if (!argv[0][1] && argc>1) {
            /* Case 'lush @ xxxenv' */
            argc--; argv++; s = argv[0];
          } else if (strcmp(&argv[0][1],"@"))
            /* Case 'lush @xxxenv' but not 'lush @@' */
            s = &argv[0][1];
          /* Current dir has priority */
          r = concat_fname(NULL,s);
          if (search_file(r,"|.dump|.lshc|.lsh"))
            s = r;
        }
      /* Search a dump file */
      if ((r = search_file(s,"|.dump")) && isdump(r))
	{
	  error_doc.ready_to_an_error = FALSE;
          if (! quiet)
            {
              FMODE_TEXT(stdout);
              fprintf(stdout,"+[%s]\n",r);
              FMODE_BINARY(stderr);
            }
	  undump(r);
	}
      /* Search a lush file */
      else if ((r = search_file(s,"|.lshc|.lsh")))
	{
	  error_doc.ready_to_an_error = TRUE;
          if (! quiet) 
            {
              FMODE_TEXT(stdout);
              fprintf(stdout,"+[%s]\n",r);
              FMODE_BINARY(stderr);
            }
	  toplevel(r, NIL, NIL);
	}
      else
	abort("Cannot locate system libraries");
      /* Calls the cold startup procedure with arguments */
      error_doc.ready_to_an_error = TRUE;
      error_doc.debug_toplevel = FALSE;
      error_doc.this_call = NIL;
      error_doc.error_call = NIL;
      error_doc.error_prefix = NIL;
      error_doc.error_text = NIL;
      error_doc.error_suffix = NIL;
      recur_doc_init();
      dx_sp = dx_stack - 1;
      line_pos = line_buffer;
      *line_buffer = 0;
      in_bwrite = 0;
      p = NIL;
      where = &p;
      for (i=1; i<argc; i++)
        {
          *where = cons(new_string(argv[i]),NIL);
          where = &((*where)->Cdr);
        }
      q = apply(at_startup,p);
      UNLOCK(p);
      UNLOCK(q);
    }
  /* No interactive loop in quiet mode */
  if (! quiet)
    {
      error_doc.ready_to_an_error = FALSE;
      garbage(TRUE);
      error_doc.ready_to_an_error = TRUE;
      error_doc.debug_toplevel = FALSE;
      error_doc.this_call = NIL;
      error_doc.error_call = NIL;
      error_doc.error_prefix = NIL;
      error_doc.error_text = NIL;
      error_doc.error_suffix = NIL;
      recur_doc_init();
      dx_sp = dx_stack - 1;
      line_pos = line_buffer;
      *line_buffer = 0;
      in_bwrite = 0;
      for(;;)
        {
          /* Calls the interactive toplevel */
          q = apply(at_toplevel,NIL);
          UNLOCK(q);
          if (!isatty(fileno(stdin)))
            break;
          if (ask("Really quit"))
            break;
        } 
    }
  /* Finished */
  clean_up();
}


/***********************************************/

/* 
 * Utilities for detection of infinite recursion.
 */

#define HASHP(p) \
  (((unsigned long)(p))^(((unsigned long)(p))>>6))

static void
recur_resize_table(int nbuckets)
{
  struct recur_elt **ntable;
  if (! (ntable = malloc(nbuckets * sizeof(void*))))
    error(NIL,"Out of memory",NIL);
  memset(ntable, 0, nbuckets * sizeof(void*));
  if (recur_doc.htable)
  {
    int i,n;
    struct recur_elt *elt, *nelt;
    for (i=0; i<recur_doc.hbuckets; i++)
      for (elt=recur_doc.htable[i]; elt; elt=nelt)
      {
        nelt = elt->next;
        n = HASHP(elt->p) % nbuckets;
        elt->next = ntable[n];
        ntable[n]=elt;
      }
    if (recur_doc.htable)
      free(recur_doc.htable);
  }
  recur_doc.htable = ntable;
  recur_doc.hbuckets = nbuckets;
}


static void 
recur_doc_init()
{
  if (recur_doc.hbuckets == 0)
    recur_resize_table(127);
  memset(recur_doc.htable, 0, 
         recur_doc.hbuckets * sizeof(void*));
  recur_doc.hsize = 0;
}


/* 
 * Detection of infinite recursion.
 */

int 
recur_push_ok(struct recur_elt *elt, void *call, at *p)
{
  struct recur_elt *tst;
  /* Test with hash table */
  int n = HASHP(p) % recur_doc.hbuckets;
  for  (tst=recur_doc.htable[n]; tst; tst=tst->next)
   if (tst->p==p && tst->call==call)
     return FALSE;
  /* Prepare record */
  elt->call = call;
  elt->p = p;
  elt->next = recur_doc.htable[n];
  recur_doc.htable[n] = elt;
  recur_doc.hsize += 1;
  /* Test if htable needs resizing */
  if (recur_doc.hsize*2 > recur_doc.hbuckets*3) 
    recur_resize_table(recur_doc.hsize*2-1);
  /* Successfully added to hash table */
  return TRUE;
}


void 
recur_pop(struct recur_elt *elt)
{
  struct recur_elt **tst;
  int n = HASHP(elt->p) % recur_doc.hbuckets;
  /* Search entry in hash table */
  tst=&recur_doc.htable[n];
  while (tst && *tst!=elt)
    tst = &((*tst)->next);
  if (!tst)
    error(NIL,"Internal error in recursion detector", NIL);
  /* Remove entry when found */
  *tst = (*tst)->next;
  recur_doc.hsize -= 1;
}


/***********************************************/


/*
 * context stack handling context_push(s) context_pop()
 */

void 
context_push(struct context *newc)
{
  *newc = *context;
  newc->next = context;
  context = newc;
}

void 
context_pop(void)
{
  struct context *oldcontext = context;
  if (context->next)
    context = context->next;
  if (oldcontext->input_string && context->input_string)
    context->input_string = oldcontext->input_string;
  if (oldcontext->input_tab >= 0)
    context->input_tab = oldcontext->input_tab;
  if (oldcontext->output_tab >= 0)
    context->output_tab = oldcontext->output_tab;
}



/***********************************************/


/*
 * toplevel( input_file, output_file, verbose_mode )
 */

static int discard_flag;
static int exit_flag = 0;

void 
toplevel(char *in, char *out, char *prompts)
{
  FILE *f1, *f2;
  at *ans = NIL;
  register at *q1, *q2;
  char *ps1 = 0;
  char *ps2 = 0;
  char *ps3 = 0;
  struct context mycontext;
  /* Open files */
  f1 = f2 = NIL;
  if (in) {
    f1 = open_read(in, "|.lshc|.snc|.tlc|.lsh|.sn|.tl");
    ans = new_string(file_name);
  }
  if (out)
    f2 = open_write(out, "script");
  /* Make files current */
  context_push(&mycontext);
  symbol_push(at_file,ans);
  if (f1) {
    context->input_file = f1;
    context->input_tab = 0;
  }
  if (f2) {
    context->output_file = f2;
    context->output_tab = 0;
  }
  /* Split prompt */
  if (prompts) {
    const char d = '|';
    char *s;
    ps1 = strdup(prompts);
    s = ps1;
    while (*s && *s != d)
      s += 1;
    if (! *s) {
      ps2 = "  ";
      ps3 = ps1;
    } else {
      *s++ = 0;
      ps2 = s;
      while (*s && *s != d)
        s += 1;
      if (! *s) {
        ps3 = ps1;
      } else {
        *s++ = 0;
        ps3 = s;
        while (*s && *s != d)
          s += 1;
        if (*s)
          *s = 0;
      }
    }
  }
  if (sigsetjmp(context->error_jump, 1)) {
    /* An error occurred */
    if (f1)
      file_close(f1);
    if (f2)
      file_close(f2);
    if (ps1)
      free(ps1);
    context_pop();
    symbol_pop(at_file);
    siglongjmp(context->error_jump, -1);
  }
  /* Toplevel loop */
  exit_flag = 0;
  while ( !exit_flag && !feof(context->input_file)) {
    if (context->input_file == stdin)
      fflush(stdout);
    /* Skip junk */
    prompt_string = ps1;
    while (skip_to_expr() == ')')
      read_char();
    /* Read */
    prompt_string = ps2;
    TOPLEVEL_MACHINE;
    q1 = read_list();
    if (q1) {
      /* Eval */
      prompt_string = ps3;
      error_doc.debug_tab = 0;
      TOPLEVEL_MACHINE;
      discard_flag = FALSE;
      q2 = eval(q1);
      /* Print */
      if (f2) {
	if (discard_flag) {
	  print_string("= ");
	  print_string(first_line(q2));
	} else {
	  print_string("= ");
	  print_list(q2);
	}
	print_char('\n');
      }
      discard_flag = FALSE;
      UNLOCK(q1);
      var_set(result, q2);
      UNLOCK(q2);
    }
  }
  /* Cleanup */
  if (context->input_file)
    {
      clearerr(context->input_file);
      if (context->input_file == stdin) 
        {
          line_pos = line_buffer;
          *line_buffer = 0;
        }
    }
  if (f1) 
    {
      file_close(f1);
      strcpy(file_name, SADD(ans->Object));
      UNLOCK(ans);
    }
  if (f2)
    file_close(f2);
  if (ps1)
    free(ps1);
  context_pop();
  symbol_pop(at_file);
  exit_flag = 0;
}

DX(xload)
{
  register char *s,*prompt;

  ALL_ARGS_EVAL;

  if (arg_number == 3) {
    s = ASTRING(2);
    prompt = ASTRING(3);
    toplevel(ASTRING(1), s, prompt);
  } else if (arg_number == 2) {
    s = ASTRING(2);
    toplevel(ASTRING(1), s, NIL);
  } else {
    ARG_NUMBER(1);
    toplevel(ASTRING(1), NIL, NIL);
  }
  return new_string(file_name);
}

/*
 * (discard ....) Evals his argument list, but force toplevel to print only a
 * few characters as result. However, the system variable RESULT contains
 * always the result.
 */
DY(ydiscard)
{
  discard_flag = TRUE;
  return progn(ARG_LIST);
}


/* 
 * exit
 */

void
set_toplevel_exit_flag(void)
{
  exit_flag = 1;
}

DX(xexit)
{
  if (arg_number==1) {
    int n = AINTEGER(1);
    ARG_EVAL(1);
    clean_up();
    exit(n);
  }
  set_toplevel_exit_flag();
  return NIL;
}


/***********************************************/

/*
 * error-routines
 * 
 * error(prefix,text,atsuffix) is the main error routine. print_error(prefix
 * text atsuffix) prints the error stocked in error_doc.
 */

static char *
error_text(void)
{
  extern char *print_buffer;
  char *prefix = error_doc.error_prefix;
  char *prefixsep = " : ";
  char *text = error_doc.error_text;
  char *textsep = " : ";
  at *suffix = error_doc.error_suffix;
  at *call = error_doc.error_call;
  
  strcpy(print_buffer, "No information on current error condition");
  
  if (!prefix &&
      CONSP(call) && CONSP(call->Car) && call->Car->Car && 
      (call->Car->Car->flags&X_SYMBOL) ) {
    prefix = nameof(call->Car->Car);
  }
  prefix = prefix ? prefix : "";
  text = text ? text : "";
  if (!*prefix || !*text)
    prefixsep = "";
  if (!*text || !suffix)
    textsep = "";
  sprintf(print_buffer,"%s%s%s%s%s", 
	  prefix, prefixsep, text, textsep, 
	  suffix ? first_line(suffix) : "" );
  return print_buffer;
}


void
user_break(char *s)
{
  eval_ptr = eval_std;
  argeval_ptr = eval_std;
  compute_bump_active = 0;
  if (error_doc.ready_to_an_error == FALSE)
    lastchance("Break");
  
  TOPLEVEL_MACHINE;
  error_doc.error_call = error_doc.this_call;
  error_doc.ready_to_an_error = FALSE;
  error_doc.error_prefix = NIL;
  error_doc.error_text = "Break";
  error_doc.error_suffix = NIL;
  line_pos = line_buffer;
  *line_buffer = 0;

  if (!error_doc.debug_toplevel && strcmp(s,"on read")) 
  {
    at *(*sav_ptr)(at *) = eval_ptr;
    at *(*argsav_ptr)(at *) = argeval_ptr;
    at *q;

    eval_ptr = eval_std;
    argeval_ptr = eval_std;
    error_doc.ready_to_an_error = TRUE;
    error_doc.debug_toplevel = TRUE;
    ifn (q = apply(at_break,NIL)) 
    {
       UNLOCK(q);
       error_doc.debug_toplevel = FALSE;
       error_doc.error_call = NIL;
       error_doc.error_prefix = NIL;
       error_doc.error_text = NIL;
       error_doc.error_suffix = NIL;
       eval_ptr = sav_ptr;
       argeval_ptr = argsav_ptr;
       return;
    }
  }
  else
  {
    FILE *old;
    old = context->output_file;
    context->output_file = stdout;
    print_string("\n\007*** Break\n");
    context->output_file = old;      
  }
  recur_doc_init();
  error_doc.debug_toplevel = FALSE;
  siglongjmp(context->error_jump, -1);
  while (1) { /* no return */ };
}


void 
error(char *prefix, char *text, at *suffix)
{
  if (run_time_error_flag)
    run_time_error(text);

  eval_ptr = eval_std;
  argeval_ptr = eval_std;
  compute_bump_active = 0;

  if (error_doc.ready_to_an_error == FALSE)
    lastchance(text);
  
  TOPLEVEL_MACHINE;
  error_doc.error_call = error_doc.this_call;
  error_doc.ready_to_an_error = FALSE;
  error_doc.error_prefix = prefix;
  error_doc.error_text = text;
  error_doc.error_suffix = suffix;
  recur_doc_init();
  line_pos = line_buffer;
  *line_buffer = 0;
  LOCK(suffix);

  if (! error_doc.debug_toplevel) 
    {
      eval_ptr = eval_std;
      argeval_ptr = eval_std;
      error_doc.ready_to_an_error = TRUE;
      error_doc.debug_toplevel = TRUE;
      apply(at_debug,NIL);
    } 
  else 
    {
      FILE *old;
      text = error_text();
      old = context->output_file;
      context->output_file = stdout;
      print_string("\n\007*** ");
      print_string(text);
      print_string("\n");
      context->output_file = old;      
    }
  error_doc.debug_toplevel = FALSE;
  siglongjmp(context->error_jump, -1);
  while (1) { /* no return */ };
}

DX(xerror)
{
  at *call;
  at *symb = 0;
  at *arg = 0;
  char *msg = 0;
  
  ALL_ARGS_EVAL;
  switch (arg_number) {
  case 1:
    msg = ASTRING(1);
    break;
  case 2:
    if (ISSYMBOL(1)) {
      symb = APOINTER(1);
      msg = ASTRING(2);
    } else {
      msg = ASTRING(1);
      arg = APOINTER(2);
    }
    break;
  case 3: 
    ASYMBOL(1);
    symb = APOINTER(1);
    msg = ASTRING(2);
    arg = APOINTER(3);
    break;
  default:
    error(NIL,"illegal arguments",NIL);
  }
  call = error_doc.this_call;
  while( CONSP(call) ) {
    if (CONSP(call->Car) && call->Car->Car==symb) {
      error_doc.this_call = call;
      break;
    }
    call = call->Cdr;
  }
  error(NIL, msg, arg);
  return NIL;
}

DX(xwhere)
{
  at *call;
  int n = 0;
  
  if (arg_number==1) {
    ARG_EVAL(1);
    n = AINTEGER(1);
  } else {
    ARG_NUMBER(0);
  }
  call = error_doc.error_call;
  if (! call)
    call = error_doc.this_call;
  while (--n!=0 && CONSP(call)) {
    if (call == error_doc.error_call)
      print_string("** in:   ");
    else
      print_string("** from: ");
    print_string(first_line(call->Car));
    call = call->Cdr;
    print_string("\n");
  }
  return NIL;
}

DX(xerrname)
{
  ARG_NUMBER(0);
  return new_string( error_text() );
}

DX(xquiet)
{
  ALL_ARGS_EVAL;
  if (arg_number>0)
    {
      extern int line_flush_stdout;
      ARG_NUMBER(1);
      quiet = ((APOINTER(1)) ? TRUE : FALSE);
      line_flush_stdout = ! quiet;
    }
  return ((quiet) ? true() : NIL);
}

/* --------- INITIALISATION CODE --------- */


void
init_toplevel(void)
{
  at_startup  = var_define("startup");
  at_toplevel = var_define("toplevel");
  at_break =    var_define("break-hook");
  at_debug =    var_define("debug-hook");
  at_file =     var_define("file-being-loaded");
  result =      var_define("result");

  dx_define("exit", xexit);
  dx_define("load", xload);
  dy_define("discard", ydiscard);
  dx_define("error", xerror);
  dx_define("where", xwhere);
  dx_define("errname", xerrname);
  dx_define("lush-is-quiet", xquiet);
}
