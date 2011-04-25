;;;============================================================================

;;; File: "_front.scm", Time-stamp: <2010-06-10 16:34:45 feeley>

;;; Copyright (c) 1994-2009 by Marc Feeley, All Rights Reserved.

(include "fixnum.scm")

(include-adt "_envadt.scm")
(include-adt "_gvmadt.scm")
(include-adt "_ptreeadt.scm")
(include-adt "_sourceadt.scm")

'(begin;**********brad
(##include "../gsc/_utilsadt.scm")
(##include "../gsc/_ptree1adt.scm")
(##include "../gsc/_envadt.scm")
(##include "../gsc/_gvmadt.scm")
(##include "../gsc/_hostadt.scm")
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (zzzbb-put-non-branch! bb text gvm-instr)
  (let ((frame (gvm-instr-frame gvm-instr))
        (comment (gvm-instr-comment gvm-instr)))
    '
    (bb-put-non-branch! bb
      (make-copy (make-obj text)
                 (make-glo '***)
                 frame
                 comment))
    (bb-put-non-branch! bb gvm-instr)))

;;;----------------------------------------------------------------------------

;;;; Front-end of GAMBIT compiler

;;;----------------------------------------------------------------------------

;; sample use:
;;
;; (cf "tak" 'c '() #f #f)          -- compile tak.scm to tak.c using C back-end
;; (cf "tak" #f '() #f #f)          -- compile tak.scm using default back-end
;; (cf "tak" 'c '() "foo.c" #f)     -- compile tak.scm to foo.c using C back-end
;; (cf "tak" 'c '(verbose) #f #f)   -- produce compiler trace
;; (cf "tak" 'c '(report) #f #f)    -- show usage of global variables
;; (cf "tak" 'c '(gvm) #f #f)       -- write GVM code on 'tak.gvm'
;; (cf "tak" 'c '(debug) #f #f)     -- generate code with debugging info
;; (cf "tak" 'c '(expansion) #f #f) -- show code after source-to-source transf.
;; (cf "tak" 'c '(asm stats) #f #f) -- various back-end options

(define cf #f)

(set! cf
  (lambda (input target-name opts output mod-name)
    (let ((remaining-opts
           (handle-options opts)))

      (set! warnings-requested? compiler-option-warnings)

      (let* ((output-root
              (if output
                  #f
                  (path-strip-directory
                   (path-strip-extension input))))
             (info-port
              (if compiler-option-verbose
                  (current-output-port)
                  #f))
             (successful
              (with-exception-handling
               (lambda ()
                 (if (not (null? remaining-opts))
                     (compiler-error
                      "Unhandled compiler options:" remaining-opts))
                 (compile-program
                  input
                  (or target-name (default-target))
                  opts
                  remaining-opts
                  output
                  output-root
                  mod-name
                  info-port)))))

        successful))))

(define (handle-options opts)
  (reset-options)
  (let ((rev-remaining-opts '()))

    (for-each
     (lambda (opt)
       (case opt
         ((warnings)
          (set! compiler-option-warnings           #t))
         ((verbose)
          (set! compiler-option-verbose            #t))
         ((report)
          (set! compiler-option-report             #t))
         ((expansion)
          (set! compiler-option-expansion          #t))
         ((gvm)
          (set! compiler-option-gvm                #t))
         ((debug)
          (set! compiler-option-debug              #t))
         ((debug-location)
          (set! compiler-option-debug-location     #t))
         ((debug-source)
          (set! compiler-option-debug-source       #t))
         ((debug-environments)
          (set! compiler-option-debug-environments #t))
         ((track-scheme)
          (set! compiler-option-track-scheme       #t))
         ((c dynamic exe obj link flat
           check force keep-c
           o l prelude postlude
           cc-options ld-options-prelude ld-options)
          #f) ;; these options are innocuous
         (else
          (set! rev-remaining-opts
                (cons opt rev-remaining-opts)))))
     opts)

    (if (or compiler-option-debug-location
            compiler-option-debug-source
            compiler-option-debug-environments)
        (set! compiler-option-debug #t)
        (begin
          (set! compiler-option-debug-location     #t)
          (set! compiler-option-debug-source       #t)
          (set! compiler-option-debug-environments #t)))

    (reverse rev-remaining-opts)))

(define (reset-options)
  (set! compiler-option-warnings           #f)
  (set! compiler-option-verbose            #f)
  (set! compiler-option-report             #f)
  (set! compiler-option-expansion          #f)
  (set! compiler-option-gvm                #f)
  (set! compiler-option-debug              #f)
  (set! compiler-option-debug-location     #f)
  (set! compiler-option-debug-source       #f)
  (set! compiler-option-debug-environments #f)
  (set! compiler-option-track-scheme       #f))

(define compiler-option-warnings           #f)
(define compiler-option-verbose            #f)
(define compiler-option-report             #f)
(define compiler-option-expansion          #f)
(define compiler-option-gvm                #f)
(define compiler-option-debug              #f)
(define compiler-option-debug-location     #f)
(define compiler-option-debug-source       #f)
(define compiler-option-debug-environments #f)
(define compiler-option-track-scheme       #f)

(define ##compilation-options '())

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;;; The program compiler

(define wrap-program #f)
(set! wrap-program
  (lambda (program)
    program))

(define expand-source #f)
(set! expand-source
  (lambda (program)
    program))

(define (compile-program
         input
         target-name
         opts
         remaining-opts
         output
         output-root
         mod-name
         info-port)

  (define (compiler-body)
    (let* ((root
            (or output-root
                (path-strip-extension output)))
           (module-name
            (or mod-name
                (path-strip-directory root))))

      (if (not (valid-module-name? module-name))
        (compiler-error
          "Invalid characters in file name (must be a symbol with no \"#\")")
        (begin

          (scheme-global-var-define!
            (scheme-global-var
              (string->canonical-symbol "##compilation-options"))
            (cons target-name opts))

          (env.begin!)
          (ptree.begin! info-port)
          (virtual.begin!)
          (target-select! target-name info-port)

          (let ((x (read-source input #f #t)))
            (parse-program
             (expand-source (wrap-program (##vector-ref x 1)));;;;;;;;;;;;;;
             (make-global-environment)
             module-name
             (lambda (lst env c-intf)
               (let ((parsed-program (normalize-program lst)))

                 (if compiler-option-expansion
                   (let ((port (current-output-port)))
                     (display "Expansion:" port)
                     (newline port)
                     (let loop ((l parsed-program))
                       (if (pair? l)
                         (let ((ptree (car l)))
                           (newline port)
                           (pp-expression (parse-tree->expression ptree) port)
                           (loop (cdr l)))))
                     (newline port)))

                 (let ((module-procs
                        (compile-parsed-program module-name
                                                parsed-program
                                                env
                                                c-intf
                                                info-port)))

                   (if compiler-option-report
                     (generate-report env))

                   (if compiler-option-gvm
                     (let ((gvm-port
                            (open-output-file (string-append root ".gvm"))))
                       (virtual.dump module-procs gvm-port)
                       (close-output-port gvm-port)))

                   (target.dump
                    module-procs
                    output
                    output-root
                    c-intf
                    (##vector-ref x 0);;;;;;;;;;;;;;;;;;;;
                    opts)

                   (dump-c-intf module-procs root c-intf))))))

          (target-unselect!)
          (virtual.end!)
          (ptree.end!)
          (env.end!)

          #t))))

  (set! warnings-requested? compiler-option-warnings)

  (let ((successful (with-exception-handling compiler-body)))

    (if info-port
      (if successful
        (begin
          (display "Compilation finished." info-port)
          (newline info-port))
        (begin
          (display "Compilation terminated abnormally." info-port)
          (newline info-port))))

    successful))

(define (valid-module-name? module-name)

  ; Valid module names are exactly the valid symbols except those
  ; containing "#".

  (define (valid-char? c)
    (and (not (memv c '(#\# #\; #\( #\) #\  #\[ #\] #\{ #\} #\" #\' #\` #\,)))
         (not (char-whitespace? c))))

  (let ((n (string-length module-name)))
    (and (> n 0)                               ; should not be empty
         (not (string=? module-name "."))      ; should not be "."
         (not (string->number module-name 10)) ; should not be a number
         (let loop ((i 0))
           (if (< i n)
             (if (valid-char? (string-ref module-name i))
               (loop (+ i 1))
               #f)
             #t)))))

(define (dump-c-intf module-procs root c-intf)
  (let ((decls (c-intf-decls c-intf))
        (procs (c-intf-procs c-intf))
        (inits (c-intf-inits c-intf)))

    (if (or (not (null? decls))
            (not (null? procs))
            (not (null? inits)))

      (let* ((module-name
              (proc-obj-name (car module-procs)))
             (filename
              (string-append root ".c"))
             (port
              (open-output-file filename)))

        (display "/* File: \"" port)
        (display filename port)
        (display "\", C-interface file produced by Gambit " port)
        (display (compiler-version-string) port)
        (display " */" port)
        (newline port)

        (display "#define " port)
        (display c-id-prefix port)
        (display "MODULE_NAME \"" port)
        (display module-name port)
        (display "\"" port)
        (newline port)

        (display "#define " port)
        (display c-id-prefix port)
        (display "MODULE_LINKER " port)
        (display c-id-prefix port)
        (display (scheme-id->c-id module-name) port)
        (newline port)

        (display "#define " port)
        (display c-id-prefix port)
        (display "VERSION " port)
        (display (compiler-version) port)
        (newline port)

        ;; ******************to be fixed

        (if (not (null? procs))
          (begin
            (display "#define " port)
            (display c-id-prefix port)
            (display "C_PRC_COUNT " port)
            (display (length procs) port)
            (newline port)))

        (display "#include \"gambit.h\"" port)
        (newline port)

        (display c-id-prefix port)
        (display "BEGIN_MODULE" port)
        (newline port)

        (for-each
          (lambda (x)
            (let ((scheme-name (c-proc-scheme-name x)))
              (display c-id-prefix port)
              (display "SUPPLY_PRM(" port)
              (display c-id-prefix port)
              (display "P_" port)
              (display (scheme-id->c-id scheme-name) port)
              (display ")" port)
              (newline port)))
          procs)

        (newline port)

        (for-each
          (lambda (x)
            (display x port)
            (newline port))
          decls)

        (if (not (null? procs))
          (begin

            (for-each
              (lambda (x)
                (let ((scheme-name (c-proc-scheme-name x))
                      (c-name (c-proc-c-name x))
                      (arity (c-proc-arity x))
                      (body (c-proc-body x)))
                  (display c-id-prefix port)
                  (display "BEGIN_C_COD(" port)
                  (display c-name port)
                  (display "," port)
                  (display c-id-prefix port)
                  (display "P_" port)
                  (display (scheme-id->c-id scheme-name) port)
                  (display "," port)
                  (display arity port)
                  (display ")" port)
                  (newline port)

                  ;;???????????????????????????????????????????????
                  (display "#undef ___ARG1" port)
                  (newline port)
                  (display "#define ___ARG1 ___R1" port)
                  (newline port)
                  (display "#undef ___ARG2" port)
                  (newline port)
                  (display "#define ___ARG2 ___R2" port)
                  (newline port)
                  (display "#undef ___ARG3" port)
                  (newline port)
                  (display "#define ___ARG3 ___R3" port)
                  (newline port)
                  (display "#undef ___RESULT" port)
                  (newline port)
                  (display "#define ___RESULT ___R1" port)
                  (newline port)

                  (display body port)
                  (display c-id-prefix port)
                  (display "END_C_COD" port)
                  (newline port)))
              procs)

            (newline port)

            (display c-id-prefix port)
            (display "BEGIN_C_PRC" port)
            (newline port)

            (let loop ((i 0) (lst procs))
              (if (not (null? lst))
                (let* ((x (car lst))
                       (scheme-name (c-proc-scheme-name x))
                       (c-name (c-proc-c-name x))
                       (arity (c-proc-arity x)))
                  (if (= i 0)
                    (display " " port)
                    (display "," port))
                  (display c-id-prefix port)
                  (display "DEF_C_PRC(" port)
                  (display c-name port)
                  (display "," port)
                  (display c-id-prefix port)
                  (display "P_" port)
                  (display (scheme-id->c-id scheme-name) port)
                  (display "," port)
                  (display arity port)
                  (display ")" port)
                  (newline port)
                  (loop (+ i 1) (cdr lst)))))

            (display c-id-prefix port)
            (display "END_C_PRC" port)
            (newline port)))

        (newline port)

        (display c-id-prefix port)
        (display "BEGIN_PRM" port)
        (newline port)

        (for-each
          (lambda (x)
            (display x port)
            (newline port))
          inits)

        (display c-id-prefix port)
        (display "END_PRM" port)
        (newline port)

        (close-output-port port)))))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;;; Report generation

(define (generate-report env)
  (let ((vars (sort-variables (env-global-variables env))))

    (define (report title pred? vars wrote-something?)
      (if (pair? vars)
        (let ((var (car vars)))
          (if (pred? var)
            (begin
              (if (not wrote-something?)
                (begin
                  (display " ")
                  (display title)
                  (newline)))
              (let loop1 ((l (ptset->list (var-refs var))) (r? #f) (c? #f))
                (if (pair? l)
                  (let* ((x (car l))
                         (y (node-parent x)))
                    (if (and y (app? y) (eq? x (app-oper y)))
                      (loop1 (cdr l) r? #t)
                      (loop1 (cdr l) #t c?)))
                  (let loop2 ((l (ptset->list (var-sets var))) (d? #f) (a? #f))
                    (if (pair? l)
                      (if (set? (car l))
                        (loop2 (cdr l) d? #t)
                        (loop2 (cdr l) #t a?))
                      (begin
                        (display "  [")
                        (if d? (display "D") (display " "))
                        (if a? (display "A") (display " "))
                        (if r? (display "R") (display " "))
                        (if c? (display "C") (display " "))
                        (display "] ")
                        (display (var-name var)) (newline))))))
              (report title pred? (cdr vars) #t))
            (cons (car vars) (report title pred? (cdr vars) wrote-something?))))
        (begin
          (if wrote-something? (newline))
          '())))

    (define (classify var std?)
      (let ((proc (target.prim-info (var-name var))))
        (and proc
             (standard-procedure?
               proc
               std?
               (not std?)
               (scheme-dialect env)))))

    (display "Global variable usage:") (newline)
    (newline)

    (report "OTHERS"
            (lambda (var) #t)
            (report "EXTENDED"
                    (lambda (var) (classify var #f))
                    (report "STANDARD"
                            (lambda (var) (classify var #t))
                            vars
                            #f)
                    #f)
            #f)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (compile-parsed-program module-name program env c-intf info-port)

  (if info-port
    (display "Compiling:" info-port))

  (set! trace-indentation 0)

  (set! *bbs* (make-bbs))
  (set! *global-env* env)

  (set! proc-queue '())
  (set! known-procs '())

  (restore-context
    (make-context 0 '() (list ret-var) '() (entry-poll) #f))

  (let ((procs

          (let loop1 ((l program) (procs '()))
            (if (not (null? l))

              (let ((node (car l)))
                (if (def? node)
                  (let* ((var (def-var node))
                         (val (global-single-def var)))
                    (if (and val (prc? val))
                      (let ((proc
                              (make-proc-obj
                                (symbol->string (var-name var)) ; name
                                (prc-c-name val)   ; c-name
                                #t                 ; primitive?
                                #f                 ; code
                                (call-pattern val) ; call-pat
                                #t                 ; side-effects?
                                '()                ; strict-pat
                                0                  ; lift-pat
                                '(#f)              ; type
                                #f)))              ; standard
                        (add-constant-var var (make-obj proc))
                        (loop1 (cdr l) (cons proc procs)))
                      (loop1 (cdr l) procs)))
                  (loop1 (cdr l) procs)))

              (let loop2 ((l (c-intf-procs c-intf)) (procs procs))
                (if (not (null? l))

                  (let* ((x (car l))
                         (name (c-proc-scheme-name x))
                         (arity (c-proc-arity x))
                         (sym (string->canonical-symbol name))
                         (var (env-lookup-global-var *global-env* sym))
                         (pat (make-pattern arity 0 0 #f))
                         (proc
                           (make-proc-obj
                             name     ; name
                             #f       ; c-name
                             #t       ; primitive?
                             x        ; code
                             pat      ; call-pat
                             #t       ; side-effects?
                             '()      ; strict-pat
                             0        ; lift-pat
                             '(#f)    ; type
                             #f)))    ; standard
                    (add-constant-var var (make-obj proc))
                    (set-car! l proc)
                    (loop2 (cdr l) (cons proc procs)))

                  (reverse procs)))))))

    (let* ((entry-lbl
            (bbs-new-lbl! *bbs*))
           (body-lbl
            (bbs-new-lbl! *bbs*))
           (frame
            (current-frame ret-var-set))
           (node1
            (car program)))

      (bbs-entry-lbl-num-set! *bbs* entry-lbl)

      (set! entry-bb
        (make-bb (make-label-entry
                  entry-lbl
                  0
                  '()
                  #f
                  #f
                  #f
                  frame
                  (node->comment node1))
                 *bbs*))

      (bb-put-branch! entry-bb
        (make-jump (make-lbl body-lbl)
                   #f
                   #f
                   #f
                   frame
                   (node->comment node1)))

      (set! *bb*
        (make-bb (make-label-simple body-lbl frame (node->comment node1))
                 *bbs*))

      (let loop3 ((l program))
        (let ((node (car l)))
          (if (def? node)
            (gen-define (def-var node) (def-val node) info-port)
            (gen-node node
                      ret-var-set
                      (if (null? (cdr l))
                        (make-reason-tail)
                        (make-reason-side))))
          (if (null? (cdr l))
            (if (def? node)
              (gen-return node
                          ret-var-set
                          (make-reason-tail)
                          (make-obj void-object)))
            (loop3 (cdr l)))))

      (let loop4 ()
        (if (pair? proc-queue)
          (let ((proc-info (car proc-queue)))
            (set! proc-queue (cdr proc-queue))
            (gen-proc proc-info info-port)
            (trace-unindent info-port)
            (loop4))))

      (if info-port
        (begin
          (newline info-port)
          (newline info-port)))

      (bbs-purify! *bbs*)

      (let ((proc
              (make-proc-obj
                (string-append module-prefix module-name) ; name
                #f           ; c-name
                #t           ; primitive?
                *bbs*        ; code
                '(0)         ; call-pat
                #t           ; side-effects?
                '()          ; strict-pat
                0            ; lift-pat
                '(#f)        ; type
                #f)))        ; standard

        (set! *bb* '())
        (set! *bbs* '())
        (set! *global-env* '())

        (set! proc-queue '())
        (set! known-procs '())

        (clear-context)

        (cons proc procs)))))

(define *bb* '())
(define *bbs* '())
(define *global-env* '())

(define proc-queue '())
(define known-procs '())

(define trace-indentation '())

(define (trace-indent info-port)
  (set! trace-indentation (+ trace-indentation 1))
  (if info-port
    (begin
      (newline info-port)
      (let loop ((i trace-indentation))
        (if (> i 0)
          (begin (display "  " info-port) (loop (- i 1))))))))

(define (trace-unindent info-port)
  (set! trace-indentation (- trace-indentation 1)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (gen-define var node info-port)
  (if (prc? node)

    (let ((p-bbs         *bbs*)
          (p-bb          *bb*)
          (p-proc-queue  proc-queue)
          (p-known-procs known-procs)
          (p-context     (current-context)))

      (set! *bbs* (make-bbs))
      (set! proc-queue '())
      (set! known-procs '())

      (let* ((proc-info (schedule-gen-proc node '()))
             (entry-lbl-num (proc-info-lbl1 proc-info)))

        (define (do-body)
          (let loop ()
            (if (pair? proc-queue)
              (let ((proc-info (car proc-queue)))
                (set! proc-queue (cdr proc-queue))
                (gen-proc proc-info info-port)
                (trace-unindent info-port)
                (loop))))
          (trace-unindent info-port)
          (bbs-purify! *bbs*))

        (bbs-entry-lbl-num-set! *bbs* entry-lbl-num)
        (if (constant-var? var)
          (let-constant-var var (make-lbl entry-lbl-num)
            (lambda ()
              (add-known-proc proc-info)
              (do-body)))
          (do-body))
        (let ((bbs *bbs*)
              (x (var-constant var)))
          (set! *bbs* p-bbs)
          (set! *bb* p-bb)
          (set! proc-queue p-proc-queue)
          (set! known-procs p-known-procs)
          (restore-context p-context)
          (if x
;;;         (let ((proc (obj-val (cdr x))))
            (let ((proc (obj-val x)))
              (proc-obj-code-set! proc bbs))
            (let ((proc
                    (make-proc-obj
                      (symbol->string (var-name var)) ; name
                      (prc-c-name node)   ; c-name
                      #f                  ; primitive?
                      bbs                 ; code
                      (call-pattern node) ; call-pat
                      #t                  ; side-effects?
                      '()                 ; strict-pat
                      0                   ; lift-pat
                      '(#f)               ; type
                      #f)))               ; standard
              (put-copy 1 (make-obj proc)
                        (make-glo (var-name var))
                        #f
                        ret-var-set
                        (node->comment node)))))))

    (let* ((dst (make-glo (var-name var)))
           (src (gen-node node
                          ret-var-set
                          (make-reason-need dst))))
      (put-copy 2 src dst #f ret-var-set (node->comment node)))))

(define (call-pattern node)
  (let ((nb-parms (length (prc-parms node)))
        (nb-opts (length (prc-opts node)))
        (nb-keys (length (or (prc-keys node) '())))
        (rest? (prc-rest? node)))
    (make-pattern nb-parms nb-opts nb-keys rest?)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;; Runtime context manipulation (i.e. where the variables are, what registers
;; are in use, etc.)

;; runtime context description: nb-slots = number of slots presently
;; allocated for the current frame on the stack, slots = list of
;; variables associated with each slot (topmost slot first), regs =
;; list of variables contained in each register, closed = list of
;; variables which are closed with respect to the current procedure,
;; poll = what is the maximum number of GVM instructions that can be
;; executed before the next poll instruction and has there been a poll
;; instruction executed since entry to this procedure, entry-bb = the
;; entry basic block for the procedure containing this context (must
;; have a label of type PROC).

(define (make-context nb-slots slots regs closed poll entry-bb)
  (vector nb-slots slots regs closed poll entry-bb))

(define (context-nb-slots x)        (vector-ref x 0))
(define (context-slots x)           (vector-ref x 1))
(define (context-regs x)            (vector-ref x 2))
(define (context-closed x)          (vector-ref x 3))
(define (context-poll x)            (vector-ref x 4))
(define (context-entry-bb x)        (vector-ref x 5))
(define (context-entry-bb-set! x y) (vector-set! x 5 y))

(define nb-slots  '())
(define slots     '())
(define regs      '())
(define closed    '())
(define poll      '())
(define entry-bb  '())

(define (restore-context context)
  (set! nb-slots   (context-nb-slots context))
  (set! slots      (context-slots context))
  (set! regs       (context-regs context))
  (set! closed     (context-closed context))
  (set! poll       (context-poll context))
  (set! entry-bb   (context-entry-bb context)))

(define (clear-context)
  (restore-context (make-context '() '() '() '() '() '())))

(define (current-context)
  (make-context nb-slots slots regs closed poll entry-bb))

(define (current-frame live)
  (make-frame nb-slots slots regs closed live))

(define (context->frame context live)
  (make-frame (context-nb-slots context)
              (context-slots context)
              (context-regs context)
              (context-closed context)
              live))

(define (make-poll since-entry? delta)
  (cons since-entry? delta))

(define (poll-since-entry? x) (car x))
(define (poll-delta x) (cdr x))

(define (entry-poll)
  (make-poll #f (- poll-period poll-head)))

(define (return-poll poll)
  (let ((delta (poll-delta poll)))
    (make-poll (poll-since-entry? poll)
               (+ poll-head (max delta poll-tail)))))

(define (poll-merge poll other-poll)
  (make-poll
    (or (poll-since-entry? poll) ;; shouldn't it be "and"?
        (poll-since-entry? other-poll))
    (max (poll-delta poll)
         (poll-delta other-poll))))

(define poll-period #f) ; Lmax
(set! poll-period 40000)

(define poll-head #f) ; E
(set! poll-head 200)

(define poll-tail #f) ; R
(set! poll-tail 200)

;; (entry-context proc closed) returns the context in existence upon entry to
;; the procedure `proc'

(define (entry-context proc closed)

  (define (empty-vars-list n)
    (if (> n 0)
      (cons empty-var (empty-vars-list (- n 1)))
      '()))

  (let* ((parms (prc-parms proc))
         (pc (target.label-info (length parms) (not (null? closed))))
         (fs (pcontext-fs pc))
         (slots-list (empty-vars-list fs))
         (regs-list (empty-vars-list target.nb-regs)))

    (define (assign-var-to-loc var loc)
      (let ((x (cond ((reg? loc)
                      (let ((i (reg-num loc)))
                        (if (<= i target.nb-regs)
                          (drop regs-list i)
                          (compiler-internal-error
                            "entry-context, reg out of bound in back-end's pcontext"))))
                     ((stk? loc)
                      (let ((i (stk-num loc)))
                        (if (<= i fs)
                          (drop slots-list (- fs i))
                          (compiler-internal-error
                            "entry-context, stk out of bound in back-end's pcontext"))))
                     (else
                      (compiler-internal-error
                        "entry-context, loc other than reg or stk in back-end's pcontext")))))
        (if (eq? (car x) empty-var)
          (set-car! x var)
          (compiler-internal-error
            "entry-context, duplicate location in back-end's pcontext"))))

    (let loop ((l (pcontext-map pc)))
      (if (not (null? l))
        (let* ((couple (car l))
               (name (car couple))
               (loc (cdr couple)))
          (cond ((eq? name 'return)
                 (assign-var-to-loc ret-var loc))
                ((eq? name 'closure-env)
                 (assign-var-to-loc closure-env-var loc))
                (else
                 (assign-var-to-loc (list-ref parms (- name 1)) loc)))
          (loop (cdr l)))))

;;;;;;;;;;;;;;;;;;
'(pp (list '********2 fs (map (lambda (x) (and x (var-name x))) slots-list) (map (lambda (x) (and x (var-name x))) regs-list) (map var-name closed)))
    (make-context fs slots-list regs-list closed (entry-poll) #f)))

(define (get-var opnd)
  (cond ((glo? opnd)
         (env-lookup-global-var *global-env* (glo-name opnd)))
        ((reg? opnd)
         (list-ref regs (reg-num opnd)))
        ((stk? opnd)
         (list-ref slots (- nb-slots (stk-num opnd))))
        (else
         (compiler-internal-error
           "get-var, location must be global, register or stack slot"))))

(define (put-var opnd new)

  (define (put-v opnd new)
    (cond ((reg? opnd)
           (set! regs (replace-nth regs (reg-num opnd) new)))
          ((stk? opnd)
           (set! slots (replace-nth slots (- nb-slots (stk-num opnd)) new)))
          (else
           (compiler-internal-error
             "put-var, location must be register or stack slot, for var:"
             (var-name new)))))

  (if (and (eq? new ret-var) ; only keep one copy of return address
           (or (memq ret-var regs)
               (memq ret-var slots)))
    (put-v (var->opnd ret-var) empty-var))

  (put-v opnd new))

(define (flush-regs)
  (set! regs '()))

(define (push-slot)
  (set! slots (cons empty-var slots))
  (set! nb-slots (+ nb-slots 1)))

(define (adjust-slots new-nb-slots live comment)
  (if (< new-nb-slots nb-slots)
    (shrink-slots2 new-nb-slots)
    (extend-slots2 new-nb-slots live comment)))

(define (shrink-slots2 new-nb-slots)
  (set! slots (drop slots (- nb-slots new-nb-slots)))
  (set! nb-slots new-nb-slots))

(define (extend-slots2 new-nb-slots live comment)
  (let loop ()
    (if (< nb-slots new-nb-slots)
      (begin
        (push-slot)
        (zzzbb-put-non-branch! *bb* "IN extend-slots2"
          (make-copy #f
                     (make-stk nb-slots)
                     (current-frame live)
                     comment))
        (loop)))))

(define (extend-slots new-nb-slots live comment)
  (if (< new-nb-slots nb-slots)
    (compiler-internal-error
     "extend-slots, invalid argument"))
  (extend-slots2 new-nb-slots live comment))

(define (shrink-slots new-nb-slots)
  (if (or (< new-nb-slots 0)
          (> new-nb-slots nb-slots))
    (compiler-internal-error
     "shrink-slots, invalid argument"))
  (shrink-slots2 new-nb-slots))

(define (replace-nth l i v)
  (if (null? l)
    (if (= i 0)
      (list v)
      (cons empty-var (replace-nth l (- i 1) v)))
    (if (= i 0)
      (cons v (cdr l))
      (cons (car l) (replace-nth (cdr l) (- i 1) v)))))

(define (live-vars live)
  (if (varset-intersects? live (list->varset closed))
    (varset-adjoin live closure-env-var)
    live))

(define (live-reg-var? reg-var live-v)
  (and (varset-member? reg-var live-v)
       (not (memq reg-var slots))))

(define (live-slot-var? slot-var live-v)
  (varset-member? slot-var live-v))

(define (dead-reg/stk? opnd live)
  (cond ((reg? opnd)
         (let ((var (reg->var regs (reg-num opnd))))
           (or (not var)
               (not (live-reg-var? var (live-vars live))))))
        ((stk? opnd)
         (let ((var (stk->var slots (stk-num opnd))))
           (or (not var)
               (not (live-slot-var? var (live-vars live))))))
        (else
         #f)))

(define (live-slots live)
  (let ((live-v (live-vars live)))
    (let loop ((s '()) (l slots) (i nb-slots))
      (cond ((null? l)
             s)
            ((live-slot-var? (car l) live-v)
             (loop (cons i s) (cdr l) (- i 1)))
            (else
             (loop s (cdr l) (- i 1)))))))

(define (dead-slots live)
  (let ((live-v (live-vars live)))
    (let loop ((s '()) (l slots) (i nb-slots))
      (cond ((null? l)
             s)
            ((not (live-slot-var? (car l) live-v))
             (loop (cons i s) (cdr l) (- i 1)))
            (else
             (loop s (cdr l) (- i 1)))))))

(define (live-regs live)
  (let ((live-v (live-vars live)))
    (let loop ((s '()) (l regs) (i 0))
      (cond ((null? l)
             (reverse s))
            ((live-reg-var? (car l) live-v)
             (loop (cons i s) (cdr l) (+ i 1)))
            (else
             (loop s (cdr l) (+ i 1)))))))

(define (lowest-dead-slot live)
  (make-stk (or (lowest (dead-slots live)) (+ nb-slots 1))))

(define (highest-live-slot live)
  (make-stk (or (highest (live-slots live)) 0)))

(define (lowest-dead-reg live)
  (let ((live-v (live-vars live)))
    (if (null? regs)
      (make-reg 1)
      (let ((reg0 (car regs))
            (rest (cdr regs)))
        (let loop ((rest rest) (i 1))
          (if (null? rest)
            (if (< i target.nb-regs)
              (make-reg i)
              (if (live-reg-var? reg0 live-v)
                #f
                (make-reg 0)))
            (if (live-reg-var? (car rest) live-v)
              (loop (cdr rest) (+ i 1))
              (make-reg i))))))))

(define (highest-dead-reg live)
  (let ((live-v (live-vars live)))
    (cond ((or (null? regs) (not (live-reg-var? (car regs) live-v)))
           (make-reg 0))
          ((< (length regs) target.nb-regs)
           (make-reg (- target.nb-regs 1)))
          (else
           (let loop ((rest (reverse (cdr regs))) (i (- target.nb-regs 1)))
             (if (null? rest)
               #f
               (if (live-reg-var? (car rest) live-v)
                 (loop (cdr rest) (- i 1))
                 (make-reg i))))))))

(define (highest lst) ; return highest number in a list
  (if (null? lst) #f (apply max lst)))

(define (lowest lst) ; return lowest number in a list
  (if (null? lst) #f (apply min lst)))

(define (var->opnd var)
  (let ((x (var-constant var)))
    (if x
      x
      (if (global? var)
        (make-glo (var-name var))
        (let ((n (pos-in-list var regs)))
          (if n
            (make-reg n)
            (let ((n (pos-in-list var slots)))
              (if n
                (make-stk (- nb-slots n))
                (let ((n (pos-in-list var closed)))
                  (if n
                    (make-clo (var->opnd closure-env-var) (+ n 1))
                    (begin
                      ;;*************
                      ;;(display "================")(newline)
                      ;;(display "regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs))
                      ;;(display "slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
                      ;;(display "closed: ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) closed))
                      (compiler-internal-error
                       "var->opnd, variable is not accessible:" (var-name var)))))))))))))

(define (node->comment node)
  (let ((x (make-comment)))
    (comment-put! x 'node node)
    x))

(define (sort-variables lst)
  (sort-list lst
             (lambda (x y)
               (string<? (symbol->string (var-name x))
                         (symbol->string (var-name y))))))

;;;----------------------------------------------------------------------------

(define (add-constant-var var opnd)
  (var-constant-set! var opnd))

(define (let-constant-var var opnd thunk)
  (let ((temp (var-constant var)))
    (var-constant-set! var opnd)
    (thunk)
    (var-constant-set! var temp)))

(define (constant-var? var)
  (var-constant var))

(define (not-constant-var? var)
  (not (constant-var? var)))

(define (add-known-proc proc-info)
  (set! known-procs
        (cons (cons (proc-info-lbl1 proc-info) proc-info) known-procs)))

;;;----------------------------------------------------------------------------

;;;; generate code for a procedure

(define (gen-proc proc-info info-port)
  (let ((proc (proc-info-proc proc-info)))
    (trace-indent info-port)
    (if info-port
      (if (prc-name proc)
        (write (string->canonical-symbol (prc-name proc)) info-port)
        (write "unknown" info-port)))
    (set! *bb* (proc-info-bb proc-info))
    (let ((lbl (bb-lbl-num *bb*)))
      (restore-context (proc-info-context proc-info))
      (gen-node (prc-body proc)
                (varset-union (proc-body-live-varset proc)
                              ret-var-set)
                (make-reason-tail)))))

(define (proc-body-live-varset proc)
  (let* ((body (prc-body proc))
         (env (node-env body)))
    (if (optimize-dead-local-variables? env)
        (varset-empty)
        (list->varset (prc-parms proc)))))

(define (schedule-gen-proc proc closed-list)
  (let* ((lbl1 (bbs-new-lbl! *bbs*)) ; arg check entry point
         (lbl2 (bbs-new-lbl! *bbs*)) ; no arg check entry point
         (context-lbl1 (entry-context proc closed-list))
         (context-lbl2 context-lbl1)
         (frame-lbl1 (context->frame
                      context-lbl1
                      (varset-union (bound-free-variables (prc-body proc))
                                    (varset-union (proc-body-live-varset proc)
                                                  ret-var-set))))
         (frame-lbl2 frame-lbl1)
         (bb1 (make-bb
                (make-label-entry
                  lbl1
                  (length (prc-parms proc))
                  (map make-obj (prc-opts proc))
                  (and (prc-keys proc)
                       (map (lambda (x)
                              (cons (car x) (make-obj (cdr x))))
                            (prc-keys proc)))
                  (prc-rest? proc)
                  (not (null? closed-list))
                  frame-lbl1
                  (node->comment proc))
                *bbs*))
         (bb2 (make-bb
                (make-label-simple
                  lbl2
                  frame-lbl2
                  (node->comment proc))
                *bbs*))
         (proc-info (make-proc-info proc lbl1 lbl2 bb2 context-lbl2
                                    (target.label-info (length (prc-parms proc)) (not (null? closed-list))))));**************
    (context-entry-bb-set! context-lbl1 bb1)
    (bb-put-branch! bb1
      (make-jump (make-lbl lbl2) #f #f #f frame-lbl2 (node->comment proc)))
    (set! proc-queue (cons proc-info proc-queue))
    proc-info))

(define (make-proc-info proc lbl1 lbl2 bb context pcontext)
  (vector proc lbl1 lbl2 bb context pcontext))
(define (proc-info-proc x) (vector-ref x 0))
(define (proc-info-lbl1 x) (vector-ref x 1))
(define (proc-info-lbl2 x) (vector-ref x 2))
(define (proc-info-bb x) (vector-ref x 3))
(define (proc-info-context x) (vector-ref x 4))
(define (proc-info-pcontext x) (vector-ref x 5))

;;;----------------------------------------------------------------------------

;; There are four reasons for generating an expression:

;; expression in tail position

(define (make-reason-tail)
  'tail)

(define (reason-tail? r)
  (eq? r 'tail))

;; expression is evaluated for side effect

(define (make-reason-side)
  'side)

(define (reason-side? r)
  (eq? r 'side))

;; expression's value is needed

(define (make-reason-need hint-loc)
  (vector hint-loc))

(define (reason-need? r)
  (and (vector? r) (= (vector-length r) 1)))

(define (reason-need-hint-loc r)
  (vector-ref r 0))

;; expression is used as a predicate in a conditional branch

(define (make-reason-pred true-live false-live)
  (vector true-live false-live))

(define (reason-pred? r)
  (and (vector? r) (= (vector-length r) 2)))

(define (reason-pred-true-live r)
  (vector-ref r 0))

(define (reason-pred-false-live r)
  (vector-ref r 1))

(define (reason-pred-invert r)
  (make-reason-pred
   (reason-pred-false-live r)
   (reason-pred-true-live r)))

(define (make-branchpoints true-context true-bb false-context false-bb)
  (vector true-context true-bb false-context false-bb))

(define (branchpoints-true-context bp)
  (vector-ref bp 0))

(define (branchpoints-true-bb bp)
  (vector-ref bp 1))

(define (branchpoints-false-context bp)
  (vector-ref bp 2))

(define (branchpoints-false-bb bp)
  (vector-ref bp 3))

(define (branchpoints-invert bp)
  (make-branchpoints
   (branchpoints-false-context bp)
   (branchpoints-false-bb bp)
   (branchpoints-true-context bp)
   (branchpoints-true-bb bp)))

;;;----------------------------------------------------------------------------

;;;; generate code for an expression

(define (gen-node node live reason)

  #;
  (begin
    (display "------------------ gen-node: ")
    (newline)
    (pp (parse-tree->expression node))
    (display "live: ")
    (pp (map var-name (varset->list live)))
    (display "regs  : ")
    (pp (map (lambda (x) (if (var? x) (var-name x) x)) regs))
    (display "slots : ")
    (pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
    (display "closed: ")
    (pp (map (lambda (x) (if (var? x) (var-name x) x)) closed))
    (display "reason: ")
    (pp (cond ((reason-tail? reason) 'tail)
              ((reason-need? reason) 'need)
              ((reason-side? reason) 'side)
              ((reason-pred? reason) 'pred)
              (else '???))))

  (cond ((cst? node)
         (gen-return node live reason (make-obj (cst-val node))))

        ((ref? node)
         (gen-return
           node
           live
           reason
           (if (reason-side? reason)
             (make-obj void-object)
             (let ((proc (global-proc-obj node)))
               (if proc
                 (make-obj proc)
                 (var->opnd (ref-var node)))))))

        ((set? node)
         (let* ((var (set-var node))
                (dst (make-glo (var-name var)))
                (src (gen-node (set-val node)
                               (varset-adjoin live var)
                               (make-reason-need dst))))
           (put-copy 3 src dst #f live (node->comment node))
           (gen-return node live reason (make-obj void-object))))

        ((def? node)
         (compiler-internal-error
           "gen-node, 'def' node not at root of parse tree"))

        ((tst? node)
         (gen-tst/switch node live reason))

        ((conj? node)
         (gen-conj/disj node live reason))

        ((disj? node)
         (gen-conj/disj node live reason))

        ((prc? node)
         (let* ((closed (not-constant-closed-vars node))
                (closed-list (sort-variables (varset->list closed)))
                (proc-info (schedule-gen-proc node closed-list))
                (proc-lbl (make-lbl (proc-info-lbl1 proc-info))))
           (let ((opnd
                  (if (null? closed-list)
                    (begin
                      (add-known-proc proc-info)
                      proc-lbl)
                    (begin
                      (shrink-slots
                       (stk-num
                        (highest-live-slot
                         (varset-union closed live))))
                      (push-slot)
                      (let ((slot (make-stk nb-slots))
                            (var (make-temp-var 'closure)))
                        (put-var slot var)
                        (zzzbb-put-non-branch! *bb* "IN gen-node"
                          (make-close
                            (list (make-closure-parms
                                    slot
                                    (lbl-num proc-lbl)
                                    (map var->opnd closed-list)))
                            (current-frame (varset-adjoin live var))
                            (node->comment node)))
                        slot)))))
             (gen-return node live reason opnd))))

        ((app? node)
         (gen-call node live reason))

        ((fut? node)
         (gen-fut node live reason))

        (else
         (compiler-internal-error
           "gen-node, unknown parse tree node type:" node))))

(define (gen-return node live reason opnd)
  (cond ((reason-tail? reason)
         (let ((var (make-temp-var 'result)))
           (put-copy 4 opnd
                     target.proc-result
                     var
                     ret-var-set
                     (node->comment node))
           (let ((ret-opnd (var->opnd ret-var)))
             (seal-bb (intrs-enabled? (node-env node)) 'return)
             (shrink-slots 0)
             (bb-put-branch! *bb*
               (make-jump ret-opnd
                          #f
                          #f
                          #f
                          (current-frame (varset-singleton var))
                          (node->comment node))))))
        ((reason-pred? reason)
         (if (obj? opnd)
           (let* ((false?
                   (false-object? (obj-val opnd)))
                  (dummy-lbl
                   (bbs-new-lbl! *bbs*))
                  (dummy-bb
                   (make-bb
                    (make-label-simple
                     dummy-lbl
                     (current-frame
                      (if false?
                        (reason-pred-false-live reason)
                        (reason-pred-true-live reason)))
                     (node->comment node))
                    *bbs*))
                  (context
                   (current-context)))
             (if false?
               (make-branchpoints context dummy-bb context *bb*)
               (make-branchpoints context *bb* context dummy-bb)))
           (branchpoints-invert
            (gen-conditional node
                             live
                             (reason-pred-invert reason)
                             **not-proc-obj
                             (list opnd)))))
        (else ; (or (reason-need? reason) (reason-side? reason))
         opnd)))

(define (gen-conditional node live reason test opnds)
  (let* ((true-lbl
          (bbs-new-lbl! *bbs*))
         (false-lbl
          (bbs-new-lbl! *bbs*))
         (true-bb
          (make-bb
           (make-label-simple
            true-lbl
            (current-frame (reason-pred-true-live reason))
            (node->comment node))
           *bbs*))
         (false-bb
          (make-bb
           (make-label-simple
            false-lbl
            (current-frame (reason-pred-false-live reason))
            (node->comment node))
           *bbs*)))
    (bb-put-branch! *bb*
      (make-ifjump
       test
       opnds
       true-lbl
       false-lbl
       #f
       (current-frame live)
       (node->comment node)))
    (let ((context (current-context)))
      (make-branchpoints context true-bb context false-bb))))

(define (not-constant-closed-vars val)
  (list->varset
   (keep not-constant-var? (varset->list (bound-free-variables val)))))

;;;----------------------------------------------------------------------------

;;;; generate code for a conditional

(define transform-to-case? #f)
(set! transform-to-case? #t)

(define min-cases-for-switch #f)
(set! min-cases-for-switch 4)

(define (gen-tst/switch node live reason)
  (if transform-to-case?
    (detect-case
     node
     (lambda (case-var branches nb-cases)
       (if (and (>= nb-cases min-cases-for-switch)
                (reason-tail? reason));;;;;;;;;;;;;;;;;;
         (gen-switch node live reason case-var branches)
         (gen-tst node live reason))))
    (gen-tst node live reason)))

(define (gen-switch node live reason case-var branches)
  (let* ((rev-branches
          (reverse branches))
         (rev-branch-nodes
          (map car rev-branches))
         (rev-branch-lbls
          (map (lambda (b) (bbs-new-lbl! *bbs*)) rev-branches))
         (default-branch-lbl
          (car rev-branch-lbls))
         (opnd
          (var->opnd case-var))
         (all-live
          (varset-union-multi
           (cons live
                 (map bound-free-variables rev-branch-nodes))))
         (frame
          (current-frame all-live)))

    (bb-put-branch! *bb*
      (make-switch
       opnd
       (let loop ((branches (cdr rev-branches))
                  (branch-lbls (cdr rev-branch-lbls))
                  (cases '()))
         (if (null? branches)
           cases
           (let* ((branch (car branches))
                  (lbl (car branch-lbls))
                  (objs (cdr branch)))
             (loop (cdr branches)
                   (cdr branch-lbls)
                   (append (map (lambda (obj)
                                  (make-switch-case obj lbl))
                                objs)
                           cases)))))
       default-branch-lbl
       #f
       frame
       (node->comment node)))

    (let ((context (current-context)))

      (for-each
       (lambda (branch-node branch-lbl)
         (restore-context context)
         (set! *bb* (make-bb (make-label-simple
                              branch-lbl
                              frame
                              (node->comment node))
                             *bbs*))
         (gen-node branch-node live reason))
       rev-branch-nodes
       rev-branch-lbls))))

(define (detect-case node cont)

  (define case-var #f)

  (define (try-ref-cst arg1 arg2)
    (and (ref? arg1)
         (cst? arg2)
         (let ((var (ref-var arg1))
               (val (cst-val arg2)))
           (and (bound? var)
                (target.switch-testable? val)
                (begin
                  (if (not case-var)
                    (set! case-var var))
                  (and (eq? case-var var)
                       (list val)))))))

  (define (extract-cases pre)
    (cond ((disj? pre)
           (let ((x1 (extract-cases (disj-pre pre))))
             (and x1
                  (let ((x2 (extract-cases (disj-alt pre))))
                    (and x2
                         (append x1 x2))))))
          ((app? pre)
           (let ((proc (app->specialized-proc pre))
                 (args (app-args pre)))
             (and (eq? proc **eq?-proc-obj)
                  (= (length args) 2)
                  (let ((arg1 (car args))
                        (arg2 (cadr args)))
                    (or (try-ref-cst arg1 arg2)
                        (try-ref-cst arg2 arg1))))))
          (else
           #f)))

  (define (extract-case node cont)
    (if (tst? node)
      (let ((pre (tst-pre node))
            (con (tst-con node))
            (alt (tst-alt node)))
        (let ((cs (extract-cases pre)))
          (if cs
            (extract-case
             alt
             (lambda (branches nb-cases)
               (cont (cons (cons con cs) branches)
                     (+ nb-cases (length cs)))))
            (cont (list (cons node #f)) 0))))
      (cont (list (cons node #f)) 0)))

  (extract-case node
                (lambda (branches nb-cases)
                  (cont case-var branches nb-cases))))

(define (gen-tst node live reason)

  (let ((pre (tst-pre node))
        (con (tst-con node))
        (alt (tst-alt node)))

    (let* ((con-fv
            (bound-free-variables con))
           (con-live
            (varset-union live con-fv))
           (alt-fv
            (bound-free-variables alt))
           (alt-live
            (varset-union live alt-fv))
           (after-pre-live
            (varset-union con-fv alt-live))
           (bp
            (gen-node
             pre
             after-pre-live
             (make-reason-pred
              con-live
              alt-live)))
           (true-context
            (branchpoints-true-context bp))
           (true-bb
            (branchpoints-true-bb bp))
           (false-context
            (branchpoints-false-context bp))
           (false-bb
            (branchpoints-false-bb bp)))

        (cond ((reason-tail? reason)
               (restore-context true-context)
               (set! *bb* true-bb)
               (gen-node con live reason)
               (restore-context false-context)
               (set! *bb* false-bb)
               (gen-node alt live reason))

              ((reason-pred? reason)
               (restore-context true-context)
               (set! *bb* true-bb)
               (let* ((con-bp
                       (gen-node con live reason))
                      (con-true-context
                       (branchpoints-true-context con-bp))
                      (con-true-bb
                       (branchpoints-true-bb con-bp))
                      (con-false-context
                       (branchpoints-false-context con-bp))
                      (con-false-bb
                       (branchpoints-false-bb con-bp)))
                 (restore-context false-context)
                 (set! *bb* false-bb)
                 (let* ((alt-bp
                         (gen-node alt live reason))
                        (alt-true-context
                         (branchpoints-true-context alt-bp))
                        (alt-true-bb
                         (branchpoints-true-bb alt-bp))
                        (alt-false-context
                         (branchpoints-false-context alt-bp))
                        (alt-false-bb
                         (branchpoints-false-bb alt-bp)))

                   (join-execution-paths
                    node
                    (reason-pred-true-live reason)
                    (list (cons con-true-context con-true-bb)
                          (cons alt-true-context alt-true-bb)))

                   (let ((result-true-context (current-context))
                         (result-true-bb *bb*))

                     (join-execution-paths
                      node
                      (reason-pred-false-live reason)
                      (list (cons con-false-context con-false-bb)
                            (cons alt-false-context alt-false-bb)))

                     (let ((result-false-context (current-context))
                           (result-false-bb *bb*))

                       (make-branchpoints
                        result-true-context
                        result-true-bb
                        result-false-context
                        result-false-bb))))))

              (else ; (or (reason-need? reason) (reason-side? reason))
               (restore-context true-context)
               (set! *bb* true-bb)
               (let* ((con-alt-reason
                       (if (reason-side? reason)
                         reason
                         (make-reason-need #f)))
                      (con-opnd
                       (gen-node con live con-alt-reason))
                      (loc
                       (cond ((reason-side? reason)
                              target.proc-result)
                             ((reg? con-opnd)
                              con-opnd)
                             (else
                              (or (let ((hint-loc
                                         (reason-need-hint-loc reason)))
                                    (and hint-loc
                                         (reg? hint-loc)
                                         hint-loc))
                                  (lowest-dead-reg live)
                                  target.proc-result))))
                      (result-var
                       (make-temp-var 'result)))

                 (if (not (reason-side? con-alt-reason))
                   (save-opnd-to-reg con-opnd
                                     loc
                                     result-var
                                     live
                                     (node->comment con)))

                 (let ((con-context (current-context))
                       (con-bb *bb*))

                   (restore-context false-context)
                   (set! *bb* false-bb)

                   (let ((alt-opnd (gen-node alt live con-alt-reason)))

                     (if (not (reason-side? con-alt-reason))
                       (save-opnd-to-reg alt-opnd
                                         loc
                                         result-var
                                         live
                                         (node->comment alt)))

                     (let ((alt-context (current-context))
                           (alt-bb *bb*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                      (let ()
                        (##namespace ("" with-output-to-string pp))
                        (pp (list (parse-tree->expression node)
                                  LIVE:
                                  (map var-name (varset->list live))
                                  (list
                                   RT:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs true-context))
                                   ST:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots true-context)))
                                  (list
                                   R1:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs con-context))
                                   S1:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots con-context)))
                                  (list
                                   RF:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs false-context))
                                   SF:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots false-context)))
                                  (list
                                   R2:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs alt-context))
                                   S2:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots alt-context))))))

                       (join-execution-paths
                        node
                        (if (reason-side? con-alt-reason)
                          live
                          (varset-adjoin live result-var))
                        (list (cons con-context con-bb)
                              (cons alt-context alt-bb)))

                       loc)))))))))

(define (join-execution-paths node live context-bb-list)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
  (define (order context-bb1 context-bb2)

    ; order the contexts so that the first is the one with the most
    ; live variables in registers.

    (define (nb-live-vars lst)
      (let ((live-v (live-vars live)))
        (let loop ((lst lst)
                   (vars (varset-empty)))
          (if (pair? lst)
            (let ((v (car lst)))
              (if (and v (varset-member? v live-v))
                (loop (cdr lst)
                      (varset-adjoin vars v))
                (loop (cdr lst)
                      vars)))
            (length (varset->list vars))))))

    (let* ((context1 (car context-bb1))
           (context2 (car context-bb2))
           (nb-live1 (nb-live-vars (context-regs context1)))
           (nb-live2 (nb-live-vars (context-regs context2))))
      (>= nb-live1 nb-live2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (define (order context-bb1 context-bb2)
    (let* ((context1 (car context-bb1))
           (context2 (car context-bb2))
           (nb-slots1 (context-nb-slots context1))
           (nb-slots2 (context-nb-slots context2)))
      (> nb-slots1 nb-slots2)))

  (let ((ordered-context-bb-vector
         (list->vector
          (sort-list context-bb-list order))))

    (define (join-range start end)
      (if (= start end)
        (vector-ref ordered-context-bb-vector start)
        (let* ((mid (quotient (+ start end) 2))
               (context-bb1 (join-range start mid))
               (context-bb2 (join-range mid end)))
          (join-execution-paths-aux
           node
           live
           (car context-bb1)
           (cdr context-bb1)
           (car context-bb2)
           (cdr context-bb2))
          (cons (current-context)
                *bb*))))

    (join2 node
           live
           (car (vector-ref ordered-context-bb-vector 0))
           (cdr (vector-ref ordered-context-bb-vector 0))
           (car (vector-ref ordered-context-bb-vector 1))
           (cdr (vector-ref ordered-context-bb-vector 1)))))

(define (join2 node live context1 bb1 context2 bb2)

  ; order the contexts so that the first is the one with the most
  ; live variables in registers.

    (define (nb-live-vars lst)
      (let ((live-v (live-vars live)))
        (let loop ((lst lst)
                   (vars (varset-empty)))
          (if (pair? lst)
            (let ((v (car lst)))
              (if (and v (varset-member? v live-v))
                (loop (cdr lst)
                      (varset-adjoin vars v))
                (loop (cdr lst)
                      vars)))
            (length (varset->list vars))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (if (> (context-nb-slots context1)
         (context-nb-slots context2))
;;  (if (>= (nb-live-vars (context-regs context1))
;;          (nb-live-vars (context-regs context2)))
    (join-execution-paths-aux2 node live context1 bb1 context2 bb2)
    (join-execution-paths-aux2 node live context2 bb2 context1 bb1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
  (if (> (context-nb-slots context1)
         (context-nb-slots context2))
    (join-execution-paths-aux node live context1 bb1 context2 bb2)
    (join-execution-paths-aux node live context2 bb2 context1 bb1)))

(define (join-execution-paths-aux node live context1 bb1 context2 bb2)
  (restore-context context2)
  (set! *bb* bb2)
  (seal-bb (intrs-enabled? (node-env node)) 'internal)
  (let ((join-lbl (bbs-new-lbl! *bbs*)))
    (bb-put-branch! *bb*
      (make-jump (make-lbl join-lbl)
                 #f
                 #f
                 #f
                 (current-frame live)
                 (node->comment node)))
    (let ((context2* (current-context)))
      (restore-context context1)
      (set! *bb* bb1)
      (merge-contexts-and-seal-bb
       context2*
       live
       (intrs-enabled? (node-env node))
       'internal
       (node->comment node))
      (bb-put-branch! *bb*
        (make-jump (make-lbl join-lbl)
                   #f
                   #f
                   #f
                   (current-frame live)
                   (node->comment node)))
      (set! *bb* (make-bb
                  (make-label-simple
                   join-lbl
                   (current-frame live)
                   (node->comment node))
                  *bbs*)))))

(define (join-execution-paths-aux2 node live context1 bb1 context2 bb2)
  (let ((live-v (live-vars live)))

    (define (common lst1 lst2 common-vars)
      (let loop ((lst1 lst1)
                 (lst2 lst2)
                 (common-vars common-vars))
        (if (and (pair? lst1) (pair? lst2))
          (let* ((v1 (car lst1))
                 (v2 (car lst2))
                 (r1 (cdr lst1))
                 (r2 (cdr lst2)))
            (if (and (not (eq? v1 empty-var))
                     (not (eq? v2 empty-var))
                     (eq? v1 v2)
                     (varset-member? v1 live-v))
              (loop r1
                    r2
                    (varset-adjoin common-vars v1))
              (loop r1
                    r2
                    common-vars)))
          common-vars)))

    (define (displace lst1 lst2 n vars-in-new-context cont)
      (let loop ((lst1 lst1)
                 (lst2 lst2)
                 (vars-in-new-context vars-in-new-context)
                 (rev-lst '())
                 (i 0))
        (if (< i n)
          (let* ((v1 (if (pair? lst1) (car lst1) empty-var))
                 (v2 (if (pair? lst2) (car lst2) empty-var))
                 (r1 (if (pair? lst1) (cdr lst1) '()))
                 (r2 (if (pair? lst2) (cdr lst2) '())))
            (if (and (not (eq? v1 empty-var))
                     (not (eq? v2 empty-var))
                     (eq? v1 v2)
                     (varset-member? v1 live-v))
              (loop r1
                    r2
                    vars-in-new-context ; v1 is already in vars-in-new-context
                    (cons v1 rev-lst)
                    (+ i 1))
              (let* ((var1
                      (and (not (eq? v1 empty-var))
                           (varset-member? v1 live-v)
                           (not (varset-member? v1 vars-in-new-context))
                           v1))
                     (var2
                      (and (not (eq? v2 empty-var))
                           (varset-member? v2 live-v)
                           (not (varset-member? v2 vars-in-new-context))
                           v2)))
                (cond (var1
                       (loop r1
                             r2
                             (varset-adjoin vars-in-new-context var1)
                             (cons var1 rev-lst)
                             (+ i 1)))
                      (var2
                       (loop r1
                             r2
                             (varset-adjoin vars-in-new-context var2)
                             (cons var2 rev-lst)
                             (+ i 1)))
                      (else
                       (loop r1
                             r2
                             vars-in-new-context
                             (cons empty-var rev-lst)
                             (+ i 1)))))))
          (cont vars-in-new-context
                rev-lst))))

    (define (unused-slots slots)
      (if (and (pair? slots)
               (eq? (car slots) empty-var))
        (+ 1 (unused-slots (cdr slots)))
        0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
    (let ()
      (##namespace ("" pp))
      (pp (list
           'CONTEXT1
           (list
            R:
            (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs context1))
            S:
            (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots context1))))))
#;
    (let ()
      (##namespace ("" pp))
      (pp (list
           'CONTEXT2
           (list
            R:
            (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs context2))
            S:
            (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots context2))))))


    (let* ((regs1
            (context-regs context1))
           (rev-slots1
            (reverse (context-slots context1)))
           (regs2
            (context-regs context2))
           (rev-slots2
            (reverse (context-slots context2)))
           (common-vars
            (common
             rev-slots1
             rev-slots2
             (common
              regs1
              regs2
              (varset-empty))))
           (min-nb-slots
            (min (context-nb-slots context1)
                 (context-nb-slots context2)))
           (max-nb-slots
            (max (context-nb-slots context1)
                 (context-nb-slots context2))))

      (displace
       regs1
       regs2
       target.nb-regs
       common-vars
       (lambda (vars-in-new-context rev-new-regs)
         (let ((new-regs (reverse rev-new-regs)))
           (displace
            rev-slots1
            rev-slots2
            max-nb-slots
            vars-in-new-context
            (lambda (vars-in-new-context new-slots)
              (let* ((new-regs
                      (reverse rev-new-regs))
                     (new-nb-slots
                      (max min-nb-slots
                           (- max-nb-slots
                              (unused-slots new-slots))))
                     (new-context
                      (make-context new-nb-slots
                                    (drop new-slots
                                          (- max-nb-slots new-nb-slots))
                                    new-regs
                                    (context-closed context1)
                                    (poll-merge
                                     (context-poll context1)
                                     (context-poll context2))
                                    (context-entry-bb context1)))
                     (new-frame
                      (context->frame new-context live))
                     (join-lbl
                      (bbs-new-lbl! *bbs*)))

                (define (join context bb)
                  (restore-context context)
                  (set! *bb* bb)

                  (let* ((nb-locs (+ 1 (+ target.nb-regs max-nb-slots)))
                         (from (make-vector nb-locs #f))
                         (to (make-vector nb-locs #f)))

                    (define (from-to i j)
                      (vector-set! from i j)
                      (vector-set! to j i))

                    (define (location var)
                      (or (pos-in-list var regs)
                          (let ((n (pos-in-list var slots)))
                            (if n
                              (+ target.nb-regs (- nb-slots (+ n 1)))
                              (compiler-internal-error
                               "join-execution-paths-aux2, unknown location")))))

                    (define (find-loc kind start end)
                      (let loop ((i start))
                        (if (< i end)
                          (if (eq? kind (vector-ref to i))
                            i
                            (loop (+ i 1)))
                          #f)))

                    (let loop1 ((lst new-regs)
                                (i 0))
                      (if (pair? lst)
                        (let ((new-v (car lst)))
                          (if (not (eq? new-v empty-var))
                            (from-to
                             i
                             (if (eq? new-v (reg->var regs i))
                               i
                               (location new-v))))
                          (loop1 (cdr lst)
                                 (+ i 1)))))

                    (let loop2 ((lst (reverse new-slots))
                                (i 0))
                      (if (pair? lst)
                        (let ((new-v (car lst)))
                          (if (not (eq? new-v empty-var))
                            (from-to
                             (+ target.nb-regs i)
                             (if (eq? new-v (stk->var regs (+ i 1)))
                               (+ target.nb-regs i)
                               (location new-v))))
                          (loop2 (cdr lst)
                                 (+ i 1)))))

                    (let* ((chains
                            (let loop3 ((i 0) (chains '()))

                              (define (build-chain i)
                                (if i
                                  (let ((next (vector-ref from i)))
                                    (vector-set! from i #f)
                                    (vector-set! to i 'chain)
                                    (cons i (build-chain next)))
                                  '()))

                              (if (< i nb-locs)
                                (loop3 (+ i 1)
                                       (if (and (vector-ref from i)
                                                (not (vector-ref to i)))
                                         (cons (build-chain i)
                                               chains)
                                         chains))
                                chains)))
                           (cycles
                            (let loop4 ((i 0) (cycles '()))

                              (define (build-cycle i)
                                (cons i
                                      (let ((next (vector-ref from i)))
                                        (vector-set! from i #f)
                                        (vector-set! to i 'cycle)
                                        (if (vector-ref from next)
                                          (build-cycle next)
                                          '()))))

                              (if (< i nb-locs)
                                (loop4 (+ i 1)
                                       (if (and (vector-ref from i)
                                                (not (= (vector-ref from i)
                                                        i)))
                                         (cons (build-cycle i)
                                               cycles)
                                         cycles))
                                cycles)))
                           (temp
                            (if (null? cycles)
                              #f
                              (or (find-loc 'chain 0 target.nb-regs)
                                  (find-loc #f 0 target.nb-regs)
                                  (find-loc 'chain target.nb-regs nb-locs)
                                  (find-loc #f target.nb-regs nb-locs))))
                           (output '()));;;;;;;;;;;;;;;;;;;;

                      (define (loc->opnd loc)
                        (if (< loc target.nb-regs)
                          (make-reg loc)
                          (make-stk (+ 1 (- loc target.nb-regs)))))

                      (define (copy src dst)
                        (let ((s (loc->opnd src))
                              (d (loc->opnd dst))
                              (comment (node->comment node)))
                          (if (and (stk? d) (> (stk-num d) nb-slots))
                            (begin
                              (extend-slots (- (stk-num d) 1) live comment)
                              (push-slot)))
                          (put-var d (get-var s))

                          (set! output (cons (list dst '<- src) output))

                          (zzzbb-put-non-branch! *bb* "IN join-execution-paths-aux2"
                            (make-copy s
                                       d
                                       (current-frame live)
                                       comment))))

                      (define (do-cycles)
                        (for-each
                         (lambda (cycle)
                           (let ((dst1 (car cycle)))
                             (copy dst1 temp)
                             (let loop ((dst dst1)
                                        (rest (cdr cycle)))
                               (if (pair? rest)
                                 (let ((src (car rest)))
                                   (copy src dst)
                                   (loop src (cdr rest)))
                                 (copy temp dst)))))
                         cycles)
                        (set! temp #f))

                      (define (do-chains)
                        (for-each
                         (lambda (chain)
                           (let ((dst1 (car chain)))
                             (let loop ((dst dst1)
                                        (rest (cdr chain)))
                               (if (eqv? dst temp)
                                 (do-cycles))
                               (if (pair? rest)
                                 (let ((src (car rest)))
                                   (copy src dst)
                                   (loop src (cdr rest)))))))
                         chains))

                      (do-chains)
                      (if temp (do-cycles))

                      (adjust-slots new-nb-slots
                                    live
                                    (node->comment node))

                      (seal-bb (intrs-enabled? (node-env node)) 'internal)

                      (bb-put-branch! *bb*
                        (make-jump (make-lbl join-lbl)
                                   #f
                                   #f
                                   #f
                                   new-frame
                                   (node->comment node)))

                      (cons (current-context) *bb*))))

                (let* ((c1 (join context1 bb1))
                       (c2 (join context2 bb2)))

                  (restore-context new-context)

                  (set! *bb* (make-bb
                              (make-label-simple
                               join-lbl
                               new-frame
                               (node->comment node))
                              *bbs*))

;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                      (let ()
                        (##namespace ("" pp))
                        (pp (list
                             'EXIT
                             (list
                              R:
                              (map (lambda (x) (if (var? x) (var-name x) x)) regs)
                              S:
                              (map (lambda (x) (if (var? x) (var-name x) x)) slots)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
'
                  (let* ((context1 (car c1))
                         (bb1 (cdr c1))
                         (context2 (car c2))
                         (bb2 (cdr c2)))
                    (if (> (context-nb-slots context1)
                           (context-nb-slots context2))
                      (join-execution-paths-aux node live context1 bb1 context2 bb2)
                      (join-execution-paths-aux node live context2 bb2 context1 bb1)))))))))))))

;; 'merge-contexts-and-seal-bb' generates code to transform the current
;; context (i.e. reg and stack values and frame size) to 'other-context' only
;; considering the variables in 'live'.

(define (merge-contexts-and-seal-bb other-context live poll? where comment)
;(display "*************")(newline);*************
;(display "1 regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs))
;(display "1 slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
;(display "2 regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) (context-regs other-context)))
;(display "2 slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) (context-slots other-context)))
  (let ((live-v (live-vars live))
        (other-nb-slots (context-nb-slots other-context))
        (other-regs (context-regs other-context))
        (other-slots (context-slots other-context))
        (other-poll (context-poll other-context))
        (other-entry-bb (context-entry-bb other-context)))

    (let loop1 ((i (- target.nb-regs 1)))
;(display "r regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs));*************
;(display "r slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
      (if (>= i 0)

        (let ((other-var (reg->var other-regs i)) ; #f if no var
              (var (reg->var regs i)))            ; #f if no var
          (if (and other-var
                   (not (eq? var other-var)) ; if var not there and must keep
                   (varset-member? other-var live-v)) ; other-var somewhere
            (let ((r (make-reg i)))
              (put-var r empty-var)
              (if (and var
                       (varset-member? var live-v) ; register's value is needed
                       (not (memq var regs))       ; and not in any other
                       (not (memq var slots)))     ; register or stack slot
                (let ((top (make-stk (+ nb-slots 1)))) ; save on top of stack
                  (put-copy 5 r top var live-v comment)))
              (put-copy 6 (var->opnd other-var) r other-var live-v comment)))
          (loop1 (- i 1)))))

    (let loop2 ((i 1))
;(display "s regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs));*************
;(display "s slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
      (if (<= i other-nb-slots)

        (let ((other-var (stk->var other-slots i)) ; #f if no var
              (var (stk->var slots i)))            ; #f if no var
          (if (and other-var
                   (not (eq? var other-var)) ; if var not there and must keep
                   (varset-member? other-var live-v)) ; other-var somewhere
            (let ((s (make-stk i)))
              (if (<= i nb-slots) (put-var s empty-var))
;(display "S regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs));*************
;(display "S slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
              (if (and var
                       (varset-member? var live-v) ; slot's value is needed
                       (not (memq var regs))       ; and not in any other
                       (not (memq var slots)))     ; register or stack slot
                (let ((top (make-stk (+ nb-slots 1)))) ; save on top of stack
                  (put-copy 7 s top var live-v comment)))
;(display "Z regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs));*************
;(display "Z slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))
              (put-copy 8 (var->opnd other-var) s other-var live-v comment))
            (if (> i nb-slots)
              (let ((top (make-stk (+ nb-slots 1))))
                (put-copy 9 (make-obj void-object)
                          top
                          empty-var
                          live-v
                          comment))))
          (loop2 (+ i 1)))))

    ; It is OK to shrink because other-nb-slots <= nb-slots
    (shrink-slots other-nb-slots)

    (let loop3 ((i (- target.nb-regs 1)))
      (if (>= i 0)

        (let ((other-var (reg->var other-regs i)) ; #f if no var
              (var (reg->var regs i)))            ; #f if no var
          (if (not (eq? var other-var))
            (put-var (make-reg i) empty-var))
          (loop3 (- i 1)))))

    (let loop4 ((i 1))
      (if (<= i other-nb-slots)

        (let ((other-var (stk->var other-slots i)) ; #f if no var
              (var (stk->var slots i)))            ; #f if no var
          (if (not (eq? var other-var))
            (put-var (make-stk i) empty-var))
          (loop4 (+ i 1)))))

    (seal-bb poll? where)

    (set! poll (poll-merge poll other-poll))

;(display "3 regs  : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) regs));*************
;(display "3 slots : ")(pp (map (lambda (x) (if (var? x) (var-name x) x)) slots))

    (if (not (eq? entry-bb other-entry-bb))
      (compiler-internal-error
        "merge-contexts-and-seal-bb, entry-bb's do not agree"))))

(define (seal-bb poll? where)

  (define (last-pair l)
    (if (pair? (cdr l)) (last-pair (cdr l)) l))

  (define (poll-at split-point)
    (let loop ((i 0) (l1 (bb-non-branch-instrs *bb*)) (l2 '()))
      (if (< i split-point)
        (loop (+ i 1) (cdr l1) (cons (car l1) l2))
        (let* ((label-instr
                (bb-label-instr *bb*))
               (non-branch-instrs1
                (reverse l2))
               (non-branch-instrs2
                l1)
               (last-instr
                (car (last-pair (cons label-instr non-branch-instrs1))))
               (frame
                (gvm-instr-frame last-instr))
               (new-lbl
                (bbs-new-lbl! *bbs*)))
          (bb-non-branch-instrs-set! *bb* non-branch-instrs1)
          (bb-put-branch! *bb*
            (make-jump (make-lbl new-lbl)
                       #f
                       #t
                       #f
                       frame
                       (gvm-instr-comment last-instr)))
          (set! *bb* (make-bb (make-label-simple
                               new-lbl
                               frame
                               (gvm-instr-comment last-instr))
                              *bbs*))
          (bb-non-branch-instrs-set! *bb* non-branch-instrs2)
          (set! poll (make-poll #t 0))))))

  (define (poll-at-end)
    (poll-at (length (bb-non-branch-instrs *bb*))))

  (define (impose-polling-constraints)
    (let ((n (+ (length (bb-non-branch-instrs *bb*)) 1))
          (delta (poll-delta poll)))
      (if (> (+ delta n) poll-period)
        (begin
          (poll-at (max (- poll-period delta) 0))
          (impose-polling-constraints)))))

  (if poll? (impose-polling-constraints))

  (let* ((n (+ (length (bb-non-branch-instrs *bb*)) 1))
         (delta (+ (poll-delta poll) n))
         (since-entry? (poll-since-entry? poll)))
    (if (and poll?
             (case where
               ((call)
                (> delta (- poll-period poll-head)))
               ((tail-call)
                (> delta poll-tail))
               ((return)
                (and since-entry? (> delta (+ poll-head poll-tail))))
               ((internal)
                #f)
               (else
                (compiler-internal-error "seal-bb, unknown 'where':" where))))
      (poll-at-end)
      (set! poll (make-poll since-entry? delta)))))

(define (reg->var regs i)
  (cond ((null? regs)
         #f)
        ((> i 0)
         (reg->var (cdr regs) (- i 1)))
        (else
         (car regs))))

(define (stk->var slots i)
  (let ((j (- (length slots) i)))
    (if (< j 0)
      #f
      (list-ref slots j))))

;;;----------------------------------------------------------------------------
;;
;; generate code for a conjunction or disjunction

(define (gen-conj/disj node live reason)
  (let ((is-conj? (conj? node)))

    (define (gen-node* node live reason)
      (if is-conj?
        (gen-node node live reason)
        (branchpoints-invert
         (gen-node node live (reason-pred-invert reason)))))

    (define (gen-conj/disj-pred pre alt live reason)
      (let* ((alt-fv
              (bound-free-variables alt))
             (alt-live
              (varset-union live alt-fv))
             (bp
              (gen-node*
               pre
               alt-live
               (make-reason-pred
                alt-live
                (reason-pred-false-live reason))))
             (true-context
              (branchpoints-true-context bp))
             (true-bb
              (branchpoints-true-bb bp))
             (false-context
              (branchpoints-false-context bp))
             (false-bb
              (branchpoints-false-bb bp)))

        (restore-context true-context)
        (set! *bb* true-bb)
        (let* ((alt-bp
                (gen-node* alt live reason))
               (alt-true-context
                (branchpoints-true-context alt-bp))
               (alt-true-bb
                (branchpoints-true-bb alt-bp))
               (alt-false-context
                (branchpoints-false-context alt-bp))
               (alt-false-bb
                (branchpoints-false-bb alt-bp)))

          (join-execution-paths
           node
           (reason-pred-false-live reason)
           (list (cons false-context false-bb)
                 (cons alt-false-context alt-false-bb)))

          (make-branchpoints
           alt-true-context
           alt-true-bb
           (current-context)
           *bb*))))

    (define (gen-conj/disj-value pre alt live reason)
      (let ((result-var (make-temp-var 'result)))

        (define (gen-node-value* node live reason)
          (if is-conj?
            (gen-node-value node live reason)
            (branchpoints-invert
             (gen-node-value node live (reason-pred-invert reason)))))

        (define (gen-node-value node live reason)
          (save-opnd-to-reg (gen-node node
                                      live
                                      (make-reason-need
                                       target.proc-result))
                            target.proc-result
                            result-var
                            live
                            (node->comment node))
          (seal-bb (intrs-enabled? (node-env node)) 'internal)
          (let* ((true-lbl
                  (bbs-new-lbl! *bbs*))
                 (false-lbl
                  (bbs-new-lbl! *bbs*))
                 (true-bb
                  (make-bb
                   (make-label-simple
                    true-lbl
                    (current-frame (reason-pred-true-live reason))
                    (node->comment node))
                   *bbs*))
                 (false-bb
                  (make-bb
                   (make-label-simple
                    false-lbl
                    (current-frame (reason-pred-false-live reason))
                    (node->comment node))
                   *bbs*)))
            (bb-put-branch! *bb*
              (make-ifjump
               **not-proc-obj
               (list target.proc-result)
               false-lbl
               true-lbl
               #f
               (current-frame (varset-adjoin live result-var))
               (node->comment node)))
            (let ((context (current-context)))
              (make-branchpoints context true-bb context false-bb))))

        (let* ((bool-pre?
                (boolean-value? pre))
               (alt-fv
                (bound-free-variables alt))
               (alt-live
                (varset-union live alt-fv))
               (bp
                (if bool-pre?
                  (gen-node*
                   pre
                   alt-live
                   (make-reason-pred
                    alt-live
                    live))
                  (gen-node-value*
                   pre
                   alt-live
                   (make-reason-pred
                    alt-live
                    (varset-adjoin live result-var)))))
               (true-context
                (branchpoints-true-context bp))
               (true-bb
                (branchpoints-true-bb bp))
               (false-context
                (branchpoints-false-context bp))
               (false-bb
                (branchpoints-false-bb bp)))

          (restore-context true-context)
          (set! *bb* true-bb)

          (let ((alt-opnd (gen-node alt live reason)))

            (if (and (not (reason-tail? reason))
                     (not (reason-side? reason)))
              (save-opnd-to-reg alt-opnd
                                target.proc-result
                                result-var
                                live
                                (node->comment alt)))

            (let ((alt-context (current-context))
                  (alt-bb *bb*))

              (restore-context false-context)
              (set! *bb* false-bb)

              (if (and bool-pre?
                       (not (reason-side? reason)))
                (save-opnd-to-reg (make-obj (if is-conj? false-object #t))
                                  target.proc-result
                                  result-var
                                  live
                                  (node->comment node)))

              (if (reason-tail? reason)
                (gen-return node live reason target.proc-result)
                (begin
                  (join-execution-paths
                   node
                   (if (reason-side? reason)
                     live
                     (varset-adjoin live result-var))
                   (list (cons (current-context) *bb*)
                         (cons alt-context alt-bb)))
                  target.proc-result)))))))

    (if (reason-pred? reason)

      (if is-conj?
        (gen-conj/disj-pred
         (conj-pre node)
         (conj-alt node)
         live
         reason)
        (branchpoints-invert
         (gen-conj/disj-pred
          (disj-pre node)
          (disj-alt node)
          live
          (reason-pred-invert reason))))

      (if is-conj?
        (gen-conj/disj-value
         (conj-pre node)
         (conj-alt node)
         live
         reason)
        (gen-conj/disj-value
         (disj-pre node)
         (disj-alt node)
         live
         reason)))))

;;;----------------------------------------------------------------------------
;;
;; generate code for a procedure call

(define (gen-call node live reason)
  (let* ((oper (app-oper node))
         (args (app-args node))
         (nb-args (length args)))

    (if (and (prc? oper) ; applying a lambda-expr is like a 'let' or 'letrec'
             (prc-req-and-opt-parms-only? oper)
             (= (length (prc-parms oper)) nb-args))

      (gen-let oper args live reason)

      (let ((proc (app->specialized-proc node)))
        (if (and proc
                 (or ((proc-obj-inlinable? proc) (node-env node))
                     (and (reason-pred? reason)
                          ((proc-obj-testable? proc) (node-env node)))))

          (if (and (reason-pred? reason)
                   (eq? proc **not-proc-obj))

            (branchpoints-invert
             (gen-node (car args)
                       live
                       (reason-pred-invert reason)))

            (let ((eval-order (arg-eval-order #f args))
                  (vars (map (lambda (x) (cons x #f)) args)))

              (let loop ((l eval-order) (liv live))
                (if (not (null? l))

                  (let* ((needed (vals-live-vars liv (map car (cdr l))))
                         (arg (car (car l)))
                         (pos (cdr (car l)))
                         (var
                          (save-var (gen-node arg
                                              needed
                                              (make-reason-need #f))
                                    (make-temp-var pos)
                                    needed
                                    (node->comment arg))))
                    (set-cdr! (assq arg vars) var)
                    (loop (cdr l) (varset-adjoin liv var)))

                  (if (and (reason-pred? reason)
                           ((proc-obj-testable? proc) (node-env node)))

                    (let ((args (map var->opnd (map cdr vars))))
                      (gen-conditional node live reason proc args))

                    (let ((loc
                           (if (reason-side? reason)
                             target.proc-result
                             (or (and (reason-need? reason)
                                      (let ((hint-loc
                                             (reason-need-hint-loc reason)))
                                        (and hint-loc
                                             (dead-reg/stk? hint-loc live)
                                             hint-loc)))
                                 (lowest-dead-reg live)
                                 (lowest-dead-slot live)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                      (let ()
                        (##namespace ("" with-output-to-string pp))
                        (pp (list (parse-tree->expression node)
                                  (map var-name (varset->list live))
                                  (with-output-to-string "" (lambda () (write-gvm-opnd loc (current-output-port))))
                                  (with-output-to-string "" (lambda () (write-gvm-opnd (lowest-dead-reg live) (current-output-port))))
                                  regs:
                                  (map (lambda (x) (if (var? x) (var-name x) x)) regs)
                                  slots:
                                  (map (lambda (x) (if (var? x) (var-name x) x)) slots)

)))

                      (if (and (not (reason-side? reason))
                               (stk? loc)
                               (> (stk-num loc) nb-slots))
                        (begin
                          (extend-slots (- (stk-num loc) 1)
                                        live
                                        (node->comment node))
                          (push-slot)))

                      (let* ((args (map var->opnd (map cdr vars)))
                             (var (make-temp-var 'result)))
                        (if (not (reason-side? reason))
                          (put-var loc var))
                        (zzzbb-put-non-branch! *bb* "IN gen-call"
                          (make-apply
                           proc
                           args
                           (if (reason-side? reason) #f loc)
                           (current-frame
                            (if (reason-side? reason)
                              live
                              (varset-adjoin live var)))
                           (node->comment node)))
                        (gen-return node live reason loc))))))))

          (let* ((reason2
                  (if (and (reason-tail? reason)
                           (not (proper-tail-calls? (node-env node))))
                      (make-reason-need target.proc-result)
                      reason))
                 (local-proc-info
                  (and (ref? oper)
                       (let ((opnd (var->opnd (ref-var oper))))
                         (and (lbl? opnd)
                              (let ((x (assq (lbl-num opnd) known-procs)))
                                (and x
                                     (let* ((proc-info (cdr x))
                                            (proc (proc-info-proc proc-info)))
                                       (and (prc-req-and-opt-parms-only? proc)
                                            (= (length (prc-parms proc))
                                               nb-args)
                                            proc-info))))))))
                 (jstate
                   (if local-proc-info
                     (proc-info->jump-state local-proc-info args)
                     (args->jump-state args)))
                 (in-stk
                  (jump-state-in-stk jstate))
                 (in-reg
                  (jump-state-in-reg jstate))
                 (eval-order
                  (arg-eval-order
                   (if (or local-proc-info proc) #f oper)
                   in-reg))
                 (live-after
                  (if (reason-tail? reason2)
                    (varset-empty)
                    live))
                 (live-vars-at-each-reg
                  (compute-live-vars-at-each-expr
                   live-after
                   (map car eval-order)
                   (make-reason-tail)))
                 (return-lbl
                  (if (reason-tail? reason2) #f (bbs-new-lbl! *bbs*)))
                 (live-vars-at-each-slot
                  (compute-live-vars-at-each-expr
                   (car live-vars-at-each-reg)
                   in-stk
                   reason2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                      (let ()
                        (##namespace ("" with-output-to-string pp))
                        (pp (list (parse-tree->expression node)
                                  LIVE1:
                                  (map var-name (varset->list live))
                                  (list
                                   R:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) regs)
                                   S: nb-slots
                                   (map (lambda (x) (if (var? x) (var-name x) x)) slots)))))


            ; save regs on stack if they contain values needed after the call
            (save-regs-to-stk (live-regs live-after)
                              (car live-vars-at-each-slot)
                              (node->comment node))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                      (let ()
                        (##namespace ("" with-output-to-string pp))
                        (pp (list (parse-tree->expression node)
                                  LIVE2:
                                  (map var-name (varset->list live))
                                  (list
                                   R:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) regs)
                                   S: nb-slots
                                   (map (lambda (x) (if (var? x) (var-name x) x)) slots)))))


            (let* ((top-live-slot
                    (stk-num (highest-live-slot live-after)))
                   (frame-start
                    (if (reason-tail? reason2)
                      top-live-slot
                      (let ((frame-reserve
                             (frame-constraints-reserve
                              target.frame-constraints))
                            (frame-align
                             (frame-constraints-align
                              target.frame-constraints)))
                        (* (quotient (+ (+ top-live-slot frame-reserve)
                                        (- frame-align 1))
                                     frame-align)
                           frame-align)))))

              (let loop1 ((l
                           in-stk)
                          (liv
                           live-after)
                          (live-vars-at-next-slots
                           (cdr live-vars-at-each-slot))
                          (i
                           (+ frame-start 1)))
                (if (not (null? l))

                  ; ==== FIRST: evaluate arguments that go onto stack

                  (let ((arg (car l))
                        (slot (make-stk i))
                        (needed (varset-union liv
                                              (car live-vars-at-next-slots))))
                    (if arg

                      (if (and (ref? arg)
                               (<= i nb-slots)
                               (eq? (ref-var arg) (get-var slot)))
                        (loop1 (cdr l)
                               (varset-adjoin liv (ref-var arg))
                               (cdr live-vars-at-next-slots)
                               (+ i 1))
                        (let ((var (if (and (eq? arg 'return)
                                            (reason-tail? reason2))
                                     ret-var
                                     (make-temp-var (- frame-start i)))))

                          (save-opnd-to-stk (if (eq? arg 'return)
                                              (if (reason-tail? reason2)
                                                (var->opnd ret-var)
                                                (make-lbl return-lbl))
                                              (gen-node arg
                                                        needed
                                                        (make-reason-need
                                                         slot)))
                                            slot
                                            var
                                            needed
                                            (node->comment
                                             (if (eq? arg 'return)
                                               node
                                               arg)))
                          (loop1 (cdr l)
                                 (varset-adjoin liv var)
                                 (cdr live-vars-at-next-slots)
                                 (+ i 1))))

                      (begin
                        (if (> i nb-slots)
                          (put-copy 10 (make-obj void-object)
                                    slot
                                    empty-var
                                    liv
                                    (node->comment node)))
                        (loop1 (cdr l)
                               liv
                               (cdr live-vars-at-next-slots)
                               (+ i 1)))))

                  (let ((reg-map (make-stretchable-vector #f)))
                    (let loop2 ((l
                                 eval-order)
                                (liv
                                 liv)
                                (live-vars-at-next-regs
                                 (cdr live-vars-at-each-reg))
                                (oper-var
                                 '()))
                      (if (not (null? l))

                        ; ==== SECOND: evaluate operator and args that go in registers

                        (let* ((arg (car (car l)))
                               (pos (cdr (car l)))
                               (needed
                                (varset-union liv (car live-vars-at-next-regs)))
                               (var (if (and (eq? arg 'return)
                                             (reason-tail? reason2))
                                      ret-var
                                      (make-temp-var pos)))
                               (opnd (if (eq? arg 'return)
                                       (if (reason-tail? reason2)
                                         (var->opnd ret-var)
                                         (make-lbl return-lbl))
                                       (gen-node arg
                                                 needed
                                                 (make-reason-need
                                                  (if (eq? pos 'operator)
                                                    #f
                                                    (make-reg pos)))))))

                          (if (eq? pos 'operator)

                            ; operator

                            (if (and (ref? arg)
                                     (not (or (obj? opnd) (lbl? opnd))))
                              (loop2 (cdr l)
                                     (varset-adjoin liv (ref-var arg))
                                     (cdr live-vars-at-next-regs)
                                     (ref-var arg))
                              (begin
                                (save-arg opnd
                                          var
                                          needed
                                          (node->comment
                                           (if (eq? arg 'return)
                                             node
                                             arg)))
                                (loop2 (cdr l)
                                       (varset-adjoin liv var)
                                       (cdr live-vars-at-next-regs)
                                       var)))

                            ; return address or argument

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                            (begin
                              (save-val opnd
                                        var
                                        needed
                                        (node->comment
                                         (if (eq? arg 'return)
                                           node
                                           arg)))
                              (stretchable-vector-set! reg-map pos var)
                              (loop2 (cdr l)
                                     (varset-adjoin liv var)
                                     (cdr live-vars-at-next-regs)
                                     oper-var))

                            (let ((reg (make-reg pos)))

                              (if (all-args-trivial? (cdr l))
                                (save-opnd-to-reg opnd
                                                  reg
                                                  var
                                                  needed
                                                  (node->comment
                                                   (if (eq? arg 'return)
                                                     node
                                                     arg)))
                                (save-in-slot 111 opnd
                                              var
                                              needed
                                              (node->comment
                                               (if (eq? arg 'return)
                                                 node
                                                 arg))))

                              (stretchable-vector-set! reg-map pos var)
                              (loop2 (cdr l)
                                     (varset-adjoin liv var)
                                     (cdr live-vars-at-next-regs)
                                     oper-var))

))

                        (let loop3 ((i (- target.nb-regs 1)))
                          (if (>= i 0)

                            ; ==== THIRD: reload spilled registers

                            (let ((var (stretchable-vector-ref reg-map i)))
                              (if var
                                (let ((var-i (reg->var regs i))) ; #f if no var
                                  (if (or (not var-i) (not (eq? var-i var)))
                                    (save-opnd-to-reg (var->opnd var)
                                                      (make-reg i)
                                                      var
                                                      liv
                                                      (node->comment node)))))
                              (loop3 (- i 1)))

                            ; ==== FOURTH: jump to procedure

                            (let ((opnd
                                   (cond (local-proc-info
                                          (make-lbl
                                           (proc-info-lbl2 local-proc-info)))
                                         (proc
                                          (make-obj proc))
                                         (else
                                          (var->opnd oper-var)))))

                              (adjust-slots
                               (+ frame-start (length in-stk))
                               liv
                               (node->comment node))

                              (if (not (reason-tail? reason2))
                                (let ((frame-reserve
                                       (frame-constraints-reserve
                                        target.frame-constraints)))
                                  (let loop4 ((i (- frame-reserve 1)))
                                    (if (>= i 0)
                                      (begin
                                        (put-var (make-stk (- frame-start i))
                                                 empty-var)
                                        (loop4 (- i 1)))))))

                              (seal-bb (intrs-enabled? (node-env node))
                                       (if (reason-tail? reason2)
                                         'tail-call
                                         'call))

                              (if (and (not (intrs-enabled? (node-env node)))
                                       (not (reason-tail? reason2))
                                       (warnings? (node-env node)))
                                (compiler-user-warning
                                 (source-locat (node-source node))
                                 "Nontail call with interrupts disabled"))

                              (bb-put-branch! *bb*
                                (make-jump
                                 opnd
                                 (if local-proc-info #f nb-args)
                                 #f
                                 (safe? (node-env node))
                                 (current-frame liv)
                                 (node->comment node)))

                              ; ==== FIFTH: put return label if there is one

                              (let ((result-var (make-temp-var 'result)))

                                (shrink-slots frame-start)
                                (flush-regs)
                                (put-var target.proc-result result-var)

                                (if (reason-tail? reason2)
                                  target.proc-result
                                  (begin
                                    (set! poll (return-poll poll))
                                    (set! *bb*
                                      (make-bb
                                       (make-label-return
                                        return-lbl
                                        (current-frame
                                         (varset-adjoin live result-var))
                                        (node->comment node))
                                       *bbs*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#;
                      (let ()
                        (##namespace ("" with-output-to-string pp))
                        (pp (list (parse-tree->expression node)
                                  LIVE:
                                  (map var-name (varset->list live))
                                  (list
                                   R:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) regs)
                                   S:
                                   (map (lambda (x) (if (var? x) (var-name x) x)) slots)))))


                                    (gen-return node live reason target.proc-result)))))))))))))))))))

(define (contained-reg/slot opnd)
  (cond ((reg? opnd)
         opnd)
        ((stk? opnd)
         opnd)
        ((clo? opnd)
         (contained-reg/slot (clo-base opnd)))
        (else
         #f)))

(define (opnd-needed opnd needed)
  (let ((x (contained-reg/slot opnd)))
    (if x
      (varset-adjoin needed (get-var x))
      needed)))

(define (save-opnd opnd live comment)
  (let ((dest (or ;(highest-dead-reg live) ; it is better to not use registers
                  (lowest-dead-slot live))))
    (put-copy 12 opnd dest (get-var opnd) live comment)))

(define (save-regs-to-stk regs live comment)
  (for-each (lambda (i)
              (let ((slot (lowest-dead-slot live))
                    (opnd (make-reg i)))
                (put-copy 13 opnd slot (get-var opnd) live comment)))
            regs))

(define (save-opnd-to-reg opnd reg var live comment)
  (let ((reg-var (reg->var regs (reg-num reg))))
    (if (and reg-var
             (live-reg-var? reg-var (live-vars live)))
      (save-opnd reg (opnd-needed opnd live) comment))
    (put-copy 14 opnd reg var live comment)))

(define (save-opnd-to-stk opnd stk var live comment)
  (if (memq (stk-num stk) (live-slots live))
    (save-opnd stk (opnd-needed opnd live) comment))
  (put-copy 15 opnd stk var live comment))

(define (all-args-trivial? l)
  (if (null? l)
    #t
    (let ((arg (car (car l))))
      (or (eq? arg 'return)
          (and (trivial? arg)
               (all-args-trivial? (cdr l)))))))

(define (every-trivial? l)
  (or (null? l)
      (and (trivial? (car l))
           (every-trivial? (cdr l)))))

(define (trivial? node)
  (or (cst? node)
      (ref? node)
      (and (set? node)
           (trivial? (set-val node)))
      (and (app? node)
           (let ((proc (app->specialized-proc node)))
             (and proc ((proc-obj-inlinable? proc) (node-env node))))
           (every-trivial? (app-args node)))))

(define (boolean-value? node)
  (or (and (conj? node)
           (boolean-value? (conj-pre node))
           (boolean-value? (conj-alt node)))
      (and (disj? node)
           (boolean-value? (disj-pre node))
           (boolean-value? (disj-alt node)))
      (boolean-app? node)))

(define (boolean-app? node)
  (if (app? node)
    (let ((proc (app->specialized-proc node)))
      (if proc
        (eq? (type-name (proc-obj-type proc)) 'boolean)
        #f))
    #f))

(define (pcontext->jump-state pcontext args)
  (let ((pcontext pcontext))

    (define (empty-node-list n)
      (if (> n 0)
        (cons #f (empty-node-list (- n 1)))
        '()))

    (let* ((fs (pcontext-fs pcontext))
           (slots-list (empty-node-list fs))
           (regs-list (empty-node-list target.nb-regs)))

      (define (assign-node-to-loc var loc)
        (let ((x (cond ((reg? loc)
                        (let ((i (reg-num loc)))
                          (if (<= i target.nb-regs)
                            (drop regs-list i)
                            (compiler-internal-error
                              "jump-state, reg out of range"))))
                       ((stk? loc)
                        (let ((i (stk-num loc)))
                          (if (<= i fs)
                            (drop slots-list (- i 1))
                            (compiler-internal-error
                              "jump-state, stk out of range"))))
                       (else
                        (compiler-internal-error
                          "jump-state, loc other than reg or stk")))))
          (if (not (car x))
            (set-car! x var)
            (compiler-internal-error
              "jump-state, duplicate location in back-end's pcontext"))))

      (let loop ((l (pcontext-map pcontext)))
        (if (not (null? l))
          (let* ((couple (car l))
                 (name (car couple))
                 (loc (cdr couple)))
            (cond ((eq? name 'return)
                   (assign-node-to-loc 'return loc))
                  (else
                   (assign-node-to-loc (list-ref args (- name 1)) loc)))
            (loop (cdr l)))))

      (make-jump-state slots-list regs-list))))

(define (args->jump-state args)
  (pcontext->jump-state (target.jump-info (length args)) args))

(define (proc-info->jump-state proc-info args)
  (let* ((proc (proc-info-proc proc-info))
         (context (proc-info-context proc-info))
         (parms (prc-parms proc)))
'(pp (list '********9 (map var-name parms)
(context-nb-slots context)
(map (lambda (x) (and x (var-name x))) (context-slots context))
(map (lambda (x) (and x (var-name x))) (context-regs context))))
    (pcontext->jump-state (proc-info-pcontext proc-info) args)))

(define (make-jump-state in-stk in-reg) (vector in-stk in-reg))
(define (jump-state-in-stk x) (vector-ref x 0))
(define (jump-state-in-reg x) (vector-ref x 1))

(define (arg-eval-order oper nodes)

  (define (loop nodes pos part1 part2)

    (cond ((null? nodes)
           (let ((p1 (reverse part1))
                 (p2 (free-vars-order part2)))
             (cond ((not oper)
                    (append p1 p2))
                   ((trivial? oper)
                    (append p1 p2 (list (cons oper 'operator))))
                   (else
                    (append (cons (cons oper 'operator) p1) p2)))))

          ((not (car nodes))
           (loop (cdr nodes)
                 (+ pos 1)
                 part1
                 part2))

          ((or (eq? (car nodes) 'return)
               (trivial? (car nodes)))
           (loop (cdr nodes)
                 (+ pos 1)
                 part1
                 (cons (cons (car nodes) pos) part2)))

          (else
           (loop (cdr nodes)
                 (+ pos 1)
                 (cons (cons (car nodes) pos) part1)
                 part2))))

  (loop nodes 0 '() '()))

(define (free-vars-order l)
  (let ((bins '())
        (ordered-args '()))

    (define (free-v x)
      (if (eq? x 'return)
        (varset-empty)
        (bound-free-variables x)))

    (define (add-to-bin! x)
      (let ((y (assq x bins)))
        (if y
          (set-cdr! y (+ (cdr y) 1))
          (set! bins (cons (cons x 1) bins)))))

    (define (payoff-if-removed node)
      (let loop ((l (varset->list (free-v node))) (r 0))
        (if (null? l)
          r
          (let ((y (cdr (assq (car l) bins))))
            (loop (cdr l) (+ r (quotient 1000 (* y y)))))))) ; heuristic

    (define (remove-free-vars! x)
      (let loop ((l (varset->list x)))
        (if (not (null? l))
          (let ((y (assq (car l) bins)))
            (set-cdr! y (- (cdr y) 1))
            (loop (cdr l))))))

    (define (find-max-payoff l thunk)
      (if (null? l)
        (thunk '() -1)
        (find-max-payoff (cdr l)
          (lambda (best-arg best-payoff)
            (let ((payoff (payoff-if-removed (car (car l)))))
              (if (>= payoff best-payoff)
                (thunk (car l) payoff)
                (thunk best-arg best-payoff)))))))

    (for-each (lambda (x)
                (for-each add-to-bin! (varset->list (free-v (car x)))))
              l)

    (if (> (length l) 10) ; if many arguments just use left to right order
      l
      (let loop ((args l) (ordered-args '()))
        (if (null? args)
          (reverse ordered-args)
          (find-max-payoff args
            (lambda (best-arg best-payoff)
              (remove-free-vars! (free-v (car best-arg)))
              (loop (remq best-arg args) (cons best-arg ordered-args)))))))))

(define (compute-live-vars-at-each-expr live exprs reason)
  (if (null? exprs)
    (list live)
    (let* ((live-vars-at-next-exprs
             (compute-live-vars-at-each-expr live (cdr exprs) reason))
           (live-after
             (car live-vars-at-next-exprs)))
      (cond ((not (car exprs))
             (cons live-after
                   live-vars-at-next-exprs))
            ((eq? (car exprs) 'return)
             (cons (if (reason-tail? reason)
                     (varset-adjoin live-after ret-var)
                     live-after)
                   live-vars-at-next-exprs))
            (else
             (cons (varset-union live-after (bound-free-variables (car exprs)))
                   live-vars-at-next-exprs))))))


;;;----------------------------------------------------------------------------
;;
;; generate code for a 'let' or 'letrec'

(define (gen-let proc vals live reason)
  (let* ((live (varset-union live (proc-body-live-varset proc)))
         (vars (prc-parms proc))
         (node (prc-body proc))
         (var-val-map (pair-up vars vals))
         (var-set (list->varset vars))
         (all-live
          (varset-union-multi
           (cons live
                 (cons (bound-free-variables node)
                       (map bound-free-variables vals))))))

    (define (var->val var) (cdr (assq var var-val-map)))

    (define (proc-var? var) (prc? (var->val var)))

    (define (closed-vars var const-proc-vars)
      (varset-difference (not-constant-closed-vars (var->val var))
                         const-proc-vars))

    (define (no-closed-vars? var const-proc-vars)
      (varset-empty? (closed-vars var const-proc-vars)))

    (define (closed-vars? var const-proc-vars)
      (not (no-closed-vars? var const-proc-vars)))

    (define (compute-const-proc-vars proc-vars)
      (let loop1 ((const-proc-vars proc-vars))
        (let ((new-const-proc-vars
                (list->varset
                  (keep (lambda (x) (no-closed-vars? x const-proc-vars))
                        (varset->list const-proc-vars)))))
          (if (= (varset-size new-const-proc-vars)
                 (varset-size const-proc-vars))
            const-proc-vars
            (loop1 new-const-proc-vars)))))

    (let* ((proc-vars (list->varset (keep proc-var? (varset->list var-set))))
           (const-proc-vars (compute-const-proc-vars proc-vars))
           (clo-vars-list (keep (lambda (x) (closed-vars? x const-proc-vars))
                                (varset->list proc-vars)))
           (clo-vars (list->varset clo-vars-list)))

      (for-each
        (lambda (proc-var)
          (let* ((proc-info (schedule-gen-proc (var->val proc-var) '()))
                 (proc-lbl (make-lbl (proc-info-lbl1 proc-info))))
            (add-known-proc proc-info)
            (add-constant-var proc-var proc-lbl)))
        (varset->list const-proc-vars))

      (let ((non-clo-vars-list
              (keep (lambda (var)
                      (and (not (varset-member? var const-proc-vars))
                           (not (varset-member? var clo-vars))))
                    (varset->list var-set)))
            (liv
              (varset-union-multi
                (cons live
                      (cons (bound-free-variables node)
                            (map (lambda (x)
                                   (closed-vars x const-proc-vars))
                                 clo-vars-list))))))

        (let loop2 ((vars* non-clo-vars-list))
          (if (not (null? vars*))
            (let* ((var (car vars*))
                   (val (var->val var))
                   (needed (vals-live-vars liv (map var->val (cdr vars*)))))
              (if (var-useless? var)
                (gen-node val needed (make-reason-side))
                (save-val (gen-node val
                                    needed
                                    (make-reason-need #f ;;;;;;;;;;;is this good?
                                                      #; target.proc-result))
                          var
                          needed
                          (node->comment val)))
              (loop2 (cdr vars*)))))

        (if (pair? clo-vars-list)
          (begin

            (shrink-slots (stk-num (highest-live-slot liv)))

            (let loop3 ((l clo-vars-list))
              (if (not (null? l))
                (begin
                  (push-slot)
                  (let ((var (car l))
                        (slot (make-stk nb-slots)))
                     (put-var slot var)
                     (loop3 (cdr l))))))

            (zzzbb-put-non-branch! *bb* "IN gen-let"
              (make-close
                (map (lambda (var)
                       (let ((closed-list
                               (sort-variables
                                 (varset->list
                                   (closed-vars var const-proc-vars)))))
                         (if (null? closed-list)
                           (compiler-internal-error
                             "gen-let, no closed variables:" (var-name var))
                           (let ((proc-info
                                  (schedule-gen-proc (var->val var)
                                                     closed-list)))
                             (make-closure-parms
                              (var->opnd var)
                              (proc-info-lbl1 proc-info)
                              (map var->opnd closed-list))))))
                     clo-vars-list)
                (current-frame liv)
                (node->comment node)))))

        (gen-node node live reason)))))

(define (save-arg opnd var live comment)
  (if (glo? opnd)
    (add-constant-var var opnd)
    (save-val opnd var live comment)))

(define (save-val opnd var live comment)
  (cond ((or (obj? opnd) (lbl? opnd))
         (add-constant-var var opnd))
        ((and (reg? opnd)
              (let ((opnd-var (reg->var regs (reg-num opnd))))
                (or (not opnd-var)
                    (not (live-reg-var? opnd-var (live-vars live))))))
         (put-var opnd var))
        ((and (stk? opnd)
              (not (memq (stk-num opnd) (live-slots live))))
         (put-var opnd var))
        (else
         (save-in-slot 222 opnd var live comment))))

(define (save-in-slot n opnd var live comment);;;;;;;;;;;;;;;;;;;;;;;;;
  (let ((slot (lowest-dead-slot live)))
    (put-copy n opnd slot var live comment)))

(define (save-var opnd var live comment)
  (cond ((or (obj? opnd) (lbl? opnd))
         (add-constant-var var opnd)
         var)
        ((or (glo? opnd) (reg? opnd) (stk? opnd))
         (get-var opnd))
        (else
         (let ((dest (or (highest-dead-reg live) (lowest-dead-slot live))))
           (put-copy 17 opnd dest var live comment)
           var))))

(define (put-copy n opnd loc var live comment);;;;;;;;;;;;;;;;;;;;;;;
  (if (and (stk? loc) (> (stk-num loc) nb-slots))
    (begin
      (extend-slots (- (stk-num loc) 1) live comment)
      (push-slot)))
  (if var (put-var loc var))
  (if (not (eq? opnd loc))
    (zzzbb-put-non-branch! *bb* (string-append "IN put-copy " (number->string n))
      (make-copy opnd
                 loc
                 (current-frame (if var (varset-adjoin live var) live))
                 comment))))

(define (var-useless? var)
  (and (ptset-empty? (var-refs var))
       (ptset-empty? (var-sets var))))

(define (vals-live-vars live vals)
  (if (null? vals)
    live
    (vals-live-vars (varset-union live (bound-free-variables (car vals)))
                    (cdr vals))))

;;;----------------------------------------------------------------------------
;;
;; generate code for a future

(define (gen-fut node live reason)
  (let* ((val (fut-val node))
         (clo-vars (not-constant-closed-vars val))
         (clo-vars-list (varset->list clo-vars))
         (ret-var* (make-temp-var 0))
         (live-after live)
         (live-starting-task (varset-adjoin (varset-union live-after clo-vars)
                                            ret-var*))
         (task-lbl (bbs-new-lbl! *bbs*))
         (return-lbl (bbs-new-lbl! *bbs*)))

    ; save regs on stack if they contain values needed after the future
    (save-regs-to-stk (live-regs live-after)
                      live-starting-task
                      (node->comment node))

    (let* ((top-live-slot
            (stk-num (highest-live-slot live-after)))
           (frame-start
            (let ((frame-reserve
                   (frame-constraints-reserve target.frame-constraints))
                  (frame-align
                   (frame-constraints-align target.frame-constraints)))
              (* (+ (quotient (+ (+ top-live-slot frame-reserve)
                                 (- frame-align 1))
                              frame-align)
                    1) ;; reserve space for a break frame
                 frame-align))))

      ; move return address to where task expects it
      (save-opnd-to-reg (make-lbl return-lbl)
                        target.task-return
                        ret-var*
                        (varset-remove live-starting-task ret-var*)
                        (node->comment node))

      ; save variables that the task needs (that are not in regs)
      (let loop1 ((l clo-vars-list) (i 0))
        (if (null? l)
          (adjust-slots
           (+ frame-start i)
           live-starting-task
           (node->comment node))
          (let ((var (car l))
                (rest (cdr l)))
            (if (memq var regs)
              (loop1 rest i)
              (let ((live-v
                     (varset-union live-starting-task
                                   (live-vars (list->varset rest)))))
                (let loop2 ((j (- target.nb-regs 1)))
                  (if (>= j 0)
                    (if (or (>= j (length regs))
                            (not (varset-member? (list-ref regs j)
                                                 live-v)))
                      (let ((reg (make-reg j)))
                        (put-copy 19 (var->opnd var)
                                  reg
                                  var
                                  live-v
                                  (node->comment node))
                        (loop1 rest i))
                      (loop2 (- j 1)))
                  (let ((slot (make-stk (+ frame-start (+ i 1))))
                        (needed (list->varset rest)))
                      (if (and (or (> (stk-num slot) nb-slots)
                                 (not (memq (list-ref slots (- nb-slots (stk-num slot))) regs)))
                             (memq (stk-num slot) (live-slots needed)))
                      (save-opnd slot
                                 live-v
                                 (node->comment node)))
                    (put-copy 20 (var->opnd var)
                              slot
                              var
                              live-v
                              (node->comment node))
                    (loop1 rest (+ i 1))))))))))

      (let ((frame-reserve
             (frame-constraints-reserve
              target.frame-constraints)))
        (let loop3 ((i (- frame-reserve 1)))
          (if (>= i 0)
            (begin
              (put-var (make-stk (- frame-start i))
                       empty-var)
              (loop3 (- i 1))))))

      (seal-bb (intrs-enabled? (node-env node)) 'call)

      (bb-put-branch! *bb*
        (make-jump (make-lbl task-lbl)
                   #f
                   #f
                   #f
                   (current-frame live-starting-task)
                   (node->comment node)))

      (let ((task-context
              (make-context (- nb-slots frame-start)
                            (reverse (drop (reverse slots) frame-start))
                            (cons ret-var (cdr regs))
                            '()
                            poll
                            entry-bb))
            (return-context
              (make-context frame-start
                            (drop slots (- nb-slots frame-start))
                            '()
                            closed
                            (return-poll poll)
                            entry-bb)))

        (restore-context task-context)
        (set! *bb* (make-bb
                     (make-label-task-entry
                       task-lbl
                       (current-frame live-starting-task)
                       (node->comment node))
                     *bbs*))

        (gen-node val ret-var-set (make-reason-tail))

        (let ((result-var (make-temp-var 'future)))
          (restore-context return-context)
          (put-var target.proc-result result-var)

          (set! *bb* (make-bb
                       (make-label-task-return
                         return-lbl
                         (current-frame (varset-adjoin live result-var))
                         (node->comment node))
                       *bbs*))

          (gen-return node live reason target.proc-result))))))

;;;----------------------------------------------------------------------------
