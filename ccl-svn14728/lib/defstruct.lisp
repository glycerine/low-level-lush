;;;-*-Mode: LISP; Package: CCL -*-
;;;
;;;   Copyright (C) 2009 Clozure Associates
;;;   Copyright (C) 1994-2001 Digitool, Inc
;;;   This file is part of Clozure CL.  
;;;
;;;   Clozure CL is licensed under the terms of the Lisp Lesser GNU Public
;;;   License , known as the LLGPL and distributed with Clozure CL as the
;;;   file "LICENSE".  The LLGPL consists of a preamble and the LGPL,
;;;   which is distributed with Clozure CL as the file "LGPL".  Where these
;;;   conflict, the preamble takes precedence.  
;;;
;;;   Clozure CL is referenced in the preamble as the "LIBRARY."
;;;
;;;   The LLGPL is also available online at
;;;   http://opensource.franz.com/preamble.html

(in-package "CCL")

;;; Defstruct.lisp

(eval-when (eval compile)
  (require 'defstruct-macros)

)

(defvar %structure-refs% (make-hash-table :test #'eq))
(defvar %defstructs% (make-hash-table :test #'eq))

(defun make-ssd (name initform offset r/o &optional (type t))
  (let ((refinfo (%ilogior2 offset (if r/o #x1000000 0))))
    (list* name initform
           (if (eq type 't)
             refinfo
             (cons type refinfo)))))

(declaim (inline accessor-structref-info-p))
(defun accessor-structref-info-p (object) ;; as opposed to predicate structref-info.
  (consp object))

(declaim (inline structref-info-type))
(defun structref-info-type (info)
  (when (consp info)
    (if (consp (%car info)) (%caar info) 't)))

(declaim (inline structref-info-refinfo))
(defun structref-info-refinfo (info)
  (when (consp info)
    (if (consp (%car info)) (%cdar info) (%car info))))

(defun structref-set-r/o (sym &optional env)
  (let ((info (structref-info sym env)))
    (when (accessor-structref-info-p info)
      (if (consp (%car info))
        (setf (%cdar info) (%ilogior2 (%ilsl $struct-r/o 1) (%cdar info)))
        (setf (%car info) (%ilogior2 (%ilsl $struct-r/o 1) (%car info)))))))

(declaim (inline structref-info-struct))
(defun structref-info-struct (info)
  (when (consp info)
    (%cdr info)))

(defun ssd-set-reftype (ssd reftype)
  (ssd-update-refinfo (ssd refinfo)
                      (%ilogior2 (%ilogand2 #x300FFFF refinfo)
                                 (%ilsl 16 reftype))))

(defun ssd-set-r/o (ssd) 
  (ssd-update-refinfo (ssd refinfo)
                      (%ilogior2 (%ilsl $struct-r/o 1) refinfo)))

(defun ssd-set-inherited (ssd)
  (ssd-update-refinfo (ssd refinfo)
		       (bitset $struct-inherited refinfo)))

(defun copy-ssd (ssd)
  (let* ((cdr (cdr ssd))
         (cddr (cdr cdr)))
    (list* (%car ssd) (%car cdr)
           (if (consp cddr)
             (list* (%car cddr) (%cdr cddr))
             cddr))))

(declaim (inline ssd-type-and-refinfo))
(defun ssd-type-and-refinfo (ssd)
  (cddr ssd))

(defun ssd-type (ssd)
  (let ((type-and-refinfo (ssd-type-and-refinfo ssd)))
    (if (consp type-and-refinfo)
      (%car type-and-refinfo)
      't)))

(defun ssd-refinfo (ssd)
  (let ((type-and-refinfo (ssd-type-and-refinfo ssd)))
    (if (consp type-and-refinfo) (%cdr type-and-refinfo) type-and-refinfo)))

(defun %structure-class-of (thing)
  (let* ((cell (car (uvref thing 0))))
    (or (class-cell-class cell)
        (setf (class-cell-class cell)
              (find-class (class-cell-name cell))))))

;These might want to compiler-transform into non-typechecking versions...
(defun struct-ref (struct offset)
  (if (structurep struct) (uvref struct offset)
      (report-bad-arg struct 'structure-object)))

(defun struct-set (struct offset value)
  (if (structurep struct) (uvset struct offset value)
      (report-bad-arg struct 'structure-object)))

(defsetf struct-ref struct-set)


; things for defstruct to do - at load time
(defun %defstruct-do-load-time (sd predicate &optional doc &aux (name (sd-name sd)))
  ;(declare (ignore refnames))
  (when (null (sd-type sd))
    (%define-structure-class sd))
  (when (and doc *save-doc-strings*)
    (set-documentation name 'type doc))  
  (puthash name %defstructs% sd)
  (record-source-file name 'structure)
  (when (and predicate (null (sd-type sd)))
    (puthash predicate %structure-refs% name))  
  (when *fasload-print* (format t "~&~S~%" name))
  name)

(defun %defstruct-set-print-function (sd print-function print-object-p)
  (sd-set-print-function sd (if print-object-p
			      (list print-function)
			      print-function)))

(defun sd-refname-in-included-struct-p (sd name &optional env)
  (dolist (included-type (cdr (sd-superclasses sd)))
    (let ((sub-sd (or (let ((defenv (definition-environment env)))
			(when defenv (%cdr (assq included-type
						 (defenv.structures
						     defenv)))))
		      (gethash included-type %defstructs%))))
      (when sub-sd
	(if (member name (sd-refnames sub-sd) :test 'eq)
	  (return t))))))

(defun sd-refname-pos-in-included-struct (sd name)
  (dolist (included-type (cdr (sd-superclasses sd)))
    (let ((sub-sd (gethash included-type %defstructs%)))
      (when sub-sd
        (let ((refnames (sd-refnames sub-sd)))
          (if refnames
            (let ((pos (position name refnames :test 'eq)))
              (and pos (1+ pos)))
            (dolist (slot (sd-slots sub-sd))
              (let ((ssd-name (ssd-name slot)))
                (unless (fixnump ssd-name)
                  (when (eq name ssd-name)
                    (return-from sd-refname-pos-in-included-struct
                      (ssd-offset slot))))))))))))

;;; return stuff for defstruct to compile
(defun %defstruct-compile (sd refnames env)
  (let ((stuff)
        (struct (and (not (sd-type sd)) (sd-name sd))))
    (dolist (slot (sd-slots sd))
      (unless (fixnump (ssd-name slot))
        (let* ((accessor (if refnames (pop refnames) (ssd-name slot)))
               (pos (sd-refname-pos-in-included-struct sd accessor)))
          (if pos
            (let ((offset (ssd-offset slot)))
              (unless (eql pos offset)
                ;; This should be a style-warning
                (warn "Accessor ~s at different position than in included structure"
                      accessor)))
            (unless (sd-refname-in-included-struct-p sd accessor env)
              (let ((fn (slot-accessor-fn sd slot accessor env))
                    (info (cons (ssd-type-and-refinfo slot) struct)))
                (push
                 `(progn
                    ,.fn
                    (puthash ',accessor %structure-refs% ',info)
                    (record-source-file ',accessor 'structure-accessor))
                 stuff)))))))
    (nreverse stuff)))

(defun defstruct-var (name env)
  (declare (ignore env))
  (if (symbolp name)
    (if (or (constant-symbol-p name) (proclaimed-special-p name))
      (make-symbol (symbol-name name))
      name)
    'object))

(defun slot-accessor-fn (sd slot name env)
  (let* ((ref (ssd-reftype slot))
         (offset (ssd-offset slot))
         (arg (defstruct-var (sd-name sd) env))
         (value (gensym "VALUE"))
         (type (defstruct-type-for-typecheck (ssd-type slot) env))
         (form (cond ((eq ref $defstruct-nth)
                      `(nth ,offset ,arg))
                     ((eq ref $defstruct-struct)
                      `(struct-ref (typecheck ,arg ,(sd-name sd)) ,offset))
                     ((or (eq ref target::subtag-simple-vector)
                          (eq ref $defstruct-simple-vector))
                      `(svref ,arg ,offset))
                     (t `(uvref ,arg ,offset)))))
    `((defun ,name (,arg)
        ,(cond ((eq type t) form)
	       ((nx-declarations-typecheck env)
		;; TYPE may be unknown.  For example, it may be
		;; forward-referenced.  Insert a run-time check in
		;; this case.
		`(require-type ,form ',type))
	       (t `(the ,type ,form))))
      ,@(unless (ssd-r/o slot)
          `((defun (setf ,name) (,value ,arg)
              ,(cond
		((eq type t) `(setf ,form ,value))
		((nx-declarations-typecheck env)
		 ;; Checking the type of SETF's return value seems
		 ;; kind of pointless here.
		 `(require-type (setf ,form (typecheck ,value ,type)) ',type))
		(t
		 `(the ,type (setf ,form (typecheck ,value ,type)))))))))))

(defun defstruct-reftype (type)
  (cond ((null type) $defstruct-struct)
        ((eq type 'list) $defstruct-nth)
        (t (element-type-subtype (cadr type)))))

(defun defstruct-slot-defs (sd refnames env)
  (declare (ignore env))
  (let ((ref (defstruct-reftype (sd-type sd))) name defs)
    (dolist (slot (sd-slots sd))
      (ssd-set-reftype slot ref)
      (unless (fixnump (setq name (ssd-name slot))) ;Ignore fake 'name' slots
        (when refnames (setq name (pop refnames)))
        (unless (sd-refname-pos-in-included-struct sd name)
          (push name defs))))
    (setq defs (nreverse defs))
    `((declaim (inline ,@defs)))))

(defun structref-info (sym &optional env)
  (let ((info (or (and env (environment-structref-info sym env))
                  (gethash sym %structure-refs%))))
    ;; This can be removed once $fasl-min-vers is greater than #x5e
    #-BOOTSTRAPPED
    (when (or (fixnump info)
              (and (consp info) (fixnump (%cdr info))))
      ;; Old style, without struct type info.
      (setq info (cons info 'structure-object)))
    info))

(defun defstruct-type-for-typecheck (type env)
  (if (or (eq type 't)
          (specifier-type-if-known type env)
          (nx-declarations-typecheck env))
    type
    ;; Else have an unknown type used only for an implicit declaration.
    ;; Just ignore it, it's most likely a forward reference, and while it
    ;; means we might be missing out on a possible optimization, most of
    ;; the time it's not worth warning about.
    't))

;;;Used by nx-transform, setf, and whatever...
(defun defstruct-ref-transform (structref-info args env &optional no-type-p)
  (if (accessor-structref-info-p structref-info)
    (let* ((type (if no-type-p
                   't
                   (defstruct-type-for-typecheck (structref-info-type structref-info) env)))
           (refinfo (structref-info-refinfo structref-info))
           (offset (refinfo-offset refinfo))
           (ref (refinfo-reftype refinfo))
           (accessor
            (cond ((eq ref $defstruct-nth)
                   `(nth ,offset ,@args))
                  ((eq ref $defstruct-struct)
                   `(struct-ref (typecheck ,@args ,(structref-info-struct structref-info)) ,offset))
                  ((eq ref target::subtag-simple-vector)
                   `(svref ,@args ,offset))
                  (ref
                   `(aref (the (simple-array ,(element-subtype-type ref) (*))
                               ,@args) ,offset))
                  (t `(uvref ,@args ,offset)))))
      (if (eq type 't)
        accessor
	(if (nx-declarations-typecheck env)
	  `(typecheck ,accessor ,type)
	  `(the ,type ,accessor))))
    `(structure-typep ,@args ',structref-info)))

;;; Should probably remove the constructor, copier, and predicate as
;;; well. Can't remove the inline proclamations for the refnames,
;;; as the user may have explicitly said this. Questionable - but surely
;;; must delete the inline definitions.
;;; Doesn't remove the copier because we don't know for sure what it's name is
(defmethod change-class ((from structure-class)
			 (to class)
			  &rest initargs &key &allow-other-keys)
  (declare (dynamic-extent initargs))
  (let ((class-name (class-name from)))
    (unless (eq from to)                  ; shouldn't be
      (remove-structure-defs class-name)
      (remhash class-name %defstructs%)))
  (%change-class from to initargs))

;;; if redefining a structure as another structure or redefining a
;;; structure as a class
(defun remove-structure-defs (class-name)
  (let ((sd (gethash class-name %defstructs%)))
    (when sd
      (dolist (refname (sd-refnames sd))
	(unless (sd-refname-in-included-struct-p sd refname)
	  (let ((def (assq refname *nx-globally-inline*)))
	    (when def (set-function-info refname nil)))
	  (let ((info (structref-info refname)))
	    (when (accessor-structref-info-p info)
	      (unless (refinfo-r/o (structref-info-refinfo info))
		(fmakunbound (setf-function-name refname)))
	      (fmakunbound refname)))))
      #|
      ;; The print-function may indeed have become obsolete,
      ;; but we can't generally remove user-defined code
      (let ((print-fn (sd-print-function sd)))
        (when (symbolp print-fn) (fmakunbound print-fn)))
      |#
      (let ((constructor (sd-constructor sd)))
        (when (symbolp constructor) (fmakunbound constructor)))
      (let ((delete-match #'(lambda (pred struct-name)
                              (when (eq struct-name class-name)
                                (remhash pred %structure-refs%)
                                (fmakunbound pred)))))
        (declare (dynamic-extent delete-match))
        ; get rid of the predicate
        (maphash delete-match %structure-refs%)))))

(defun copy-structure (source)
  "Return a copy of STRUCTURE with the same (EQL) slot values."
  (copy-uvector (require-type source 'structure-object)))

(provide 'defstruct)

; End of defstruct.lisp
