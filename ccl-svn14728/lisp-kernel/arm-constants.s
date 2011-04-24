/*   Copyright (C) 2009 Clozure Associates */
/*   Copyright (C) 1994-2001 Digitool, Inc */
/*   This file is part of Clozure CL. */

/*   Clozure CL is licensed under the terms of the Lisp Lesser GNU Public */
/*   License , known as the LLGPL and distributed with Clozure CL as the */
/*   file "LICENSE".  The LLGPL consists of a preamble and the LGPL, */
/*   which is distributed with Clozure CL as the file "LGPL".  Where these */
/*   conflict, the preamble takes precedence. */

/*   Clozure CL is referenced in the preamble as the "LIBRARY." */

/*   The LLGPL is also available online at */
/*   http://opensource.franz.com/preamble.html */


        
nbits_in_word = 32
nbits_in_byte = 8
ntagbits = 3	/* But only 2 are significant to lisp */
nlisptagbits = 2
nfixnumtagbits = 2
num_subtag_bits = 8
fixnumshift = 2
fixnum_shift = 2
fulltagmask = 7
tagmask = 3
fixnummask = 3
subtag_mask = 0xff        
ncharcodebits = 24              /* arguably, we're only using the low 8 */
charcode_shift = nbits_in_word-ncharcodebits
word_shift = 2
node_size = 4
dnode_size = 8
dnode_align_bits = 3
dnode_shift = dnode_align_bits
bitmap_shift = 5


fixnumone = (1<<fixnumshift)
fixnum_one = fixnumone
fixnum1 = fixnumone

/* registers.  These assignments may not be viable. */

define(`imm0',`r0')             /* even, so ldrd/strd can use imm0/imm1 */
define(`imm1',`r1')
define(`imm2',`r2')
/* rcontext = r3 can be used as an imm reg in certain contexts
   (its value must be easily recovered, but that value never changes
   during a thread's lifetime.)
*/        
define(`rcontext',`r3')         
define(`arg_z',`r4')
define(`arg_y',`r5')
define(`arg_x',`r6')
define(`temp0',`r7')
define(`temp1',`r8')
define(`temp2',`r9')
define(`vsp',`r10')
define(`fn',`r11')
define(`allocptr',`r12')
define(`sp',`r13')
define(`lr',`r14')
define(`pc',`r15')

nargregs = 3
                
define(`fname',`temp1')
define(`nfn',`temp2')
define(`next_method_context',`temp1')
define(`nargs',`imm2')
define(`allocbase',`temp0')     /* while consing */

/* ARM conditions */
eq = 0
ne = 1
cs = 2
hs = cs        
cc = 3
lo = cc        
mi = 4
pl = 5
vs = 6
vc = 7
hi = 8
ls = 9
ge = 10
lt = 11
gt = 12
le = 13
al = 14

/* Tags. */
/* There are two-bit tags and three-bit tags. */
/* A FULLTAG is the value of the low three bits of a tagged object. */
/* A TAG is the value of the low two bits of a tagged object. */
/* A TYPECODE is either a TAG or the value of a "tag-misc" objects header-byte. */

/* There are 4 primary TAG values.  Any object which lisp can "see" can be classified */
/* by its TAG.  (Some headers have FULLTAGS that are congruent modulo 4 with the */
/* TAGS of other objects, but lisp can't "see" headers.) */


tag_fixnum = 0	/* All fixnums, whether odd or even */
tag_list = 1	/* Conses and NIL */
tag_misc = 2	/* Heap-consed objects other than lists: vectors, symbols, functions, floats ... */
tag_imm = 3	/* Immediate-objects: characters, UNBOUND, other markers. */


/*  And there are 8 FULLTAG values.  Note that NIL has its own FULLTAG (congruent mod 4 to tag-list), */
/*  that FULLTAG-MISC is > 4 (so that code-vector entry-points can be branched to, since the low */
/*  two bits of the PC are ignored) and that both FULLTAG-MISC and FULLTAG-IMM have header fulltags */
/*  that share the same TAG. */
/*  Things that walk memory (and the stack) have to be careful to look at the FULLTAG of each */
/*  object that they see. */


fulltag_even_fixnum = 0	/* I suppose EVENP/ODDP might care; nothing else does. */
fulltag_nil = 1	/* NIL and nothing but.  (Note that there's still a hidden NILSYM.) */
fulltag_nodeheader = 2	/* Header of heap_allocated object that contains lisp_object pointers */
fulltag_imm = 3	/* a "real" immediate object.  Shares TAG with fulltag_immheader. */
fulltag_odd_fixnum = 4	/* */
fulltag_cons = 5	/* a real (non_null) cons.  Shares TAG with fulltag_nil. */
fulltag_misc = 6	/* Pointer "real" tag_misc object.  Shares TAG with fulltag_nodeheader. */
fulltag_immheader = 7	/* Header of heap-allocated object that contains unboxed data. */

nil_value = (0x04000000+fulltag_nil)
misc_bias = fulltag_misc
cons_bias = fulltag_cons    
        
unsigned_byte_24_mask = 0xe0000003 /* bits that should be clear in a boxed */
                                   /* (UNSIGNED-BYTE 24) */
            

/* Functions are of (conceptually) unlimited size. */
	_struct(_function,-misc_bias)
	 _node(header)
         _node(entrypoint)      /* codevector & ~tagmask */
	 _node(codevector)
	_ends

	_struct(tsp_frame,0)
	 _node(backlink)
	 _node(type)
	 _struct_label(fixed_overhead)
	 _struct_label(data_offset)
	_ends

/* Order of CAR and CDR doesn't seem to matter much - there aren't */
/* too many tricks to be played with predecrement/preincrement addressing. */
/* Keep them in the confusing MCL 3.0 order, to avoid confusion. */
	_struct(cons,-cons_bias)
	 _node(cdr)
	 _node(car)
	_ends
	
misc_header_offset = -fulltag_misc
misc_subtag_offset = misc_header_offset		/* low byte of header */
misc_data_offset = misc_header_offset+4		/* first word of data */
misc_dfloat_offset = misc_header_offset+8		/* double-floats are doubleword-aligned */

max_64_bit_constant_index = ((0x0fff + misc_dfloat_offset)>>3)
max_32_bit_constant_index = ((0x0fff + misc_data_offset)>>2)
max_16_bit_constant_index = ((0x0fff + misc_data_offset)>>1)
max_8_bit_constant_index = (0x0fff + misc_data_offset)
max_1_bit_constant_index = ((0x0fff + misc_data_offset)<<5)

/* T is almost adjacent to NIL: since NIL is a misaligned CONS, it spans */
/* two doublewords.  The arithmetic difference between T and NIL is */
/* such that the least-significant bit and exactly one other bit is */
/* set in the result. */

t_offset = ((dnode_size-fulltag_nil)+fulltag_misc)
t_value = nil_value+t_offset

/* The order in which various header values are defined is significant in several ways: */
/* 1) Numeric subtags precede non-numeric ones; there are further orderings among numeric subtags. */
/* 2) All subtags which denote CL arrays are preceded by those that don't, */
/*    with a further ordering which requires that (< header-arrayH header-vectorH ,@all-other-CL-vector-types) */
/* 3) The element-size of ivectors is determined by the ordering of ivector subtags. */
/* 4) All subtags are >= fulltag-immheader . */

define(`define_subtag',`
subtag_$1 = $2|($3<<ntagbits)')
	
define(`define_imm_subtag',`
	define_subtag($1,fulltag_immheader,$2)')

	
define(`define_node_subtag',`
	define_subtag($1,fulltag_nodeheader,$2)')

		
/*Immediate subtags. */
        define_subtag(stack_alloc_marker,fulltag_imm,1)
        define_subtag(lisp_frame_marker,fulltag_imm,2) 
	define_subtag(character,fulltag_imm,9)
	define_subtag(unbound,fulltag_imm,6)
        define_subtag(illegal,fulltag_imm,10)
	define_subtag(go_tag,fulltag_imm,12)
	define_subtag(block_tag,fulltag_imm,24)
	define_subtag(vsp_protect,fulltag_imm,7)
        define_subtag(no_thread_local_binding,fulltag_imm,30)
unbound_marker = subtag_unbound
undefined = unbound_marker
illegal_marker = subtag_illegal
no_thread_local_binding_marker = subtag_no_thread_local_binding
lisp_frame_marker = subtag_lisp_frame_marker
stack_alloc_marker = subtag_stack_alloc_marker        
	

/*Numeric subtags. */

	define_imm_subtag(bignum,0)
min_numeric_subtag = subtag_bignum

	define_node_subtag(ratio,1)
max_rational_subtag = subtag_ratio

	define_imm_subtag(single_float,1)
	define_imm_subtag(double_float,2)
min_float_subtag = subtag_single_float
max_float_subtag = subtag_double_float
max_real_subtag = subtag_double_float

	define_node_subtag(complex,3)
max_numeric_subtag = subtag_complex


/* CL array types.  There are more immediate types than node types; all CL array subtags must be > than */
/* all non-CL-array subtags.  So we start by defining the immediate subtags in decreasing order, starting */
/* with that subtag whose element size isn't an integral number of bits and ending with those whose */
/* element size - like all non-CL-array fulltag-immheader types - is 32 bits. */

	define_imm_subtag(bit_vector,31)
	define_imm_subtag(double_float_vector,30)
	define_imm_subtag(s16_vector,29)
	define_imm_subtag(u16_vector,28)
min_16_bit_ivector_subtag = subtag_u16_vector
max_16_bit_ivector_subtag = subtag_s16_vector
	define_imm_subtag(s8_vector,26)
	define_imm_subtag(u8_vector,25)
min_8_bit_ivector_subtag = subtag_u8_vector
max_8_bit_ivector_subtag = fulltag_immheader|(27<<ntagbits)
        define_imm_subtag(simple_base_string,24)
        define_imm_subtag(fixnum_vector,23)
	define_imm_subtag(s32_vector,22)
	define_imm_subtag(u32_vector,21)
	define_imm_subtag(single_float_vector,20)
max_32_bit_ivector_subtag = fulltag_immheader|(24<<ntagbits)
min_cl_ivector_subtag = subtag_single_float_vector


	define_node_subtag(vectorH,20)
	define_node_subtag(arrayH,19)
	define_node_subtag(simple_vector,21)
min_vector_subtag = subtag_vectorH
min_array_subtag = subtag_arrayH

/* So, we get the remaining subtags (n: (n > max-numeric-subtag) & (n < min-array-subtag)) */
/* for various immediate/node object types. */

	define_imm_subtag(macptr,3)
min_non_numeric_imm_subtag = subtag_macptr

	define_imm_subtag(dead_macptr,4)
	define_imm_subtag(code_vector,5)
	define_imm_subtag(creole,6)

max_non_array_imm_subtag = (18<<ntagbits)|fulltag_immheader

	define_node_subtag(catch_frame,4)
	define_node_subtag(function,5)
	define_node_subtag(basic_stream,6)
	define_node_subtag(symbol,7)
	define_node_subtag(lock,8)
	define_node_subtag(hash_vector,9)
	define_node_subtag(pool,10)
	define_node_subtag(weak,11)
	define_node_subtag(package,12)
	define_node_subtag(slot_vector,13)
	define_node_subtag(instance,14)
	define_node_subtag(struct,15)
	define_node_subtag(istruct,16)
	define_node_subtag(value_cell,17)
        define_node_subtag(xfunction,18)
max_non_array_node_subtag = (18<<ntagbits)|fulltag_immheader
	
/* The objects themselves look something like this: */
	_structf(ratio)
	 _node(numer)
	 _node(denom)
	_endstructf

	_structf(single_float)
	 _word(value)
	_endstructf

	_structf(double_float)
	 _word(pad)
	 _dword(value)
	_endstructf

	_structf(symbol)
	 _node(pname)
	 _node(vcell)
	 _node(fcell)
	 _node(package_predicate)
	 _node(flags)
         _node(plist)
         _node(binding_index)
	_endstructf

	_structf(catch_frame)
	 _node(link)		/* backpointer to previous catch frame */
	 _node(mvflag)		/* 0 if single-valued catch, fixnum 1 otherwise */
	 _node(catch_tag)	/* #<unbound> -> unwind-protect, else catch */
	 _node(db_link)		/* head of special-binding chain */
	 _node(xframe)		/* exception frame chain */
         _node(last_lisp_frame) /* from TCR */
         _node(code_vector)     /* of fn in lisp_frame, or 0 */
	_endstructf

	_structf(macptr)
	 _node(address)
         _node(domain)
         _node(type)
	_endstructf

	_structf(vectorH)
	 _node(logsize)
	 _node(physsize)
	 _node(data_vector)
	 _node(displacement)
	 _node(flags)
	_endstructf

        _structf(arrayH)
         _node(rank)
         _node(physsize)
         _node(data_vector)
         _node(displacement)
         _node(flags)
         _struct_label(dim0)
        _endstructf
        
	
        	
	_struct(lisp_frame,0)
         _node(marker)
	 _node(savevsp)	
	 _node(savefn) 
	 _node(savelr)	
	_ends
	


	_struct(vector,-fulltag_misc)
	 _node(header)
	 _struct_label(data)
	_ends

        _struct(binding,0)
         _node(link)
         _node(sym)
         _node(val)
        _ends

/* Indices in %builtin-functions% */
_builtin_plus = 0	/* +-2 */
_builtin_minus = 1	/* --2 */
_builtin_times = 2	/* *-2 */
_builtin_div = 3	/* /-2 */
_builtin_eq = 4		/* =-2 */
_builtin_ne = 5		/* /-2 */
_builtin_gt = 6		/* >-2 */
_builtin_ge = 7		/* >=-2 */
_builtin_lt = 8		/* <-2 */
_builtin_le = 9		/* <=-2 */
_builtin_eql = 10	/* eql */
_builtin_length = 11	/* length */
_builtin_seqtype = 12	/* sequence-type */
_builtin_assq = 13	/* assq */
_builtin_memq = 14	/* memq */
_builtin_logbitp = 15	/* logbitp */
_builtin_logior = 16	/* logior-2 */
_builtin_logand = 17	/* logand-2 */
_builtin_ash = 18	/* ash */
_builtin_negate = 19	/* %negate */
_builtin_logxor = 20	/* logxor-2 */
_builtin_aref1 = 21	/* %aref1 */
_builtin_aset1 = 22	/* %aset1 */


symbol_extra = symbol.size-fulltag_misc
	
	_struct(nrs,0)
	 _struct_pad(dnode_size-fulltag_nil)

	 _struct_pad(fulltag_misc)
	 _struct_label(tsym)
	 _struct_pad(symbol_extra)	/* t */

	 _struct_pad(fulltag_misc)
	 _struct_label(nilsym)
	 _struct_pad(symbol_extra)	/* nil */

	 _struct_pad(fulltag_misc)
	 _struct_label(errdisp)
	 _struct_pad(symbol_extra)	/* %err-disp */

	 _struct_pad(fulltag_misc)
	 _struct_label(cmain)
	 _struct_pad(symbol_extra)	/* cmain */

	 _struct_pad(fulltag_misc)
	 _struct_label(eval)
	 _struct_pad(symbol_extra)	/* eval */
 
	 _struct_pad(fulltag_misc)
	 _struct_label(appevalfn)
	 _struct_pad(symbol_extra)	/* apply-evaluated-function */

	 _struct_pad(fulltag_misc)
	 _struct_label(error)
	 _struct_pad(symbol_extra)	/* error */

	 _struct_pad(fulltag_misc)
	 _struct_label(defun)
	 _struct_pad(symbol_extra)	/* %defun */

	 _struct_pad(fulltag_misc)
	 _struct_label(defvar)
	 _struct_pad(symbol_extra)	/* %defvar */

	 _struct_pad(fulltag_misc)
	 _struct_label(defconstant)
	 _struct_pad(symbol_extra)	/* %defconstant */

	 _struct_pad(fulltag_misc)
	 _struct_label(macrosym)
	 _struct_pad(symbol_extra)	/* %macro */

	 _struct_pad(fulltag_misc)
	 _struct_label(kernelrestart)
	 _struct_pad(symbol_extra)	/* %kernel-restart */

	 _struct_pad(fulltag_misc)
	 _struct_label(package)
	 _struct_pad(symbol_extra)	/* *package* */

	 _struct_pad(fulltag_misc)
	 _struct_label(total_bytes_freed)		/* *total-bytes-freed* */
	 _struct_pad(symbol_extra)

	 _struct_pad(fulltag_misc)
	 _struct_label(kallowotherkeys)
	 _struct_pad(symbol_extra)	/* allow-other-keys */

	 _struct_pad(fulltag_misc)
	 _struct_label(toplcatch)
	 _struct_pad(symbol_extra)	/* %toplevel-catch% */

	 _struct_pad(fulltag_misc)
	 _struct_label(toplfunc)
	 _struct_pad(symbol_extra)	/* %toplevel-function% */

	 _struct_pad(fulltag_misc)
	 _struct_label(callbacks)
	 _struct_pad(symbol_extra)	/* %pascal-functions% */

	 _struct_pad(fulltag_misc)
	 _struct_label(allmeteredfuns)
	 _struct_pad(symbol_extra)	/* *all-metered-functions* */

	 _struct_pad(fulltag_misc)
	 _struct_label(total_gc_microseconds)		/* *total-gc-microseconds* */
	 _struct_pad(symbol_extra)

	 _struct_pad(fulltag_misc)
	 _struct_label(builtin_functions)		/* %builtin-functions% */
	 _struct_pad(symbol_extra)                

	 _struct_pad(fulltag_misc)
	 _struct_label(udf)
	 _struct_pad(symbol_extra)	/* %unbound-function% */

	 _struct_pad(fulltag_misc)
	 _struct_label(init_misc)
	 _struct_pad(symbol_extra)	/* %init-misc */

	 _struct_pad(fulltag_misc)
	 _struct_label(macro_code)
	 _struct_pad(symbol_extra)	/* %macro-code% */

	 _struct_pad(fulltag_misc)
	 _struct_label(closure_code)
	 _struct_pad(symbol_extra)      /* %closure-code% */

       	 _struct_pad(fulltag_misc)
	 _struct_label(new_gcable_ptr) /* %new-gcable-ptr */
	 _struct_pad(symbol_extra)
	
       	 _struct_pad(fulltag_misc)
	 _struct_label(gc_event_status_bits)
	 _struct_pad(symbol_extra)	/* *gc-event-status-bits* */

	 _struct_pad(fulltag_misc)
	 _struct_label(post_gc_hook)
	 _struct_pad(symbol_extra)	/* *post-gc-hook* */

	 _struct_pad(fulltag_misc)
	 _struct_label(handlers)
	 _struct_pad(symbol_extra)	/* %handlers% */


	 _struct_pad(fulltag_misc)
	 _struct_label(all_packages)
	 _struct_pad(symbol_extra)	/* %all-packages% */

	 _struct_pad(fulltag_misc)
	 _struct_label(keyword_package)
	 _struct_pad(symbol_extra)	/* *keyword-package* */

	 _struct_pad(fulltag_misc)
	 _struct_label(finalization_alist)
	 _struct_pad(symbol_extra)	/* %finalization-alist% */

	 _struct_pad(fulltag_misc)
	 _struct_label(foreign_thread_control)
	 _struct_pad(symbol_extra)	/* %foreign-thread-control */

	_ends

define(`def_header',`
$1 = ($2<<num_subtag_bits)|$3')

	def_header(single_float_header,single_float.element_count,subtag_single_float)
	def_header(double_float_header,double_float.element_count,subtag_double_float)
	def_header(one_digit_bignum_header,1,subtag_bignum)
	def_header(two_digit_bignum_header,2,subtag_bignum)
	def_header(three_digit_bignum_header,3,subtag_bignum)
	def_header(symbol_header,symbol.element_count,subtag_symbol)
	def_header(value_cell_header,1,subtag_value_cell	)
	def_header(macptr_header,macptr.element_count,subtag_macptr)
	def_header(vectorH_header,vectorH.element_count,subtag_vectorH)

	include(errors.s)

/* Symbol bits that we care about */
sym_vbit_bound = (0+fixnum_shift)
sym_vbit_bound_mask = (1<<sym_vbit_bound)
sym_vbit_const = (1+fixnum_shift)
sym_vbit_const_mask = (1<<sym_vbit_const)

	_struct(area,0)
	 _node(pred) 
	 _node(succ) 
	 _node(low) 
	 _node(high) 
	 _node(active) 
	 _node(softlimit) 
	 _node(hardlimit) 
	 _node(code) 
	 _node(markbits) 
	 _node(ndwords) 
	 _node(older) 
	 _node(younger) 
	 _node(h) 
	 _node(sofprot) 
	 _node(hardprot) 
	 _node(owner) 
	 _node(refbits) 
	 _node(nextref) 
	_ends




TCR_BIAS = 0
/* TCR_BIAS = 0x7000 */
        
/*  Thread context record. */

	_struct(tcr,-TCR_BIAS)
	 _node(prev)		/* in doubly-linked list */
	 _node(next)		/* in doubly-linked list */
	 _node(lisp_fpscr)	/* lisp thread's fpscr (in low word) */
	 _node(pad)
	 _node(db_link)		/* special binding chain head */
	 _node(catch_top)	/* top catch frame */
	 _node(save_vsp)	/* VSP when in foreign code */
	 _node(save_tsp)	/* TSP when in foreign code */
	 _node(cs_area)		/* cstack area pointer */
	 _node(vs_area)		/* vstack area pointer */
	 _node(last_lisp_frame)	/* when in foreign code */
	 _node(cs_limit)	/* cstack overflow limit */
	 _node(bytes_consed_low)
	 _node(bytes_consed_high)
	 _node(log2_allocation_quantum)
	 _node(interrupt_pending)
	 _node(xframe)		/* per-thread exception frame list */
	 _node(errno_loc)	/* per-thread  errno location */
	 _node(ffi_exception)	/* fpscr exception bits from ff-call */
	 _node(osid)		/* OS thread id */
         _node(valence)		/* odd when in foreign code */
	 _node(foreign_exception_status)
	 _node(native_thread_info)
	 _node(native_thread_id)
	 _node(last_allocptr)
	 _node(save_allocptr)
	 _node(save_allocbase)
	 _node(reset_completion)
	 _node(activate)
         _node(suspend_count)
         _node(suspend_context)
	 _node(pending_exception_context)
	 _node(suspend)		/* semaphore for suspension notify */
	 _node(resume)		/* sempahore for resumption notify */
	 _node(flags)      
	 _node(gc_context)
         _node(termination_semaphore)
         _node(unwinding)
         _node(tlb_limit)
         _node(tlb_pointer)     /* Consider using tcr+N as tlb_pointer */
	 _node(shutdown_count)
         _node(safe_ref_address)
	_ends

TCR_FLAG_BIT_FOREIGN = fixnum_shift       
TCR_FLAG_BIT_AWAITING_PRESET = (fixnum_shift+1)
TCR_FLAG_BIT_ALT_SUSPEND = (fixnumshift+2)
TCR_FLAG_BIT_PROPAGATE_EXCEPTION = (fixnumshift+3)
TCR_FLAG_BIT_SUSPEND_ACK_PENDING = (fixnumshift+4)
TCR_FLAG_BIT_PENDING_EXCEPTION = (fixnumshift+5)
TCR_FLAG_BIT_FOREIGN_EXCEPTION = (fixnumshift+6)
TCR_FLAG_BIT_PENDING_SUSPEND = (fixnumshift+7)  
TCR_FLAG_BIT_ALLOCPTR_FOREIGN = (fixnumshift+8)
	
r0 = 0
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5
r6 = 6
r7 = 7
r8 = 8
r9 = 9
r10 = 10
r11 = 11
r12 = 12
r13 = 13
sp = 13        
r14 = 14
lr = 14
r15 = 15
pc = 15
        
        
/* Lisp code keeps 0.0 in fp_zero */
define(`fp_zero',`f31')   /* a non-volatile reg as far as FFI is concerned. */
define(`fp_s32conv',`f30')   /* for s32->fp conversion */
	
/* registers, as used in destrucuring-bind/macro-bind */

define(`arg_reg',`arg_z')
define(`keyvect_reg',`temp2')
define(`mask_keyp',`(1<<25)') /*  note that keyp can be true even when 0 keys. */
define(`mask_aok',`(1<<26)')
define(`mask_restp',`(1<<27)')
define(`mask_aok_seen',`(1<<30)')
define(`mask_aok_this',`(1<<31)')        
define(`mask_unknown_keyword_seen',`(1<<28)')                
define(`mask_initopt',`(1<<29)')

define(`STACK_ALIGN',8)
define(`STACK_ALIGN_MASK',7)


define(`TCR_STATE_FOREIGN',1)
define(`TCR_STATE_LISP',0)
define(`TCR_STATE_EXCEPTION_WAIT',2)
define(`TCR_STATE_EXCEPTION_RETURN',4)


lisp_globals_limit = -fulltag_nil

num_lisp_globals = 49		 /* MUST UPDATE THIS !!! */
	
	_struct(lisp_globals,-(fulltag_nil+dnode_size+(num_lisp_globals*node_size)))
	 _node(weakvll)                 /* all populations as of last GC */
	 _node(initial_tcr)	        /* initial thread tcr */
	 _node(image_name)	        /* --image-name argument */
	 _node(BADfpscr_save_high)      /* high word of FP reg used to save FPSCR */
	 _node(unwind_resume)           /* _Unwind_Resume */
	 _node(batch_flag)	        /* -b */
	 _node(host_platform)	        /* for runtime platform-specific stuff */
	 _node(argv)			/* address of argv`0' */
	 _node(ref_base)		        /* start of oldest pointer-bearing area */
	 _node(tenured_area) 		/* the tenured_area */
	 _node(oldest_ephemeral) 	/* dword address of oldest ephemeral object or 0 */
	 _node(lisp_exit_hook)		/* install foreign exception_handling */
	 _node(lisp_return_hook)	/* install lisp exception_handling */
	 _node(double_float_one) 	/* high half of 1.0d0 */
	 _node(short_float_zero) 	/* low half of 1.0d0 */
	 _node(objc2_end_catch)         /* objc_end_catch() */
	 _node(metering_info) 		/* address of lisp_metering global */
	 _node(in_gc) 			/* non-zero when GC active */
	 _node(lexpr_return1v) 		/* simpler when &lexpr called for single value. */
	 _node(lexpr_return) 		/* magic &lexpr return code. */
	 _node(all_areas) 		/* doubly-linked list of all memory areas */
	 _node(kernel_path) 		/* real executable name */
	 _node(objc2_begin_catch) 	/* objc_begin_catch */
	 _node(stack_size) 		/* from command-line */
	 _node(statically_linked)	/* non-zero if -static */
	 _node(heap_end)                /* end of lisp heap */
	 _node(heap_start)              /* start of lisp heap */
	 _node(gcable_pointers)         /* linked-list of weak macptrs. */
	 _node(gc_num)                  /* fixnum: GC call count. */
	 _node(fwdnum)                  /* fixnum: GC "forwarder" call count. */
	 _node(altivec_present)         /* non-zero when AltiVec available */
	 _node(oldspace_dnode_count) 	/* dynamic dnodes older than g0 start */
	 _node(refbits) 		/* EGC refbits */
	 _node(gc_inhibit_count)
	 _node(intflag) 		/* sigint pending */
	 _node(BAD_block_tag_counter) 	/* counter for (immediate) block tag */
	 _node(deleted_static_pairs) 		
	 _node(exception_lock)
	 _node(area_lock)
	 _node(tcr_key) 		/* tsd key for per-thread tcr */
	 _node(ret1val_addr) 		/* address of "dynamic" subprims magic values return addr */
	 _node(subprims_base) 		/* address of dynamic subprims jump table */
	 _node(saveR13)			/* probably don't really need this */
	 _node(saveTOC)                 /* where the 68K emulator stores the  emulated regs */
	 _node(objc_2_personality)      /* exception "personality routine" address for ObjC 2.0 */ 
	 _node(kernel_imports) 		/* some things we need imported for us */
	 _node(interrupt_signal)	/* signal used by PROCESS-INTERRUPT */
	 _node(tcr_count) 		/* tcr_id for next tcr */
	 _node(get_tcr) 		/* address of get_tcr() */
	_ends

/* extended type codes, for UUOs.  Shouldn't conflict with defined subtags */

xtype_unsigned_byte_24 = 252
xtype_array2d = 248
xtype_array3d = 244
xtype_integer = 4
xtype_s64 = 8
xtype_u64 = 12
xtype_s32 = 16
xtype_u32 = 20
xtype_s16 = 24
xtype_u16 = 28
xtype_s8 = 32
xtype_u8 = 36
xtype_bit = 40                               
                                               
stack_alloc_limit = 0x8000                        
                        
INTERRUPT_LEVEL_BINDING_INDEX = fixnumone
VOID_ALLOCPTR = 0xfffffff8