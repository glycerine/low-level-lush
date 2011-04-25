;;;============================================================================

;;; File: "_num.scm", Time-stamp: <2009-11-26 16:15:21 feeley>

;;; Copyright (c) 1994-2009 by Marc Feeley, All Rights Reserved.
;;; Copyright (c) 2004-2009 by Brad Lucier, All Rights Reserved.

;;;============================================================================

(##include "header.scm")
(c-declare "#include \"mem.h\"")
(##define-macro (use-fast-bignum-algorithms) #t)

;;;============================================================================

;;; Implementation of exceptions.

(implement-library-type-range-exception)

(define-prim (##raise-range-exception arg-num proc . args)
  (##extract-procedure-and-arguments
   proc
   args
   arg-num
   #f
   #f
   (lambda (procedure arguments arg-num dummy1 dummy2)
     (macro-raise
      (macro-make-range-exception procedure arguments arg-num)))))

(implement-library-type-divide-by-zero-exception)

(define-prim (##raise-divide-by-zero-exception proc . args)
  (##extract-procedure-and-arguments
   proc
   args
   #f
   #f
   #f
   (lambda (procedure arguments dummy1 dummy2 dummy3)
     (macro-raise
      (macro-make-divide-by-zero-exception procedure arguments)))))

(implement-library-type-fixnum-overflow-exception)

(define-prim (##raise-fixnum-overflow-exception proc . args)
  (##extract-procedure-and-arguments
   proc
   args
   #f
   #f
   #f
   (lambda (procedure arguments dummy1 dummy2 dummy3)
     (macro-raise
      (macro-make-fixnum-overflow-exception procedure arguments)))))

;;;----------------------------------------------------------------------------

;;; Define type checking procedures.

(define-fail-check-type exact-signed-int8 'exact-signed-int8)
(define-fail-check-type exact-signed-int8-list 'exact-signed-int8-list)
(define-fail-check-type exact-unsigned-int8 'exact-unsigned-int8)
(define-fail-check-type exact-unsigned-int8-list 'exact-unsigned-int8-list)
(define-fail-check-type exact-signed-int16 'exact-signed-int16)
(define-fail-check-type exact-signed-int16-list 'exact-signed-int16-list)
(define-fail-check-type exact-unsigned-int16 'exact-unsigned-int16)
(define-fail-check-type exact-unsigned-int16-list 'exact-unsigned-int16-list)
(define-fail-check-type exact-signed-int32 'exact-signed-int32)
(define-fail-check-type exact-signed-int32-list 'exact-signed-int32-list)
(define-fail-check-type exact-unsigned-int32 'exact-unsigned-int32)
(define-fail-check-type exact-unsigned-int32-list 'exact-unsigned-int32-list)
(define-fail-check-type exact-signed-int64 'exact-signed-int64)
(define-fail-check-type exact-signed-int64-list 'exact-signed-int64-list)
(define-fail-check-type exact-unsigned-int64 'exact-unsigned-int64)
(define-fail-check-type exact-unsigned-int64-list 'exact-unsigned-int64-list)
(define-fail-check-type inexact-real 'inexact-real)
(define-fail-check-type inexact-real-list 'inexact-real-list)
(define-fail-check-type number 'number)
(define-fail-check-type real 'real)
(define-fail-check-type finite-real 'finite-real)
(define-fail-check-type rational 'rational)
(define-fail-check-type integer 'integer)
(define-fail-check-type exact-integer 'exact-integer)
(define-fail-check-type fixnum 'fixnum)
(define-fail-check-type flonum 'flonum)

;;;----------------------------------------------------------------------------

;;; Numerical type predicates.

(define-prim (##number? x)
  (##complex? x))

(define-prim (##complex? x)
  (macro-number-dispatch x #f
    #t ;; x = fixnum
    #t ;; x = bignum
    #t ;; x = ratnum
    #t ;; x = flonum
    #t)) ;; x = cpxnum

(define-prim (number? x)
  (macro-force-vars (x)
    (##number? x)))

(define-prim (complex? x)
  (macro-force-vars (x)
    (##complex? x)))

(define-prim (##real? x)
  (macro-number-dispatch x #f
    #t ;; x = fixnum
    #t ;; x = bignum
    #t ;; x = ratnum
    #t ;; x = flonum
    (macro-cpxnum-real? x))) ;; x = cpxnum

(define-prim (real? x)
  (macro-force-vars (x)
    (##real? x)))

(define-prim (##rational? x)
  (macro-number-dispatch x #f
    #t ;; x = fixnum
    #t ;; x = bignum
    #t ;; x = ratnum
    (macro-flonum-rational? x) ;; x = flonum
    (macro-cpxnum-rational? x))) ;; x = cpxnum

(define-prim (rational? x)
  (macro-force-vars (x)
    (##rational? x)))

(define-prim (##integer? x)
  (macro-number-dispatch x #f
    #t ;; x = fixnum
    #t ;; x = bignum
    #f ;; x = ratnum
    (macro-flonum-int? x) ;; x = flonum
    (macro-cpxnum-int? x))) ;; x = cpxnum

(define-prim (integer? x)
  (macro-force-vars (x)
    (##integer? x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Exactness predicates.

(define-prim (##exact? x)

  (define (type-error) #f)

  (macro-number-dispatch x (type-error)
    #t ;; x = fixnum
    #t ;; x = bignum
    #t ;; x = ratnum
    #f ;; x = flonum
    (and (##not (##flonum? (macro-cpxnum-real x))) ;; x = cpxnum
         (##not (##flonum? (macro-cpxnum-imag x))))))

(define-prim (exact? x)
  (macro-force-vars (x)
    (let ()

      (define (type-error)
        (##fail-check-number 1 exact? x))

      (macro-number-dispatch x (type-error)
        #t ;; x = fixnum
        #t ;; x = bignum
        #t ;; x = ratnum
        #f ;; x = flonum
        (and (##not (##flonum? (macro-cpxnum-real x))) ;; x = cpxnum
             (##not (##flonum? (macro-cpxnum-imag x))))))))

(define-prim (##inexact? x)

  (define (type-error) #f)

  (macro-number-dispatch x (type-error)
    #f ;; x = fixnum
    #f ;; x = bignum
    #f ;; x = ratnum
    #t ;; x = flonum
    (or (##flonum? (macro-cpxnum-real x)) ;; x = cpxnum
        (##flonum? (macro-cpxnum-imag x)))))

(define-prim (inexact? x)
  (macro-force-vars (x)
    (let ()

      (define (type-error)
        (##fail-check-number 1 inexact? x))

      (macro-number-dispatch x (type-error)
        #f ;; x = fixnum
        #f ;; x = bignum
        #f ;; x = ratnum
        #t ;; x = flonum
        (or (##flonum? (macro-cpxnum-real x)) ;; x = cpxnum
            (##flonum? (macro-cpxnum-imag x)))))))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Comparison predicates.

(define-prim (##= x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (##fixnum.= x y)
      #f
      #f
      (if (##flonum.<-fixnum-exact? x)
          (##flonum.= (##flonum.<-fixnum x) y)
          (and (##flonum.finite? y)
               (##ratnum.= (##ratnum.<-exact-int x) (##flonum.->ratnum y))))
      (##cpxnum.= (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      #f
      (or (##eq? x y)
          (##bignum.= x y))
      #f
      (and (##flonum.finite? y)
           (##ratnum.= (##ratnum.<-exact-int x) (##flonum.->ratnum y)))
      (##cpxnum.= (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      #f
      #f
      (or (##eq? x y)
          (##ratnum.= x y))
      (and (##flonum.finite? y)
           (##ratnum.= x (##flonum.->ratnum y)))
      (##cpxnum.= (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (if (##flonum.<-fixnum-exact? y)
          (##flonum.= x (##flonum.<-fixnum y))
          (and (##flonum.finite? x)
               (##ratnum.= (##flonum.->ratnum x) (##ratnum.<-exact-int y))))
      (and (##flonum.finite? x)
           (##ratnum.= (##flonum.->ratnum x) (##ratnum.<-exact-int y)))
      (and (##flonum.finite? x)
           (##ratnum.= (##flonum.->ratnum x) y))
      (##flonum.= x y)
      (##cpxnum.= (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = cpxnum
      (##cpxnum.= x (##cpxnum.<-noncpxnum y))
      (##cpxnum.= x (##cpxnum.<-noncpxnum y))
      (##cpxnum.= x (##cpxnum.<-noncpxnum y))
      (##cpxnum.= x (##cpxnum.<-noncpxnum y))
      (##cpxnum.= x y))))

(define-prim-nary-bool (= x y)
  #t
  (if (##number? x) #t '(1))
  (##= x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-number))

(define-prim (##< x y #!optional (nan-result #f))

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (##fixnum.< x y)
      (##not (##bignum.negative? y))
      (##ratnum.< (##ratnum.<-exact-int x) y)
      (cond ((##flonum.finite? y)
             (if (##flonum.<-fixnum-exact? x)
                 (##flonum.< (##flonum.<-fixnum x) y)
                 (##ratnum.< (##ratnum.<-exact-int x) (##flonum.->ratnum y))))
            ((##flonum.nan? y)
             nan-result)
            (else
             (##flonum.positive? y)))
      (if (macro-cpxnum-real? y)
          (##< x (macro-cpxnum-real y) nan-result)
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      (##bignum.negative? x)
      (##bignum.< x y)
      (##ratnum.< (##ratnum.<-exact-int x) y)
      (cond ((##flonum.finite? y)
             (##ratnum.< (##ratnum.<-exact-int x) (##flonum.->ratnum y)))
            ((##flonum.nan? y)
             nan-result)
            (else
             (##flonum.positive? y)))
      (if (macro-cpxnum-real? y)
          (##< x (macro-cpxnum-real y) nan-result)
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      (##ratnum.< x (##ratnum.<-exact-int y))
      (##ratnum.< x (##ratnum.<-exact-int y))
      (##ratnum.< x y)
      (cond ((##flonum.finite? y)
             (##ratnum.< x (##flonum.->ratnum y)))
            ((##flonum.nan? y)
             nan-result)
            (else
             (##flonum.positive? y)))
      (if (macro-cpxnum-real? y)
          (##< x (macro-cpxnum-real y) nan-result)
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (cond ((##flonum.finite? x)
             (if (##flonum.<-fixnum-exact? y)
                 (##flonum.< x (##flonum.<-fixnum y))
                 (##ratnum.< (##flonum.->ratnum x) (##ratnum.<-exact-int y))))
            ((##flonum.nan? x)
             nan-result)
            (else
             (##flonum.negative? x)))
      (cond ((##flonum.finite? x)
             (##ratnum.< (##flonum.->ratnum x) (##ratnum.<-exact-int y)))
            ((##flonum.nan? x)
             nan-result)
            (else
             (##flonum.negative? x)))
      (cond ((##flonum.finite? x)
             (##ratnum.< (##flonum.->ratnum x) y))
            ((##flonum.nan? x)
             nan-result)
            (else
             (##flonum.negative? x)))
      (if (or (##flonum.nan? x) (##flonum.nan? y))
          nan-result
          (##flonum.< x y))
      (if (macro-cpxnum-real? y)
          (##< x (macro-cpxnum-real y) nan-result)
          (type-error-on-y)))

    (if (macro-cpxnum-real? x) ;; x = cpxnum
        (macro-number-dispatch y (type-error-on-y)
          (##< (macro-cpxnum-real x) y nan-result)
          (##< (macro-cpxnum-real x) y nan-result)
          (##< (macro-cpxnum-real x) y nan-result)
          (##< (macro-cpxnum-real x) y nan-result)
          (if (macro-cpxnum-real? y)
              (##< (macro-cpxnum-real x) (macro-cpxnum-real y) nan-result)
              (type-error-on-y)))
        (type-error-on-x))))

(define-prim-nary-bool (< x y)
  #t
  (if (##real? x) #t '(1))
  (##< x y #f)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-real))

(define-prim-nary-bool (> x y)
  #t
  (if (##real? x) #t '(1))
  (##< y x #f)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-real))

(define-prim-nary-bool (<= x y)
  #t
  (if (##real? x) #t '(1))
  (##not (##< y x #t))
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-real))

(define-prim-nary-bool (>= x y)
  #t
  (if (##real? x) #t '(1))
  (##not (##< x y #t))
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-real))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Numerical property predicates.

(define-prim (##zero? x)

  (define (type-error)
    (##fail-check-number 1 zero? x))

  (macro-number-dispatch x (type-error)
    (##fixnum.zero? x)
    #f
    #f
    (##flonum.zero? x)
    (and (let ((imag (macro-cpxnum-imag x)))
           (and (##flonum? imag) (##flonum.zero? imag)))
         (let ((real (macro-cpxnum-real x)))
           (if (##fixnum? real)
               (##fixnum.zero? real)
               (and (##flonum? real) (##flonum.zero? real)))))))

(define-prim (zero? x)
  (macro-force-vars (x)
    (##zero? x)))

(define-prim (##positive? x)

  (define (type-error)
    (##fail-check-real 1 positive? x))

  (macro-number-dispatch x (type-error)
    (##fixnum.positive? x)
    (##not (##bignum.negative? x))
    (##positive? (macro-ratnum-numerator x))
    (##flonum.positive? x)
    (if (macro-cpxnum-real? x)
        (##positive? (macro-cpxnum-real x))
        (type-error))))

(define-prim (positive? x)
  (macro-force-vars (x)
    (##positive? x)))

(define-prim (##negative? x)

  (define (type-error)
    (##fail-check-real 1 negative? x))

  (macro-number-dispatch x (type-error)
    (##fixnum.negative? x)
    (##bignum.negative? x)
    (##negative? (macro-ratnum-numerator x))
    (##flonum.negative? x)
    (if (macro-cpxnum-real? x)
        (##negative? (macro-cpxnum-real x))
        (type-error))))

(define-prim (negative? x)
  (macro-force-vars (x)
    (##negative? x)))

(define-prim (##odd? x)

  (define (type-error)
    (##fail-check-integer 1 odd? x))

  (macro-number-dispatch x (type-error)
    (##fixnum.odd? x)
    (macro-bignum-odd? x)
    (type-error)
    (if (macro-flonum-int? x)
        (##odd? (##flonum.->exact-int x))
        (type-error))
    (if (macro-cpxnum-int? x)
        (##odd? (##inexact->exact (macro-cpxnum-real x)))
        (type-error))))

(define-prim (odd? x)
  (macro-force-vars (x)
    (##odd? x)))

(define-prim (##even? x)

  (define (type-error)
    (##fail-check-integer 1 even? x))

  (macro-number-dispatch x (type-error)
    (##not (##fixnum.odd? x))
    (##not (macro-bignum-odd? x))
    (type-error)
    (if (macro-flonum-int? x)
        (##even? (##flonum.->exact-int x))
        (type-error))
    (if (macro-cpxnum-int? x)
        (##even? (##inexact->exact (macro-cpxnum-real x)))
        (type-error))))

(define-prim (even? x)
  (macro-force-vars (x)
    (##even? x)))

(define-prim (##finite? x)

  (define (type-error)
    (##fail-check-real 1 finite? x))

  (macro-number-dispatch x (type-error)
    #t
    #t
    #t
    (##flfinite? x)
    (if (macro-cpxnum-real? x)
        (let ((real (macro-cpxnum-real x)))
          (or (##not (##flonum? real))
              (##flfinite? real)))
        (type-error))))

(define-prim (finite? x)
  (macro-force-vars (x)
    (##finite? x)))

(define-prim (##infinite? x)

  (define (type-error)
    (##fail-check-real 1 infinite? x))

  (macro-number-dispatch x (type-error)
    #f
    #f
    #f
    (##flinfinite? x)
    (if (macro-cpxnum-real? x)
        (let ((real (macro-cpxnum-real x)))
          (and (##flonum? real)
               (##flinfinite? real)))
        (type-error))))

(define-prim (infinite? x)
  (macro-force-vars (x)
    (##infinite? x)))

(define-prim (##nan? x)

  (define (type-error)
    (##fail-check-real 1 nan? x))

  (macro-number-dispatch x (type-error)
    #f
    #f
    #f
    (##flnan? x)
    (if (macro-cpxnum-real? x)
        (let ((real (macro-cpxnum-real x)))
          (and (##flonum? real)
               (##flnan? real)))
        (type-error))))

(define-prim (nan? x)
  (macro-force-vars (x)
    (##nan? x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Max and min.

(define-prim (##max x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (##fixnum.max x y)
      (if (##< x y) y x)
      (if (##< x y) y x)
      (##flonum.max (##flonum.<-fixnum x) y)
      (if (macro-cpxnum-real? y)
          (##max x (macro-cpxnum-real y))
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      (if (##< x y) y x)
      (if (##< x y) y x)
      (if (##< x y) y x)
      (##flonum.max (##flonum.<-exact-int x) y)
      (if (macro-cpxnum-real? y)
          (##max x (macro-cpxnum-real y))
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      (if (##< x y) y x)
      (if (##< x y) y x)
      (if (##< x y) y x)
      (##flonum.max (##flonum.<-ratnum x) y)
      (if (macro-cpxnum-real? y)
          (##max x (macro-cpxnum-real y))
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (##flonum.max x (##flonum.<-fixnum y))
      (##flonum.max x (##flonum.<-exact-int y))
      (##flonum.max x (##flonum.<-ratnum y))
      (##flonum.max x y)
      (if (macro-cpxnum-real? y)
          (##max x (macro-cpxnum-real y))
          (type-error-on-y)))

    (if (macro-cpxnum-real? x) ;; x = cpxnum
        (macro-number-dispatch y (type-error-on-y)
          (##max (macro-cpxnum-real x) y)
          (##max (macro-cpxnum-real x) y)
          (##max (macro-cpxnum-real x) y)
          (##max (macro-cpxnum-real x) y)
          (if (macro-cpxnum-real? y)
              (##max (macro-cpxnum-real x) (macro-cpxnum-real y))
              (type-error-on-y)))
        (type-error-on-x))))

(define-prim-nary (max x y)
  ()
  (if (##real? x) x '(1))
  (##max x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-real))

(define-prim (##min x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (##fixnum.min x y)
      (if (##< x y) x y)
      (if (##< x y) x y)
      (##flonum.min (##flonum.<-fixnum x) y)
      (if (macro-cpxnum-real? y)
          (##min x (macro-cpxnum-real y))
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      (if (##< x y) x y)
      (if (##< x y) x y)
      (if (##< x y) x y)
      (##flonum.min (##flonum.<-exact-int x) y)
      (if (macro-cpxnum-real? y)
          (##min x (macro-cpxnum-real y))
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      (if (##< x y) x y)
      (if (##< x y) x y)
      (if (##< x y) x y)
      (##flonum.min (##flonum.<-ratnum x) y)
      (if (macro-cpxnum-real? y)
          (##min x (macro-cpxnum-real y))
          (type-error-on-y)))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (##flonum.min x (##flonum.<-fixnum y))
      (##flonum.min x (##flonum.<-exact-int y))
      (##flonum.min x (##flonum.<-ratnum y))
      (##flonum.min x y)
      (if (macro-cpxnum-real? y)
          (##min x (macro-cpxnum-real y))
          (type-error-on-y)))

    (if (macro-cpxnum-real? x) ;; x = cpxnum
        (macro-number-dispatch y (type-error-on-y)
          (##min (macro-cpxnum-real x) y)
          (##min (macro-cpxnum-real x) y)
          (##min (macro-cpxnum-real x) y)
          (##min (macro-cpxnum-real x) y)
          (if (macro-cpxnum-real? y)
              (##min (macro-cpxnum-real x) (macro-cpxnum-real y))
              (type-error-on-y)))
        (type-error-on-x))))

(define-prim-nary (min x y)
  ()
  (if (##real? x) x '(1))
  (##min x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-real))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; +, *, -, /

(define-prim (##+ x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (or (##fixnum.+? x y)
          (##bignum.+ (##bignum.<-fixnum x) (##bignum.<-fixnum y)))
      (if (##fixnum.zero? x)
          y
          (##bignum.+ (##bignum.<-fixnum x) y))
      (if (##fixnum.zero? x)
          y
          (##ratnum.+ (##ratnum.<-exact-int x) y))
      (if (and (macro-special-case-exact-zero?) (##fixnum.zero? x))
          y
          (##flonum.+ (##flonum.<-fixnum x) y))
      (##cpxnum.+ (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      (if (##fixnum.zero? y)
          x
          (##bignum.+ x (##bignum.<-fixnum y)))
      (##bignum.+ x y)
      (##ratnum.+ (##ratnum.<-exact-int x) y)
      (##flonum.+ (##flonum.<-exact-int x) y)
      (##cpxnum.+ (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      (if (##fixnum.zero? y)
          x
          (##ratnum.+ x (##ratnum.<-exact-int y)))
      (##ratnum.+ x (##ratnum.<-exact-int y))
      (##ratnum.+ x y)
      (##flonum.+ (##flonum.<-ratnum x) y)
      (##cpxnum.+ (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (if (and (macro-special-case-exact-zero?) (##fixnum.zero? y))
          x
          (##flonum.+ x (##flonum.<-fixnum y)))
      (##flonum.+ x (##flonum.<-exact-int y))
      (##flonum.+ x (##flonum.<-ratnum y))
      (##flonum.+ x y)
      (##cpxnum.+ (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = cpxnum
      (##cpxnum.+ x (##cpxnum.<-noncpxnum y))
      (##cpxnum.+ x (##cpxnum.<-noncpxnum y))
      (##cpxnum.+ x (##cpxnum.<-noncpxnum y))
      (##cpxnum.+ x (##cpxnum.<-noncpxnum y))
      (##cpxnum.+ x y))))

(define-prim-nary (+ x y)
  0
  (if (##number? x) x '(1))
  (##+ x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-number))

(define-prim (##* x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (cond ((##fixnum.= y 0)
             0)
            ((if (##fixnum.= y -1)
                 (##fixnum.-? x)
                 (##fixnum.*? x y))
             => (lambda (result) result))
            (else
             (##bignum.* (##bignum.<-fixnum x) (##bignum.<-fixnum y))))
      (cond ((##fixnum.zero? x)
             0)
            ((##fixnum.= x 1)
             y)
            ((##fixnum.= x -1)
             (##negate y))
            (else
             (##bignum.* (##bignum.<-fixnum x) y)))
      (cond ((##fixnum.zero? x)
             0)
            ((##fixnum.= x 1)
             y)
            ((##fixnum.= x -1)
             (##negate y))
            (else
             (##ratnum.* (##ratnum.<-exact-int x) y)))
      (cond ((and (macro-special-case-exact-zero?)
                  (##fixnum.zero? x))
             0)
            ((##fixnum.= x 1)
             y)
            (else
             (##flonum.* (##flonum.<-fixnum x) y)))
      (cond ((and (macro-special-case-exact-zero?)
                  (##fixnum.zero? x))
             0)
            ((##fixnum.= x 1)
             y)
            (else
             (##cpxnum.* (##cpxnum.<-noncpxnum x) y))))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      (cond ((##eq? y 0)
             0)
            ((##eq? y 1)
             x)
            ((##eq? y -1)
             (##negate x))
            (else
             (##bignum.* x (##bignum.<-fixnum y))))
      (##bignum.* x y)
      (##ratnum.* (##ratnum.<-exact-int x) y)
      (##flonum.* (##flonum.<-exact-int x) y)
      (##cpxnum.* (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      (cond ((##fixnum.zero? y)
             0)
            ((##fixnum.= y 1)
             x)
            ((##fixnum.= y -1)
             (##negate x))
            (else
             (##ratnum.* x (##ratnum.<-exact-int y))))
      (##ratnum.* x (##ratnum.<-exact-int y))
      (##ratnum.* x y)
      (##flonum.* (##flonum.<-ratnum x) y)
      (##cpxnum.* (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (cond ((and (macro-special-case-exact-zero?) (##fixnum.zero? y))
             0)
            ((##fixnum.= y 1)
             x)
            (else
             (##flonum.* x (##flonum.<-fixnum y))))
      (##flonum.* x (##flonum.<-exact-int y))
      (##flonum.* x (##flonum.<-ratnum y))
      (##flonum.* x y)
      (##cpxnum.* (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = cpxnum
      (cond ((and (macro-special-case-exact-zero?) (##fixnum.zero? y))
             0)
            ((##fixnum.= y 1)
             x)
            (else
             (##cpxnum.* x (##cpxnum.<-noncpxnum y))))
      (##cpxnum.* x (##cpxnum.<-noncpxnum y))
      (##cpxnum.* x (##cpxnum.<-noncpxnum y))
      (##cpxnum.* x (##cpxnum.<-noncpxnum y))
      (##cpxnum.* x y))))

(define-prim-nary (* x y)
  1
  (if (##number? x) x '(1))
  (##* x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-number))

(define-prim (##negate x)

  (##define-macro (type-error) `'(1))

  (macro-number-dispatch x (type-error)
    (or (##fixnum.-? x)
        (##bignum.- (##bignum.<-fixnum 0) (##bignum.<-fixnum ##min-fixnum)))
    (##bignum.- (##bignum.<-fixnum 0) x)
    (macro-ratnum-make (##negate (macro-ratnum-numerator x))
                       (macro-ratnum-denominator x))
    (##flonum.- x)
    (##make-rectangular (##negate (macro-cpxnum-real x))
                        (##negate (macro-cpxnum-imag x)))))

(define-prim (##- x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (macro-number-dispatch x (type-error-on-x)

    (macro-number-dispatch y (type-error-on-y) ;; x = fixnum
      (or (##fixnum.-? x y)
          (##bignum.- (##bignum.<-fixnum x) (##bignum.<-fixnum y)))
      (##bignum.- (##bignum.<-fixnum x) y)
      (if (##fixnum.zero? x)
          (##negate y)
          (##ratnum.- (##ratnum.<-exact-int x) y))
      (if (and (macro-special-case-exact-zero?) (##fixnum.zero? x))
          (##flonum.- y)
          (##flonum.- (##flonum.<-fixnum x) y))
      (##cpxnum.- (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = bignum
      (if (##fixnum.zero? y)
          x
          (##bignum.- x (##bignum.<-fixnum y)))
      (##bignum.- x y)
      (##ratnum.- (##ratnum.<-exact-int x) y)
      (##flonum.- (##flonum.<-exact-int x) y)
      (##cpxnum.- (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = ratnum
      (if (##fixnum.zero? y)
          x
          (##ratnum.- x (##ratnum.<-exact-int y)))
      (##ratnum.- x (##ratnum.<-exact-int y))
      (##ratnum.- x y)
      (##flonum.- (##flonum.<-ratnum x) y)
      (##cpxnum.- (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = flonum
      (if (and (macro-special-case-exact-zero?) (##fixnum.zero? y))
          x
          (##flonum.- x (##flonum.<-fixnum y)))
      (##flonum.- x (##flonum.<-exact-int y))
      (##flonum.- x (##flonum.<-ratnum y))
      (##flonum.- x y)
      (##cpxnum.- (##cpxnum.<-noncpxnum x) y))

    (macro-number-dispatch y (type-error-on-y) ;; x = cpxnum
      (##cpxnum.- x (##cpxnum.<-noncpxnum y))
      (##cpxnum.- x (##cpxnum.<-noncpxnum y))
      (##cpxnum.- x (##cpxnum.<-noncpxnum y))
      (##cpxnum.- x (##cpxnum.<-noncpxnum y))
      (##cpxnum.- x y))))

(define-prim-nary (- x y)
  ()
  (##negate x)
  (##- x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-number))

(define-prim (##inverse x)

  (##define-macro (type-error) `'(1))

  (define (divide-by-zero-error) #f)

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        (divide-by-zero-error)
        (if (##fixnum.negative? x)
            (if (##fixnum.= x -1)
                x
                (macro-ratnum-make -1 (##negate x)))
            (if (##fixnum.= x 1)
                x
                (macro-ratnum-make 1 x))))
    (if (##bignum.negative? x)
        (macro-ratnum-make -1 (##negate x))
        (macro-ratnum-make 1 x))
    (let ((num (macro-ratnum-numerator x))
          (den (macro-ratnum-denominator x)))
      (cond ((##eq? num 1)
             den)
            ((##eq? num -1)
             (##negate den))
            (else
             (if (##negative? num)
                 (macro-ratnum-make (##negate den) (##negate num))
                 (macro-ratnum-make den num)))))
    (##flonum./ (macro-inexact-+1) x)
    (##cpxnum./ (##cpxnum.<-noncpxnum 1) x)))

(define-prim (##/ x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (define (divide-by-zero-error) #f)

  (macro-number-dispatch y (type-error-on-y)

    (macro-number-dispatch x (type-error-on-x) ;; y = fixnum
      (cond ((##fixnum.zero? y)
             (divide-by-zero-error))
            ((##fixnum.= y 1)
             x)
            ((##fixnum.= y -1)
             (##negate x))
            ((##fixnum.zero? x)
             0)
            ((##fixnum.= x 1)
             (##inverse y))
            (else
             (##ratnum./ (##ratnum.<-exact-int x) (##ratnum.<-exact-int y))))
      (cond ((##fixnum.zero? y)
             (divide-by-zero-error))
            ((##fixnum.= y 1)
             x)
            ((##fixnum.= y -1)
             (##negate x))
            (else
             (##ratnum./ (##ratnum.<-exact-int x) (##ratnum.<-exact-int y))))
      (cond ((##fixnum.zero? y)
             (divide-by-zero-error))
            ((##fixnum.= y 1)
             x)
            ((##fixnum.= y -1)
             (##negate x))
            (else
             (##ratnum./ x (##ratnum.<-exact-int y))))
      (if (##fixnum.zero? y)
          (divide-by-zero-error)
          (##flonum./ x (##flonum.<-fixnum y)))
      (if (##fixnum.zero? y)
          (divide-by-zero-error)
          (##cpxnum./ x (##cpxnum.<-noncpxnum y))))

    (macro-number-dispatch x (type-error-on-x) ;; y = bignum
      (cond ((##fixnum.zero? x)
             0)
            ((##fixnum.= x 1)
             (##inverse y))
            (else
             (##ratnum./ (##ratnum.<-exact-int x) (##ratnum.<-exact-int y))))
      (##ratnum./ (##ratnum.<-exact-int x) (##ratnum.<-exact-int y))
      (##ratnum./ x (##ratnum.<-exact-int y))
      (##flonum./ x (##flonum.<-exact-int y))
      (##cpxnum./ x (##cpxnum.<-noncpxnum y)))

    (macro-number-dispatch x (type-error-on-x) ;; y = ratnum
      (cond ((##fixnum.zero? x)
             0)
            ((##fixnum.= x 1)
             (##inverse y))
            (else
             (##ratnum./ (##ratnum.<-exact-int x) y)))
      (##ratnum./ (##ratnum.<-exact-int x) y)
      (##ratnum./ x y)
      (##flonum./ x (##flonum.<-ratnum y))
      (##cpxnum./ x (##cpxnum.<-noncpxnum y)))

    (macro-number-dispatch x (type-error-on-x) ;; y = flonum, no error possible
      (if (and (macro-special-case-exact-zero?) (##fixnum.zero? x))
          x
          (##flonum./ (##flonum.<-fixnum x) y))
      (##flonum./ (##flonum.<-exact-int x) y)
      (##flonum./ (##flonum.<-ratnum x) y)
      (##flonum./ x y)
      (##cpxnum./ x (##cpxnum.<-noncpxnum y)))

    (macro-number-dispatch x (type-error-on-x) ;; y = cpxnum
      (##cpxnum./ (##cpxnum.<-noncpxnum x) y)
      (##cpxnum./ (##cpxnum.<-noncpxnum x) y)
      (##cpxnum./ (##cpxnum.<-noncpxnum x) y)
      (##cpxnum./ (##cpxnum.<-noncpxnum x) y)
      (##cpxnum./ x y))))

(define-prim-nary (/ x y)
  ()
  (##inverse x)
  (##/ x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-number)
  (##not ##raise-divide-by-zero-exception))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; abs

(define-prim (##abs x)

  (define (type-error)
    (##fail-check-real 1 abs x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.negative? x) (##negate x) x)
    (if (##bignum.negative? x) (##negate x) x)
    (macro-ratnum-make (##abs (macro-ratnum-numerator x))
                       (macro-ratnum-denominator x))
    (##flonum.abs x)
    (if (macro-cpxnum-real? x)
        (##make-rectangular (##abs (macro-cpxnum-real x))
                            (##abs (macro-cpxnum-imag x)))
        (type-error))))

(define-prim (abs x)
  (macro-force-vars (x)
    (##abs x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; quotient, remainder, modulo

(define-prim (##quotient x y)

  (define (type-error-on-x)
    (##fail-check-integer 1 quotient x y))

  (define (type-error-on-y)
    (##fail-check-integer 2 quotient x y))

  (define (divide-by-zero-error)
    (##raise-divide-by-zero-exception quotient x y))

  (define (exact-quotient x y)
    (##car (##exact-int.div x y)))

  (define (inexact-quotient x y)
    (let ((exact-y (##inexact->exact y)))
      (if (##eq? exact-y 0)
          (divide-by-zero-error)
          (##exact->inexact
           (##quotient (##inexact->exact x) exact-y)))))

  (macro-number-dispatch y (type-error-on-y)

    (macro-number-dispatch x (type-error-on-x) ;; y = fixnum
      (cond ((##fixnum.= y 0)
             (divide-by-zero-error))
            ((##fixnum.= y -1) ;; (quotient ##min-fixnum -1) is a bignum
             (##negate x))
            (else
             (##fixnum.quotient x y)))
      (cond ((##fixnum.= y 0)
             (divide-by-zero-error))
            (else
             (exact-quotient x y)))
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (inexact-quotient x y)
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (inexact-quotient x y)
          (type-error-on-x)))

    (macro-number-dispatch x (type-error-on-x) ;; y = bignum
      (exact-quotient x y)
      (exact-quotient x y)
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (inexact-quotient x y)
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (inexact-quotient x y)
          (type-error-on-x)))

    (type-error-on-y) ;; y = ratnum

    (macro-number-dispatch x (type-error-on-x) ;; y = flonum
      (if (macro-flonum-int? y)
          (inexact-quotient x y)
          (type-error-on-y))
      (if (macro-flonum-int? y)
          (inexact-quotient x y)
          (type-error-on-y))
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (if (macro-flonum-int? y)
              (inexact-quotient x y)
              (type-error-on-y))
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (if (macro-flonum-int? y)
              (inexact-quotient x y)
              (type-error-on-y))
          (type-error-on-x)))

    (if (macro-cpxnum-int? y) ;; y = cpxnum
        (macro-number-dispatch x (type-error-on-x)
          (inexact-quotient x y)
          (inexact-quotient x y)
          (type-error-on-x)
          (if (macro-flonum-int? x)
              (inexact-quotient x y)
              (type-error-on-x))
          (if (macro-cpxnum-int? x)
              (inexact-quotient x y)
              (type-error-on-x)))
        (type-error-on-y))))

(define-prim (quotient x y)
  (macro-force-vars (x y)
    (##quotient x y)))

(define-prim (##remainder x y)

  (define (type-error-on-x)
    (##fail-check-integer 1 remainder x y))

  (define (type-error-on-y)
    (##fail-check-integer 2 remainder x y))

  (define (divide-by-zero-error)
    (##raise-divide-by-zero-exception remainder x y))

  (define (exact-remainder x y)
    (##cdr (##exact-int.div x y)))

  (define (inexact-remainder x y)
    (let ((exact-y (##inexact->exact y)))
      (if (##eq? exact-y 0)
          (divide-by-zero-error)
          (##exact->inexact
           (##remainder (##inexact->exact x) exact-y)))))

  (macro-number-dispatch y (type-error-on-y)

    (macro-number-dispatch x (type-error-on-x) ;; y = fixnum
      (cond ((##fixnum.= y 0)
             (divide-by-zero-error))
            (else
             (##fixnum.remainder x y)))
      (cond ((##fixnum.= y 0)
             (divide-by-zero-error))
            (else
             (exact-remainder x y)))
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (inexact-remainder x y)
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (inexact-remainder x y)
          (type-error-on-x)))

    (macro-number-dispatch x (type-error-on-x) ;; y = bignum
      (exact-remainder x y)
      (exact-remainder x y)
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (inexact-remainder x y)
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (inexact-remainder x y)
          (type-error-on-x)))

    (type-error-on-y) ;; y = ratnum

    (macro-number-dispatch x (type-error-on-x) ;; y = flonum
      (if (macro-flonum-int? y)
          (inexact-remainder x y)
          (type-error-on-y))
      (if (macro-flonum-int? y)
          (inexact-remainder x y)
          (type-error-on-y))
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (if (macro-flonum-int? y)
              (inexact-remainder x y)
              (type-error-on-y))
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (if (macro-flonum-int? y)
              (inexact-remainder x y)
              (type-error-on-y))
          (type-error-on-x)))

    (if (macro-cpxnum-int? y) ;; y = cpxnum
        (macro-number-dispatch x (type-error-on-x)
          (inexact-remainder x y)
          (inexact-remainder x y)
          (type-error-on-x)
          (if (macro-flonum-int? x)
              (inexact-remainder x y)
              (type-error-on-x))
          (if (macro-cpxnum-int? x)
              (inexact-remainder x y)
              (type-error-on-x)))
        (type-error-on-y))))

(define-prim (remainder x y)
  (macro-force-vars (x y)
    (##remainder x y)))

(define-prim (##modulo x y)

  (define (type-error-on-x)
    (##fail-check-integer 1 modulo x y))

  (define (type-error-on-y)
    (##fail-check-integer 2 modulo x y))

  (define (divide-by-zero-error)
    (##raise-divide-by-zero-exception modulo x y))

  (define (exact-modulo x y)
    (let ((r (##cdr (##exact-int.div x y))))
      (if (##eq? r 0)
          0
          (if (##eq? (##negative? x) (##negative? y))
              r
              (##+ r y)))))

  (define (inexact-modulo x y)
    (let ((exact-y (##inexact->exact y)))
      (if (##eq? exact-y 0)
          (divide-by-zero-error)
          (##exact->inexact
           (##modulo (##inexact->exact x) exact-y)))))

  (macro-number-dispatch y (type-error-on-y)

    (macro-number-dispatch x (type-error-on-x) ;; y = fixnum
      (cond ((##fixnum.= y 0)
             (divide-by-zero-error))
            (else
             (##fixnum.modulo x y)))
      (cond ((##fixnum.= y 0)
             (divide-by-zero-error))
            (else
             (exact-modulo x y)))
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (inexact-modulo x y)
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (inexact-modulo x y)
          (type-error-on-x)))

    (macro-number-dispatch x (type-error-on-x) ;; y = bignum
      (exact-modulo x y)
      (exact-modulo x y)
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (inexact-modulo x y)
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (inexact-modulo x y)
          (type-error-on-x)))

    (type-error-on-y) ;; y = ratnum

    (macro-number-dispatch x (type-error-on-x) ;; y = flonum
      (if (macro-flonum-int? y)
          (inexact-modulo x y)
          (type-error-on-y))
      (if (macro-flonum-int? y)
          (inexact-modulo x y)
          (type-error-on-y))
      (type-error-on-x)
      (if (macro-flonum-int? x)
          (if (macro-flonum-int? y)
              (inexact-modulo x y)
              (type-error-on-y))
          (type-error-on-x))
      (if (macro-cpxnum-int? x)
          (if (macro-flonum-int? y)
              (inexact-modulo x y)
              (type-error-on-y))
          (type-error-on-x)))

    (if (macro-cpxnum-int? y) ;; y = cpxnum
        (macro-number-dispatch x (type-error-on-x)
          (inexact-modulo x y)
          (inexact-modulo x y)
          (type-error-on-x)
          (if (macro-flonum-int? x)
              (inexact-modulo x y)
              (type-error-on-x))
          (if (macro-cpxnum-int? x)
              (inexact-modulo x y)
              (type-error-on-x)))
        (type-error-on-y))))

(define-prim (modulo x y)
  (macro-force-vars (x y)
    (##modulo x y)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; gcd, lcm

(define-prim (##gcd x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (define (##fast-gcd u v)

    ;; See the paper "Fast Reduction and Composition of Binary
    ;; Quadratic Forms" by Arnold Schoenhage.  His algorithm and proof
    ;; are derived from, and basically the same for, his Controlled
    ;; Euclidean Descent algorithm for gcd, which he has never
    ;; published.  This algorithm has complexity log N times a
    ;; constant times the complexity of a multiplication of the same
    ;; size.  We don't use it until we get to about 6800 bits.  Note
    ;; that this is the same place that we start using FFT
    ;; multiplication and fast division with Newton's method for
    ;; finding inverses.

    ;; Niels Mo"ller has written two papers about an improved version
    ;; of this algorithm.

    ;; assumes u and v are nonnegative exact ints

    (define (make-gcd-matrix A_11 A_12
                             A_21 A_22)
      (##vector A_11 A_12
                A_21 A_22))

    (define (gcd-matrix_11 A)
      (##vector-ref A 0))

    (define (gcd-matrix_12 A)
      (##vector-ref A 1))

    (define (gcd-matrix_21 A)
      (##vector-ref A 2))

    (define (gcd-matrix_22 A)
      (##vector-ref A 3))

    (define (make-gcd-vector v_1 v_2)
      (##vector v_1 v_2))

    (define (gcd-vector_1 v)
      (##vector-ref v 0))

    (define (gcd-vector_2 v)
      (##vector-ref v 1))

    (define gcd-matrix-identity '#(1 0
                                     0 1))

    (define (gcd-matrix-multiply A B)
      (cond ((##eq? A gcd-matrix-identity)
             B)
            ((##eq? B gcd-matrix-identity)
             A)
            (else
             (let ((A_11 (gcd-matrix_11 A)) (A_12 (gcd-matrix_12 A))
                   (A_21 (gcd-matrix_21 A)) (A_22 (gcd-matrix_22 A))
                   (B_11 (gcd-matrix_11 B)) (B_12 (gcd-matrix_12 B))
                   (B_21 (gcd-matrix_21 B)) (B_22 (gcd-matrix_22 B)))
               (make-gcd-matrix (##+ (##* A_11 B_11)
                                     (##* A_12 B_21))
                                (##+ (##* A_11 B_12)
                                     (##* A_12 B_22))
                                (##+ (##* A_21 B_11)
                                     (##* A_22 B_21))
                                (##+ (##* A_21 B_12)
                                     (##* A_22 B_22)))))))

    (define (gcd-matrix-multiply-strassen A B)
      ;; from http://mathworld.wolfram.com/StrassenFormulas.html
      (cond ((##eq? A gcd-matrix-identity)
             B)
            ((##eq? B gcd-matrix-identity)
             A)
            (else
             (let ((A_11 (gcd-matrix_11 A)) (A_12 (gcd-matrix_12 A))
                   (A_21 (gcd-matrix_21 A)) (A_22 (gcd-matrix_22 A))
                   (B_11 (gcd-matrix_11 B)) (B_12 (gcd-matrix_12 B))
                   (B_21 (gcd-matrix_21 B)) (B_22 (gcd-matrix_22 B)))
               (let ((Q_1 (##* (##+ A_11 A_22) (##+ B_11 B_22)))
                     (Q_2 (##* (##+ A_21 A_22) B_11))
                     (Q_3 (##* A_11 (##- B_12 B_22)))
                     (Q_4 (##* A_22 (##- B_21 B_11)))
                     (Q_5 (##* (##+ A_11 A_12) B_22))
                     (Q_6 (##* (##- A_21 A_11) (##+ B_11 B_12)))
                     (Q_7 (##* (##- A_12 A_22) (##+ B_21 B_22))))
                 (make-gcd-matrix (##+ (##+ Q_1 Q_4) (##- Q_7 Q_5))
                                  (##+ Q_3 Q_5)
                                  (##+ Q_2 Q_4)
                                  (##+ (##+ Q_1 Q_3) (##- Q_6 Q_2))))))))

    (define (gcd-matrix-solve A y)
      (let ((y_1 (gcd-vector_1 y))
            (y_2 (gcd-vector_2 y)))
        (make-gcd-vector (##- (##* y_1 (gcd-matrix_22 A))
                              (##* y_2 (gcd-matrix_12 A)))
                         (##- (##* y_2 (gcd-matrix_11 A))
                              (##* y_1 (gcd-matrix_21 A))))))

    (define (x>=2^n x n)
      (cond ((##eq? x 0)
             #f)
            ((and (##fixnum? x)
                  (##fixnum.<= n ##bignum.mdigit-width))
             (##fixnum.>= x (##fixnum.arithmetic-shift-left 1 n)))
            (else
             (let ((x (if (##fixnum? x) (##bignum.<-fixnum x) x)))
               (let loop ((i (##fixnum.- (##bignum.mdigit-length x) 1)))
                 (let ((digit (##bignum.mdigit-ref x i)))
                   (if (##fixnum.zero? digit)
                       (loop (##fixnum.- i 1))
                       (let ((words (##fixnum.quotient n ##bignum.mdigit-width)))
                         (or (##fixnum.> i words)
                             (and (##fixnum.= i words)
                                  (##fixnum.>= digit
                                               (##fixnum.arithmetic-shift-left
                                                1
                                                (##fixnum.remainder n ##bignum.mdigit-width)))))))))))))

    (define (determined-minimal? u v s)
      ;; assumes  2^s <= u , v; s>= 0 fixnum
      ;; returns #t if we can determine that |u-v|<2^s
      ;; at least one of u and v is a bignum
      (let ((u (if (##fixnum? u) (##bignum.<-fixnum u) u))
            (v (if (##fixnum? v) (##bignum.<-fixnum v) v)))
        (let ((u-length (##bignum.mdigit-length u)))
          (and (##fixnum.= u-length (##bignum.mdigit-length v))
               (let loop ((i (##fixnum.- u-length 1)))
                 (let ((v-digit (##bignum.mdigit-ref v i))
                       (u-digit (##bignum.mdigit-ref u i)))
                   (if (and (##fixnum.zero? u-digit)
                            (##fixnum.zero? v-digit))
                       (loop (##fixnum.- i 1))
                       (and (##fixnum.= (##fixnum.quotient s ##bignum.mdigit-width)
                                        i)
                            (##fixnum.< (##fixnum.max (##fixnum.- u-digit v-digit)
                                                      (##fixnum.- v-digit u-digit))
                                        (##fixnum.arithmetic-shift-left
                                         1
                                         (##fixnum.remainder s ##bignum.mdigit-width)))))))))))

    (define (gcd-small-step cont M u v s)
      ;;  u, v >= 2^s
      ;; M is the matrix product of the partial sums of
      ;; the continued fraction representation of a/b so far
      ;; returns updated M, u, v, and a truth value
      ;;  u, v >= 2^s and
      ;; if last return value is #t, we know that
      ;; (- (max u v) (min u v)) < 2^s, i.e, u, v are minimal above 2^s

      (define (gcd-matrix-multiply-low M q)
        (let ((M_11 (gcd-matrix_11 M))
              (M_12 (gcd-matrix_12 M))
              (M_21 (gcd-matrix_21 M))
              (M_22 (gcd-matrix_22 M)))
          (make-gcd-matrix (##+ M_11 (##* q M_12))  M_12
                           (##+ M_21 (##* q M_22))  M_22)))

      (define (gcd-matrix-multiply-high M q)
        (let ((M_11 (gcd-matrix_11 M))
              (M_12 (gcd-matrix_12 M))
              (M_21 (gcd-matrix_21 M))
              (M_22 (gcd-matrix_22 M)))
          (make-gcd-matrix M_11  (##+ (##* q M_11) M_12)
                           M_21  (##+ (##* q M_21) M_22))))

      (if (or (##bignum? u)
              (##bignum? v))

          ;; if u and v are nearly equal bignums, the two ##<
          ;; following this condition could take O(N) time to compute.
          ;; When this happens, however, it will be likely that
          ;; determined-minimal? will return true.

          (cond ((determined-minimal? u v s)
                 (cont M
                       u
                       v
                       #t))
                ((##< u v)
                 (let* ((qr (##exact-int.div v u))
                        (q (##car qr))
                        (r (##cdr qr)))
                   (cond ((x>=2^n r s)
                          (cont (gcd-matrix-multiply-low M q)
                                u
                                r
                                #f))
                         ((##eq? q 1)
                          (cont M
                                u
                                v
                                #t))
                         (else
                          (cont (gcd-matrix-multiply-low M (##- q 1))
                                u
                                (##+ r u)
                                #t)))))
                ((##< v u)
                 (let* ((qr (##exact-int.div u v))
                        (q (##car qr))
                        (r (##cdr qr)))
                   (cond ((x>=2^n r s)
                          (cont (gcd-matrix-multiply-high M q)
                                r
                                v
                                #f))
                         ((##eq? q 1)
                          (cont M
                                u
                                v
                                #t))
                         (else
                          (cont (gcd-matrix-multiply-high M (##- q 1))
                                (##+ r v)
                                v
                                #t)))))
                (else
                 (cont M
                       u
                       v
                       #t)))
          ;; here u and v are fixnums, so 2^s, which is <= u and v, is
          ;; also a fixnum
          (let ((two^s (##fixnum.arithmetic-shift-left 1 s)))
            (if (##fixnum.< u v)
                (if (##fixnum.< (##fixnum.- v u) two^s)
                    (cont M
                          u
                          v
                          #t)
                    (let ((r (##fixnum.remainder v u))
                          (q (##fixnum.quotient  v u)))
                      (if (##fixnum.>= r two^s)
                          (cont (gcd-matrix-multiply-low M q)
                                u
                                r
                                #f)
                          ;; the case when q is one and the remainder is < two^s
                          ;; is covered in the first test
                          (cont (gcd-matrix-multiply-low M (##fixnum.- q 1))
                                u
                                (##fixnum.+ r u)
                                #t))))
                ;; here u >= v, but the case u = v is covered by the first test
                (if (##fixnum.< (##fixnum.- u v) two^s)
                    (cont M
                          u
                          v
                          #t)
                    (let ((r (##fixnum.remainder u v))
                          (q (##fixnum.quotient  u v)))
                      (if (##fixnum.>= r two^s)
                          (cont (gcd-matrix-multiply-high M q)
                                r
                                v
                                #f)
                          ;; the case when q is one and the remainder is < two^s
                          ;; is covered in the first test
                          (cont (gcd-matrix-multiply-high M (##fixnum.- q 1))
                                (##fixnum.+ r v)
                                v
                                #t))))))))

    (define (gcd-middle-step cont a b h m-prime cont-needs-M?)
      ((lambda (cont)
         (if (and (x>=2^n a h)
                  (x>=2^n b h))
             (MR cont a b h cont-needs-M?)
             (cont gcd-matrix-identity a b)))
       (lambda (M x y)
         (let loop ((M M)
                    (x x)
                    (y y))
           (if (or (x>=2^n x h)
                   (x>=2^n y h))
               ((lambda (cont) (gcd-small-step cont M x y m-prime))
                (lambda (M x y minimal?)
                  (if minimal?
                      (cont M x y)
                      (loop M x y))))
               ((lambda (cont) (MR cont x y m-prime cont-needs-M?))
                (lambda (M-prime alpha beta)
                  (cont (if cont-needs-M?
                            (if (##fixnum.> (##fixnum.- h m-prime) 1024)
                                ;; here we trade off 1 multiplication
                                ;; for 21 additions
                                (gcd-matrix-multiply-strassen M M-prime)
                                (gcd-matrix-multiply          M M-prime))
                            gcd-matrix-identity)
                        alpha
                        beta))))))))

    (define (MR cont a b m cont-needs-M?)
      ((lambda (cont)
         (if (and (x>=2^n a (##fixnum.+ m 2))
                  (x>=2^n b (##fixnum.+ m 2)))
             (let ((n (##fixnum.- (##fixnum.max (##integer-length a)
                                                (##integer-length b))
                                  m)))
               ((lambda (cont)
                  (if (##fixnum.<= m n)
                      (cont m 0)
                      (cont n (##fixnum.- (##fixnum.+ m 1) n))))
                (lambda (m-prime p)
                  (let ((h (##fixnum.+ m-prime (##fixnum.quotient n 2))))
                    (if (##fixnum.< 0 p)
                        (let ((a   (##arithmetic-shift a (##fixnum.- p)))
                              (b   (##arithmetic-shift b (##fixnum.- p)))
                              (a_0 (##extract-bit-field p 0 a))
                              (b_0 (##extract-bit-field p 0 b)))
                          ((lambda (cont)
                             (gcd-middle-step cont a b h m-prime #t))
                           (lambda (M alpha beta)
                             (let ((M-inverse-v_0 (gcd-matrix-solve M (make-gcd-vector a_0 b_0))))
                               (cont (if cont-needs-M? M gcd-matrix-identity)
                                     (##+ (##arithmetic-shift alpha p)
                                          (gcd-vector_1 M-inverse-v_0))
                                     (##+ (##arithmetic-shift beta p)
                                          (gcd-vector_2 M-inverse-v_0)))))))
                        (gcd-middle-step cont a b h m-prime cont-needs-M?))))))
             (cont gcd-matrix-identity
                   a
                   b)))
       (lambda (M alpha beta)
         (let loop ((M M)
                    (alpha alpha)
                    (beta beta)
                    (minimal? #f))
           (if minimal?
               (cont M alpha beta)
               (gcd-small-step loop M alpha beta m))))))

    ((lambda (cont)
       (if (and (use-fast-bignum-algorithms)
                (##bignum? u)
                (##bignum? v)
                (x>=2^n u ##bignum.fast-gcd-size)
                (x>=2^n v ##bignum.fast-gcd-size))
           (MR cont u v ##bignum.fast-gcd-size #f)
           (cont 0 u v)))
     (lambda (M a b)
       (general-base a b))))

  (define (general-base a b)
    (##declare (not interrupts-enabled))
    (if (##eq? b 0)
        a
        (if (##fixnum? b)
            (fixnum-base b (##remainder a b))
            (general-base b (##remainder a b)))))

  (define (fixnum-base a b)
    (##declare (not interrupts-enabled))
    (if (##eq? b 0)
        a
        (let ((a b)
              (b (##fixnum.remainder a b)))
          (if (##eq? b 0)
              a
              (fixnum-base b (##fixnum.remainder a b))))))

  (define (exact-gcd x y)
    (let ((x (##abs x))
          (y (##abs y)))
      (cond ((##eq? x 0)
             y)
            ((##eq? y 0)
             x)
            ((and (##fixnum? x) (##fixnum? y))
             (fixnum-base x y))
            (else
             (let ((x-first-bit (##first-bit-set x))
                   (y-first-bit (##first-bit-set y)))
               (##arithmetic-shift
                (##fast-gcd (##arithmetic-shift x (##fixnum.- x-first-bit))
                            (##arithmetic-shift y (##fixnum.- y-first-bit)))
                (##fixnum.min x-first-bit y-first-bit)))))))

  (define (inexact-gcd x y)
    (##exact->inexact
     (exact-gcd (##inexact->exact x)
                (##inexact->exact y))))

  (cond ((##not (##integer? x))
         (type-error-on-x))
        ((##not (##integer? y))
         (type-error-on-y))
        ((##eq? x y)
         (##abs x))
        (else
         (if (and (##exact? x) (##exact? y))
             (exact-gcd x y)
             (inexact-gcd x y)))))

(define-prim-nary (gcd x y)
  0
  (if (##integer? x) (##abs x) '(1))
  (##gcd x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-integer))

(define-prim (##lcm x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (define (exact-lcm x y)
    (if (or (##eq? x 0) (##eq? y 0))
        0
        (##abs (##* (##quotient x (##gcd x y))
                    y))))

  (define (inexact-lcm x y)
    (##exact->inexact
     (exact-lcm (##inexact->exact x)
                (##inexact->exact y))))

  (cond ((##not (##integer? x))
         (type-error-on-x))
        ((##not (##integer? y))
         (type-error-on-y))
        (else
         (if (and (##exact? x) (##exact? y))
             (exact-lcm x y)
             (inexact-lcm x y)))))

(define-prim-nary (lcm x y)
  1
  (if (##integer? x) (##abs x) '(1))
  (##lcm x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-integer))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; numerator, denominator

(define-prim (##numerator x)

  (define (type-error)
    (##fail-check-rational 1 numerator x))

  (macro-number-dispatch x (type-error)
    x
    x
    (macro-ratnum-numerator x)
    (cond ((##flonum.zero? x)
           x)
          ((macro-flonum-rational? x)
           (##exact->inexact (##numerator (##flonum.inexact->exact x))))
          (else
           (type-error)))
    (if (macro-cpxnum-rational? x)
        (##numerator (macro-cpxnum-real x))
        (type-error))))

(define-prim (numerator x)
  (macro-force-vars (x)
    (##numerator x)))

(define-prim (##denominator x)

  (define (type-error)
    (##fail-check-rational 1 denominator x))

  (macro-number-dispatch x (type-error)
    1
    1
    (macro-ratnum-denominator x)
    (if (macro-flonum-rational? x)
        (##exact->inexact (##denominator (##flonum.inexact->exact x)))
        (type-error))
    (if (macro-cpxnum-rational? x)
        (##denominator (macro-cpxnum-real x))
        (type-error))))

(define-prim (denominator x)
  (macro-force-vars (x)
    (##denominator x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; floor, ceiling, truncate, round

(define-prim (##floor x)

  (define (type-error)
    (##fail-check-finite-real 1 floor x))

  (macro-number-dispatch x (type-error)
    x
    x
    (let ((num (macro-ratnum-numerator x))
          (den (macro-ratnum-denominator x)))
      (if (##negative? num)
          (##quotient (##- num (##- den 1)) den)
          (##quotient num den)))
    (if (##flonum.finite? x)
        (##flonum.floor x)
        (type-error))
    (if (macro-cpxnum-real? x)
        (##floor (macro-cpxnum-real x))
        (type-error))))

(define-prim (floor x)
  (macro-force-vars (x)
    (##floor x)))

(define-prim (##ceiling x)

  (define (type-error)
    (##fail-check-finite-real 1 ceiling x))

  (macro-number-dispatch x (type-error)
    x
    x
    (let ((num (macro-ratnum-numerator x))
          (den (macro-ratnum-denominator x)))
      (if (##negative? num)
          (##quotient num den)
          (##quotient (##+ num (##- den 1)) den)))
    (if (##flonum.finite? x)
        (##flonum.ceiling x)
        (type-error))
    (if (macro-cpxnum-real? x)
        (##ceiling (macro-cpxnum-real x))
        (type-error))))

(define-prim (ceiling x)
  (macro-force-vars (x)
    (##ceiling x)))

(define-prim (##truncate x)

  (define (type-error)
    (##fail-check-finite-real 1 truncate x))

  (macro-number-dispatch x (type-error)
    x
    x
    (##quotient (macro-ratnum-numerator x)
                (macro-ratnum-denominator x))
    (if (##flonum.finite? x)
        (##flonum.truncate x)
        (type-error))
    (if (macro-cpxnum-real? x)
        (##truncate (macro-cpxnum-real x))
        (type-error))))

(define-prim (truncate x)
  (macro-force-vars (x)
    (##truncate x)))

(define-prim (##round x)

  (define (type-error)
    (##fail-check-finite-real 1 round x))

  (macro-number-dispatch x (type-error)
    x
    x
    (##ratnum.round x)
    (if (##flonum.finite? x)
        (##flonum.round x)
        (type-error))
    (if (macro-cpxnum-real? x)
        (##round (macro-cpxnum-real x))
        (type-error))))

(define-prim (round x)
  (macro-force-vars (x)
    (##round x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; rationalize

(define-prim (##rationalize x y)

  (define (simplest-rational1 x y)
    (if (##< y x)
        (simplest-rational2 y x)
        (simplest-rational2 x y)))

  (define (simplest-rational2 x y)
    (cond ((##not (##< x y))
           x)
          ((##positive? x)
           (simplest-rational3 x y))
          ((##negative? y)
           (##negate (simplest-rational3 (##negate y) (##negate x))))
          (else
           0)))

  (define (simplest-rational3 x y)
    (let ((fx (##floor x))
          (fy (##floor y)))
      (cond ((##not (##< fx x))
             fx)
            ((##= fx fy)
             (##+ fx
                  (##inverse
                   (simplest-rational3
                    (##inverse (##- y fy))
                    (##inverse (##- x fx))))))
            (else
             (##+ fx 1)))))

  (cond ((##not (##rational? x))
         (##fail-check-finite-real 1 rationalize x y))
        ((and (##flonum? y)
              (##flonum.= y (macro-inexact-+inf)))
         (macro-inexact-+0))
        ((##not (##rational? y))
         (##fail-check-real 2 rationalize x y))
        ((##negative? y)
         (##raise-range-exception 2 rationalize x y))
        ((and (##exact? x) (##exact? y))
         (simplest-rational1 (##- x y) (##+ x y)))
        (else
         (let ((exact-x (##inexact->exact x))
               (exact-y (##inexact->exact y)))
           (##exact->inexact
            (simplest-rational1 (##- exact-x exact-y)
                                (##+ exact-x exact-y)))))))

(define-prim (rationalize x y)
  (macro-force-vars (x y)
    (##rationalize x y)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; trigonometry and complex numbers

(define-prim (##exp x)

  (define (type-error)
    (##fail-check-number 1 exp x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        1
        (##flonum.exp (##flonum.<-fixnum x)))
    (##flonum.exp (##flonum.<-exact-int x))
    (##flonum.exp (##flonum.<-ratnum x))
    (##flonum.exp x)
    (##make-polar (##exp (macro-cpxnum-real x))
                  (macro-cpxnum-imag x))))

(define-prim (exp x)
  (macro-force-vars (x)
    (##exp x)))

(define-prim (##flonum.full-precision? x)
  (let ((y (##flonum.abs x)))
    (and (##fl< y (macro-inexact-+inf))
         (##fl<= (macro-flonum-min-normal) y))))

(define-prim (##log x)

  (define (type-error)
    (##fail-check-number 1 log x))

  (define (range-error)
    (##raise-range-exception 1 log x))

  (define (negative-log x)
    (##make-rectangular (##log (##negate x)) (macro-inexact-+pi)))

  (define (exact-log x)

    ;; x is positive, x is not 1.
    
    ;; There are three places where just converting to a flonum and
    ;; taking the flonum logarithm doesn't work well.
    ;; 1. Overflow in the conversion
    ;; 2. Underflow in the conversion (or even loss of precision
    ;;    because of a denormalized conversion result)
    ;; 3. When the number is close to 1.

    (let ((float-x (##exact->inexact x)))
      (cond ((##= x float-x)
             (##fllog float-x)) ;; first, we trust the builtin flonum log

            ((##not (##flonum.full-precision? float-x))
             
             ;; direct conversion to flonum could incur massive relative
             ;; rounding errors, or would just lead to an infinite result
             ;; so we tolerate more than one rounding error in the calculation
             
             (let* ((wn (##integer-length (##numerator x)))
                    (wd (##integer-length (##denominator x)))
                    (p  (##fx- wn wd))
                    (float-p (##flonum.<-fixnum p))
                    (partial-result (##fllog 
                                     (##exact->inexact
                                      (##* x (##expt 2 (##fx- p)))))))
               (##fl+ (##fl* float-p
                             (macro-inexact-log-2))
                      partial-result)))

            ((or (##fl< (macro-inexact-exp-+1/2) float-x)
                 (##fl< float-x (macro-inexact-exp--1/2)))

             ;; here the absolute value of the logarithm is at least 0.5,
             ;; so there is less rounding error in the final result.

             (##flonum.log float-x))

            (else

             ;; for rational numbers near one, we use the taylor
             ;; series for (log (/ (- x 1) (+ x 1))) by hand.
             ;; we first approximate (/ (- x 1) (+ x 1)) by a dyadic
             ;; rational with (macro-flonum-m-bits-plus-1*2) bits accuracy

             (let* ((y (##/ (##- x 1) (##+ x 1)))
                    (normalizer (##expt 2 (##fx+ (macro-flonum-m-bits-plus-1*2)
                                                 (##fx- (##integer-length (##denominator y))
                                                        (##integer-length (##numerator   y))))))    
                    (dyadic-y (##/ (##round (##* y normalizer))
                                   normalizer))
                    (dyadic-y^2 (##* dyadic-y dyadic-y))
                    (bits-gained-per-loop (##fx- (##integer-length (##denominator dyadic-y^2))
                                                 (##integer-length (##numerator   dyadic-y^2))
                                                 1)))
               (let loop ((k 0)
                          (y^2k+1 dyadic-y)
                          (result dyadic-y)
                          (accuracy bits-gained-per-loop))
                 (if (##fx< (macro-flonum-m-bits-plus-1*2) accuracy)
                     (##flonum.<-ratnum (##* 2 result))
                     (let ((y^2k+1 (##* dyadic-y^2 y^2k+1))
                           (k (##fx+ k 1)))
                       (loop k
                             y^2k+1
                             (##+ result (##/ y^2k+1 (##fx+ (##fx* 2 k) 1)))
                             (##fx+ accuracy bits-gained-per-loop))))))))))
  
  (define (complex-log-magnitude x)

    (define (log-mag a b)    
      ;; both are finite, 0 <= a <= b, b is nonzero
      (let* ((c (##/ a b))
             (approx-mag (##* b (##sqrt (##+ 1 (##* c c))))))
        (if (or (##exact? approx-mag)
                (and (##flonum.full-precision? approx-mag)
                     (or (##fl< (macro-inexact-exp-+1/2) approx-mag)
                         (##fl< approx-mag (macro-inexact-exp--1/2)))))
            ;; log composed with magnitude will compute a relatively accurate answer
            (##log approx-mag)
            (let ((a (##inexact->exact a))
                  (b (##inexact->exact b)))
              (##* 1/2 (exact-log (##+ (##* a a) (##* b b))))))))
    
    (let ((abs-r (##abs (##real-part x)))
          (abs-i (##abs (##imag-part x))))
      
      ;; abs-i is not exact 0
      (cond ((or (and (##flonum? abs-r)
                      (##flonum.= abs-r (macro-inexact-+inf)))
                 (and (##flonum? abs-i)
                      (##flonum.= abs-i (macro-inexact-+inf))))
             (macro-inexact-+inf))
            ;; neither abs-r or abs-i is infinite
            ((and (##flonum? abs-r)
                  (##flonum.nan? abs-r))
             abs-r)
            ;; abs-r is not a NaN
            ((and (##flonum? abs-i)
                  (##flonum.nan? abs-i))
             abs-i)
            ;; abs-i is not a NaN
            ((##eq? abs-r 0)
             (##log abs-i))
            ;; abs-r is not exact 0
            ((and (##zero? abs-r)
                  (##zero? abs-i))
             (macro-inexact--inf))
            ;; abs-i and abs-r are not both zero
            (else
             (if (##< abs-r abs-i)
                 (log-mag abs-r abs-i)
                 (log-mag abs-i abs-r))))))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        (range-error)
        (if (##fixnum.negative? x)
            (negative-log x)
            (if (##eq? x 1)
                0
                (exact-log x))))
    (if (##bignum.negative? x)
        (negative-log x)
        (exact-log x))
    (if (##negative? (macro-ratnum-numerator x))
        (negative-log x)
        (exact-log x))
    (if (or (##flonum.nan? x)
            (##not (##flonum.negative?
                    (##flonum.copysign (macro-inexact-+1) x))))
        (##flonum.log x)
        (negative-log x))
    (##make-rectangular (complex-log-magnitude x) (##angle x))))

(define-prim (log x)
  (macro-force-vars (x)
    (##log x)))

(define-prim (##sin x)

  (define (type-error)
    (##fail-check-number 1 sin x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        0
        (##flonum.sin (##flonum.<-fixnum x)))
    (##flonum.sin (##flonum.<-exact-int x))
    (##flonum.sin (##flonum.<-ratnum x))
    (##flonum.sin x)
    (##/ (##- (##exp (##make-rectangular
                      (##negate (macro-cpxnum-imag x))
                      (macro-cpxnum-real x)))
              (##exp (##make-rectangular
                      (macro-cpxnum-imag x)
                      (##negate (macro-cpxnum-real x)))))
         (macro-cpxnum-+2i))))

(define-prim (sin x)
  (macro-force-vars (x)
    (##sin x)))

(define-prim (##cos x)

  (define (type-error)
    (##fail-check-number 1 cos x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        1
        (##flonum.cos (##flonum.<-fixnum x)))
    (##flonum.cos (##flonum.<-exact-int x))
    (##flonum.cos (##flonum.<-ratnum x))
    (##flonum.cos x)
    (##/ (##+ (##exp (##make-rectangular
                      (##negate (macro-cpxnum-imag x))
                      (macro-cpxnum-real x)))
              (##exp (##make-rectangular
                      (macro-cpxnum-imag x)
                      (##negate (macro-cpxnum-real x)))))
         2)))

(define-prim (cos x)
  (macro-force-vars (x)
    (##cos x)))

(define-prim (##tan x)

  (define (type-error)
    (##fail-check-number 1 tan x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        0
        (##flonum.tan (##flonum.<-fixnum x)))
    (##flonum.tan (##flonum.<-exact-int x))
    (##flonum.tan (##flonum.<-ratnum x))
    (##flonum.tan x)
    (let ((a (##exp (##make-rectangular
                     (##negate (macro-cpxnum-imag x))
                     (macro-cpxnum-real x))))
          (b (##exp (##make-rectangular
                     (macro-cpxnum-imag x)
                     (##negate (macro-cpxnum-real x))))))
      (let ((c (##/ (##- a b) (##+ a b))))
        (##make-rectangular (##imag-part c) (##negate (##real-part c)))))))

(define-prim (tan x)
  (macro-force-vars (x)
    (##tan x)))

(define-prim (##asin x)

  (define (type-error)
    (##fail-check-number 1 asin x))

  (define (safe-case x)
    (##* (macro-cpxnum--i)
         (##log (##+ (##* (macro-cpxnum-+i) x)
                     (##sqrt (##- 1 (##* x x)))))))

  (define (unsafe-case x)
    (##negate (safe-case (##negate x))))

  (define (real-case x)
    (cond ((##< x -1)
           (unsafe-case x))
          ((##< 1 x)
           (safe-case x))
          (else
           (##flonum.asin (##exact->inexact x)))))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        0
        (real-case x))
    (real-case x)
    (real-case x)
    (real-case x)
    (let ((imag (macro-cpxnum-imag x)))
      (if (or (##positive? imag)
              (and (##flonum? imag)
                   (##flonum.zero? imag)
                   (##negative? (macro-cpxnum-real x))))
          (unsafe-case x)
          (safe-case x)))))

(define-prim (asin x)
  (macro-force-vars (x)
    (##asin x)))

(define-prim (##acos x)

  (define (type-error)
    (##fail-check-number 1 acos x))

  (define (complex-case x)
    (##- (macro-inexact-+pi/2) (##asin x)))

  (define (real-case x)
    (if (or (##< x -1) (##< 1 x))
        (complex-case x)
        (##flonum.acos (##exact->inexact x))))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        (macro-inexact-+pi/2)
        (real-case x))
    (real-case x)
    (real-case x)
    (real-case x)
    (complex-case x)))

(define-prim (acos x)
  (macro-force-vars (x)
    (##acos x)))

(define-prim (##atan x)

  (define (type-error)
    (##fail-check-number 1 atan x))

  (define (range-error)
    (##raise-range-exception 1 atan x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.zero? x)
        0
        (##flonum.atan (##flonum.<-fixnum x)))
    (##flonum.atan (##flonum.<-exact-int x))
    (##flonum.atan (##flonum.<-ratnum x))
    (##flonum.atan x)
    (let ((real (macro-cpxnum-real x))
          (imag (macro-cpxnum-imag x)))
      (if (and (##eq? real 0) (##eq? imag 1))
          (range-error)
          (let ((a (##make-rectangular (##negate imag) real)))
            (##/ (##- (##log (##+ a 1)) (##log (##- 1 a)))
                 (macro-cpxnum-+2i)))))))

(define-prim (##atan2 y x)

  (define (flonum-substitute x)
    (cond ((##flonum? x)
           x)
          ((##eq? x 0)
           0.)
          ((##positive? x)
           1.)
          (else
           -1.)))

  (define (irregular-flonum? x)
    (and (##flonum? x)
         (or (##flonum.zero? x)
             (##not (##flfinite? x)))))

  (cond ((##eq? 0 y)
         (if (##exact? x)
             (if (##negative? x)
                 (macro-inexact-+pi)
                 0)
             (if (##negative? (##flonum.copysign (macro-inexact-+1) x))
                 (macro-inexact-+pi)
                 0.)))
        ((or (irregular-flonum? x)
             (irregular-flonum? y))
         (##flonum.atan (flonum-substitute y)
                        (flonum-substitute x)))
        (else
         (let ((inexact-x (##exact->inexact x))
               (inexact-y (##exact->inexact y)))
           (if (and (or (##flonum? x)
                        (##flonum.full-precision? inexact-x)
                        (##= x inexact-x))
                    (or (##flonum? y)
                        (##flonum.full-precision? inexact-y)
                        (##= y inexact-y)))
               (##flonum.atan inexact-y inexact-x)
               ;; at least one of x or y is nonzero
               ;; and at least one of them is not a flonum
               (let* ((exact-x (##inexact->exact x))
                      (exact-y (##inexact->exact y))
                      (max-arg (##max (##abs exact-x)
                                      (##abs exact-y)))
                      (normalizer (##expt 2 (##- (##integer-length (##denominator max-arg))
                                                 (##integer-length (##numerator   max-arg))))))
                 ;; now the largest argument will be about 1.
                 (##flonum.atan (##exact->inexact (##* normalizer exact-y))
                                (##exact->inexact (##* normalizer exact-x)))))))))

(define-prim (atan x #!optional (y (macro-absent-obj)))
  (macro-force-vars (x)
    (if (##eq? y (macro-absent-obj))
        (##atan x)
        (macro-force-vars (y)
          (cond ((##not (##real? x))
                 (##fail-check-real 1 atan x y))
                ((##not (##real? y))
                 (##fail-check-real 2 atan x y))
                (else
                 (##atan2 x y)))))))

(define-prim (##sqrt x)

  (define (type-error)
    (##fail-check-number 1 sqrt x))

  (define (exact-int-sqrt x)
    (if (##negative? x)
        (##make-rectangular 0 (exact-int-sqrt (##negate x)))
        (let ((y (##exact-int.sqrt x)))
          (cond ((##eq? (##cdr y) 0)
                 (##car y))
                ((if (##fixnum? x)
                     (or (##not (##fixnum? (macro-flonum-+m-max-plus-1)))
                         (##fixnum.<= x (macro-flonum-+m-max-plus-1)))
                     (and (##not (##fixnum? (macro-flonum-+m-max-plus-1)))
                          (##not (##bignum.< (macro-flonum-+m-max-plus-1) x))))
                 ;; 0 <= x <= (macro-flonum-+m-max-plus-1), can be
                 ;; converted to flonum exactly so avoids double
                 ;; rounding in next expression this has a relatively
                 ;; fast path for small integers.
                 (##flonum.sqrt
                  (if (##fixnum? x)
                      (##flonum.<-fixnum x)
                      (##flonum.<-exact-int x))))
                ((##not (##< (##car y) (macro-flonum-+m-max-plus-1)))
                 ;; ##flonum.<-exact-int uses second argument correctly
                 (##flonum.<-exact-int (##car y) #t))
                (else
                 ;; The integer part of y does not have enough bits accuracy
                 ;; to round it correctly to a flonum, so to
                 ;; make sure (##car y) is big enough in the next call we
                 ;; multiply by (expt 2 (macro-flonum-m-bits-plus-1*2)),
                 ;; which is somewhat extravagant;
                 ;; (expt 2 (+ 1 (macro-flonum-m-bits-plus-1))) should
                 ;; work fine.
                 (##flonum.* (macro-flonum-inverse-+m-max-plus-1-inexact)
                             (exact-int-sqrt
                              (##arithmetic-shift
                               x
                               (macro-flonum-m-bits-plus-1*2)))))))))

  (define (ratnum-sqrt x)
    (if (##negative? x)
        (##make-rectangular 0 (ratnum-sqrt (##negate x)))
        (let ((p (macro-ratnum-numerator x))
              (q (macro-ratnum-denominator x)))
          (let ((sqrt-p (##exact-int.sqrt p))
                (sqrt-q (##exact-int.sqrt q)))
            (if (and (##zero? (##cdr sqrt-p))
                     (##zero? (##cdr sqrt-q)))
                ;; both (abs p) and q are perfect squares and
                ;; their square roots do not have any common factors
                (macro-ratnum-make (##car sqrt-p)
                                   (##car sqrt-q))
                (let ((wp (##integer-length p))
                      (wq (##integer-length q)))

                  ;; for IEEE 754 double precision, we need at least
                  ;; 53 or 54 (I can't seem to work it out) of the
                  ;; leading bits of (sqrt (/ p q)).  Here we get
                  ;; about 64 leading bits.  We just shift p (either
                  ;; right or left) until it is about 128 bits longer
                  ;; than q (shift must be even), then take the
                  ;; integer square root of the result.

                  (let* ((shift
                          (##fixnum.arithmetic-shift-left
                           (##fixnum.arithmetic-shift-right
                            (##fixnum.- 128 (##fixnum.- wp wq))
                            1)
                           1))
                         (leading-bits
                          (##car
                           (##exact-int.sqrt
                            (##quotient 
                             (##arithmetic-shift p shift)
                             q))))
                         (pre-rounded-result
                          (if (##fixnum.negative? shift)
                              (##arithmetic-shift
                               leading-bits
                               (##fixnum.-
                                (##fixnum.arithmetic-shift-right
                                 shift
                                 1)))
                              (##ratnum.normalize
                               leading-bits
                               (##arithmetic-shift
                                1
                                (##fixnum.arithmetic-shift-right
                                 shift
                                 1))))))
                    (if (##ratnum? pre-rounded-result)
                        (##flonum.<-ratnum pre-rounded-result #t)
                        (##flonum.<-exact-int  pre-rounded-result #t)))))))))

  (define (complex-sqrt-magnitude x)

    (define (sqrt-mag a b)    
      ;; both are finite, 0 <= a <= b, b is nonzero
      (let* ((c (##/ a b))
             (d (##sqrt (##+ 1 (##* c c)))))
        ;; the following may return an inexact result when the true
        ;; result is exact, but we're just feeding it into make-polar
        ;; with a non-exact-zero angle, anyway.
        (##* (##sqrt b) (##sqrt d))))
    
    (let ((abs-r (##abs (##real-part x)))
          (abs-i (##abs (##imag-part x))))
      
      ;; abs-i is not exact 0
      (cond ((or (and (##flonum? abs-r)
                      (##flonum.= abs-r (macro-inexact-+inf)))
                 (and (##flonum? abs-i)
                      (##flonum.= abs-i (macro-inexact-+inf))))
             (macro-inexact-+inf))
            ;; neither abs-r or abs-i is infinite
            ((and (##flonum? abs-r)
                  (##flonum.nan? abs-r))
             abs-r)
            ;; abs-r is not a NaN
            ((and (##flonum? abs-i)
                  (##flonum.nan? abs-i))
             abs-i)
            ;; abs-i is not a NaN
            ((##eq? abs-r 0)
             (##sqrt abs-i))
            ;; abs-r is not exact 0
            ((and (##zero? abs-r)
                  (##zero? abs-i))
             (macro-inexact-+0))
            ;; abs-i and abs-r are not both zero
            (else
             (if (##< abs-r abs-i)
                 (sqrt-mag abs-r abs-i)
                 (sqrt-mag abs-i abs-r))))))

  (macro-number-dispatch x (type-error)
    (exact-int-sqrt x)
    (exact-int-sqrt x)
    (ratnum-sqrt x)
    (if (##flonum.negative? x)
        (##make-rectangular 0 (##flonum.sqrt (##flonum.- x)))
        (##flonum.sqrt x))
    (let ((real (##real-part x))
          (imag (##imag-part x)))
      (cond ((and (##flonum? imag)
                  (##flonum.zero? imag))
             (if (##flonum.positive? (##flonum.copysign (macro-inexact-+1) imag))
                 (cond ((##negative? real)
                        (##make-rectangular (macro-inexact-+0)
                                            (##exact->inexact
                                             (##sqrt (##negate real)))))
                       ((and (##flonum? real)
                             (##flonum.nan? real))
                        (##make-rectangular real real))
                       (else
                        (##make-rectangular (##exact->inexact (##sqrt real))
                                            (macro-inexact-+0))))
                 (cond ((##negative? real)
                        (##make-rectangular (macro-inexact-+0)
                                            (##exact->inexact
                                             (##negate (##sqrt (##negate real))))))
                       ((and (##flonum? real)
                             (##flonum.nan? real))
                        (##make-rectangular real real))
                       (else
                        (##make-rectangular (##exact->inexact (##sqrt real))
                                            (macro-inexact--0))))))
            ((and (##exact? real)
                  (##exact? imag)
                  (let ((discriminant (##sqrt (##+ (##* real real)
                                                   (##* imag imag)))))
                    (and (##exact? discriminant)
                         (let ((result-real (##sqrt (##/ (##+ real discriminant) 2))))
                           (and (##exact? result-real)
                                (##make-rectangular result-real (##/ imag (##* 2 result-real))))))))
             =>
             values)
            (else
             (##make-polar (complex-sqrt-magnitude x)
                           (##/ (##angle x) 2)))))))

(define-prim (sqrt x)
  (macro-force-vars (x)
    (##sqrt x)))

(define-prim (##expt x y)

  (define (exact-int-expt x y)

    (define (positive-int-expt x y)

      ;; x is an exact number and y is a positive exact integer

      (define (square x)
        (##* x x))

      (define (expt-aux x y)

        ;; x is an exact integer (not 0 or 1) and y is a nonzero exact integer

        (if (##eq? y 1)
            x
            (let ((temp (square (expt-aux x (##arithmetic-shift y -1)))))
              (if (##even? y)
                  temp
                  (##* x temp)))))

      (cond ((or (##eq? x 0)
                 (##eq? x 1))
             x)
            ((##ratnum? x)
             (macro-ratnum-make
              (exact-int-expt (macro-ratnum-numerator   x) y)
              (exact-int-expt (macro-ratnum-denominator x) y)))
            (else
             (expt-aux x y))))

    (define (invert z)
      ;; z is exact
      (let ((result (##inverse z)))
        (if (##not result)
            (##raise-range-exception 1 expt x y)
            result)))

    (if (##negative? y)
        (invert (positive-int-expt x (##negate y)))
        (positive-int-expt x y)))

  (define (complex-expt x y)
    (##exp (##* (##log x) y)))

  (define (ratnum-expt x y)
    ;; x is exact-int or ratnum
    (cond ((##eq? x 0)
           (if (##negative? y)
               (##raise-range-exception 1 expt x y)
               0))
          ((##eq? x 1)
           1)
          ((##negative? x)
           ;; We'll do some nice multiples of angles of pi carefully
           (case (macro-ratnum-denominator y)
             ((2)
              (##* (##expt (##negate x) y)
                   (case (##modulo (macro-ratnum-numerator y) 4)
                     ((1)
                      (macro-cpxnum-+i))
                     (else ;; (3)
                      (macro-cpxnum--i)))))
             ((3)
              (##* (##expt (##negate x) y)
                   (case (##modulo (macro-ratnum-numerator y) 6)
                     ((1)
                      (macro-cpxnum-+1/2+sqrt3/2i))
                     ((2)
                      (macro-cpxnum--1/2+sqrt3/2i))
                     ((4)
                      (macro-cpxnum--1/2-sqrt3/2i))
                     (else ;; (5)
                      (macro-cpxnum-+1/2-sqrt3/2i)))))
             ((6)
              (##* (##expt (##negate x) y)
                   (case (##modulo (macro-ratnum-numerator y) 12)
                     ((1)
                      (macro-cpxnum-+sqrt3/2+1/2i))
                     ((5)
                      (macro-cpxnum--sqrt3/2+1/2i))
                     ((7)
                      (macro-cpxnum--sqrt3/2-1/2i))
                     (else ;; (11)
                      (macro-cpxnum-+sqrt3/2-1/2i)))))
             ;; otherwise, we punt
             (else
              (complex-expt x y))))
          ((or (##fixnum? x)
               (##bignum? x))
           (let* ((y-den (macro-ratnum-denominator y))
                  (temp (##exact-int.nth-root x y-den)))
             (if (##= x (exact-int-expt temp y-den))
                 (exact-int-expt temp (macro-ratnum-numerator y))
                 (##flonum.expt (##flonum.<-exact-int x)
                                (##flonum.<-ratnum y)))))
          (else
           ;; x is a ratnum
           (let ((x-num (macro-ratnum-numerator   x))
                 (x-den (macro-ratnum-denominator x))
                 (y-num (macro-ratnum-numerator   y))
                 (y-den (macro-ratnum-denominator y)))
             (let ((temp-num (##exact-int.nth-root x-num y-den)))
               (if (##= (exact-int-expt temp-num y-den) x-num)
                   (let ((temp-den (##exact-int.nth-root x-den y-den)))
                     (if (##= (exact-int-expt temp-den y-den) x-den)
                         (exact-int-expt (macro-ratnum-make temp-num temp-den)
                                         y-num)
                         (##flonum.expt (##flonum.<-ratnum x)
                                        (##flonum.<-ratnum y))))
                   (##flonum.expt (##flonum.<-ratnum x)
                                  (##flonum.<-ratnum y))))))))

  (macro-number-dispatch y (##fail-check-number 2 expt x y)

    (macro-number-dispatch x (##fail-check-number 1 expt x y) ;; y a fixnum
      (if (##eq? y 0)
          1
          (exact-int-expt x y))
      (if (##eq? y 0)
          1
          (exact-int-expt x y))
      (if (##eq? y 0)
          1
          (exact-int-expt x y))
      (cond ((##eq? y 0)
             1)
            ((##flonum.nan? x)
             x)
            ((##flonum.negative? x)
             ;; we do this because (##flonum.<-fixnum y) is always
             ;; even for large enough y on 64-bit machines
             (let ((abs-result
                    (##flonum.expt (##flonum.- x) (##flonum.<-fixnum y))))
               (if (##fixnum.odd? y)
                   (##flonum.- abs-result)
                   abs-result)))
            (else
             (##flonum.expt x (##flonum.<-fixnum y))))
      (cond ((##eq? y 0)
             1)
            ((##eq? y 1)
             x)
            ((##exact? x)
             (exact-int-expt x y))
            (else
             (complex-expt x y))))

    (macro-number-dispatch x (##fail-check-number 1 expt x y) ;; y a bignum
      (exact-int-expt x y)
      (exact-int-expt x y)
      (exact-int-expt x y)
      (cond ((##flonum.nan? x)
             x)
            ((##flonum.negative? x)
             ;; we do this because (##flonum.<-exact-int y) is always
             ;; even for large enough y
             (let ((abs-result
                    (##flonum.expt (##flonum.- x) (##flonum.<-exact-int y))))
               (if (##odd? y)
                   (##flonum.- abs-result)
                   abs-result)))
            (else
             (##flonum.expt x (##flonum.<-exact-int y))))
      (if (##exact? x)
          (exact-int-expt x y)
          (complex-expt x y)))

    (macro-number-dispatch x (##fail-check-number 1 expt x y) ;; y a ratnum
      (ratnum-expt x y)
      (ratnum-expt x y)
      (ratnum-expt x y)
      (cond ((##flonum.nan? x)
             x)
            ((##flonum.negative? x)
             (if (##eq? 2 (macro-ratnum-denominator y))
                 (let ((magnitude (##flonum.expt (##flonum.- x) (##flonum.<-ratnum y))))
                   (if (##eq? 1 (##modulo (macro-ratnum-numerator y) 4))
                       ;; multiple of i
                       (macro-cpxnum-make 0 magnitude)
                       ;; multiple of -i
                       (macro-cpxnum-make 0 (##flonum.- magnitude))))
                 (complex-expt x y)))
            (else
             (##flonum.expt x (##flonum.<-ratnum y))))
      (complex-expt x y))

    (macro-number-dispatch x (##fail-check-number 1 expt x y) ;; y a flonum
      (cond ((##flonum.nan? y)
             y)
            ((##eq? x 0)
             (if (##flonum.negative? y)
                 (##raise-range-exception 1 expt x y)
                 0))
            ((or (##fixnum.positive? x)
                 (macro-flonum-int? y))
             (##flonum.expt (##flonum.<-fixnum x) y))
            (else
             (complex-expt x y)))
      (cond ((##flonum.nan? y)
             y)
            ((or (##positive? x)
                 (macro-flonum-int? y))
             (##flonum.expt (##flonum.<-exact-int x) y))
            (else
             (complex-expt x y)))
      (cond ((##flonum.nan? y)
             y)
            ((or (##positive? x)
                 (macro-flonum-int? y))
             (##flonum.expt (##flonum.<-ratnum x) y))
            (else
             (complex-expt x y)))
      (cond ((##flonum.nan? x)
             x)
            ((##flonum.nan? y)
             y)
            ((or (##flonum.positive? x)
                 (macro-flonum-int? y))
             (##flonum.expt x y))
            (else
             (complex-expt x y)))
      (cond ((##flonum.nan? y)
             y)
            (else
             (complex-expt x y))))

    (macro-number-dispatch x (##fail-check-number 1 expt x y)  ;; y a cpxnum
      (if (##eq? x 0)
          (let ((real (##real-part y)))
            (if (##positive? real)
                0
                ;; If we call (complex-expt 0 y),
                ;; we'll try to take (##log 0) in complex-expt,
                ;; so we raise the exception here.
                (##raise-range-exception 1 expt x y)))
          (complex-expt x y))
      (complex-expt x y)
      (complex-expt x y)
      (complex-expt x y)
      (complex-expt x y))))

(define-prim (expt x y)
  (macro-force-vars (x y)
    (##expt x y)))

(define-prim (##make-rectangular x y)
  (cond ((##not (##real? x))
         (##fail-check-real 1 make-rectangular x y))
        ((##not (##real? y))
         (##fail-check-real 2 make-rectangular x y))
        (else
         (let ((real (##real-part x))
               (imag (##real-part y)))
           (if (##eq? imag 0)
               real
               (macro-cpxnum-make real imag))))))

(define-prim (make-rectangular x y)
  (macro-force-vars (x y)
    (##make-rectangular x y)))

(define-prim (##make-polar x y)
  (cond ((##not (##real? x))
         (##fail-check-real 1 make-polar x y))
        ((##not (##real? y))
         (##fail-check-real 2 make-polar x y))
        (else
         (let ((real-x (##real-part x))
               (real-y (##real-part y)))
           (##make-rectangular (##* real-x (##cos real-y))
                               (##* real-x (##sin real-y)))))))

(define-prim (make-polar x y)
  (macro-force-vars (x y)
    (##make-polar x y)))

(define-prim (##real-part x)

  (define (type-error)
    (##fail-check-number 1 real-part x))

  (macro-number-dispatch x (type-error)
    x x x x (macro-cpxnum-real x)))

(define-prim (real-part x)
  (macro-force-vars (x)
    (##real-part x)))

(define-prim (##imag-part x)

  (define (type-error)
    (##fail-check-number 1 imag-part x))

  (macro-number-dispatch x (type-error)
    0 0 0 0 (macro-cpxnum-imag x)))

(define-prim (imag-part x)
  (macro-force-vars (x)
    (##imag-part x)))

(define-prim (##magnitude x)

  (define (type-error)
    (##fail-check-number 1 magnitude x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.negative? x) (##negate x) x)
    (if (##bignum.negative? x) (##negate x) x)
    (macro-ratnum-make (##abs (macro-ratnum-numerator x))
                       (macro-ratnum-denominator x))
    (##flonum.abs x)
    (let ((abs-r (##abs (##real-part x)))
          (abs-i (##abs (##imag-part x))))

      (define (complex-magn a b)
        (cond ((##eq? a 0)
               b)
              ((and (##flonum? a) (##flonum.zero? a))
               (##exact->inexact b))
              (else
               (let ((c (##/ a b)))
                 (##* b (##sqrt (##+ (##* c c) 1)))))))

      (cond ((or (and (##flonum? abs-r)
                      (##flonum.= abs-r (macro-inexact-+inf)))
                 (and (##flonum? abs-i)
                      (##flonum.= abs-i (macro-inexact-+inf))))
             (macro-inexact-+inf))
            ((and (##flonum? abs-r) (##flonum.nan? abs-r))
             abs-r)
            ((and (##flonum? abs-i) (##flonum.nan? abs-i))
             abs-i)
            (else
             (if (##< abs-r abs-i)
                 (complex-magn abs-r abs-i)
                 (complex-magn abs-i abs-r)))))))

(define-prim (magnitude x)
  (macro-force-vars (x)
    (##magnitude x)))

(define-prim (##angle x)

  (define (type-error)
    (##fail-check-number 1 angle x))

  (macro-number-dispatch x (type-error)
    (if (##fixnum.negative? x)
        (macro-inexact-+pi)
        0)
    (if (##bignum.negative? x)
        (macro-inexact-+pi)
        0)
    (if (##negative? (macro-ratnum-numerator x))
        (macro-inexact-+pi)
        0)
    (if (##flonum.negative? (##flonum.copysign (macro-inexact-+1) x))
        (macro-inexact-+pi)
        (macro-inexact-+0))
    (##atan2 (macro-cpxnum-imag x) (macro-cpxnum-real x))))

(define-prim (angle x)
  (macro-force-vars (x)
    (##angle x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; exact->inexact, inexact->exact

(define-prim (##exact->inexact x)

  (define (type-error)
    (##fail-check-number 1 exact->inexact x))

  (macro-number-dispatch x (type-error)
    (##flonum.<-fixnum x)
    (##flonum.<-exact-int x)
    (##flonum.<-ratnum x)
    x
    (##make-rectangular (##exact->inexact (macro-cpxnum-real x))
                        (##exact->inexact (macro-cpxnum-imag x)))))

(define-prim (exact->inexact x)
  (macro-force-vars (x)
    (##exact->inexact x)))

(define-prim (##inexact->exact x)

  (define (type-error)
    (##fail-check-number 1 inexact->exact x))

  (define (range-error)
    (##raise-range-exception 1 inexact->exact x))

  (macro-number-dispatch x (type-error)
    x
    x
    x
    (if (macro-flonum-rational? x)
        (##flonum.inexact->exact x)
        (range-error))
    (let ((real (macro-cpxnum-real x))
          (imag (macro-cpxnum-imag x)))
      (if (and (macro-noncpxnum-rational? real)
               (macro-noncpxnum-rational? imag))
          (##make-rectangular (##inexact->exact real)
                              (##inexact->exact imag))
          (range-error)))))

(define-prim (inexact->exact x)
  (macro-force-vars (x)
    (##inexact->exact x)))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; number->string, string->number

(define-prim (##exact-int.number->string x rad force-sign?)

  (##define-macro (macro-make-block-size)
    (let* ((max-rad 16)
           (t (make-vector (+ max-rad 1) 0)))

      (define max-fixnum 536870911) ;; OK to be conservative

      (define (block-size-for rad)
        (let loop ((i 0) (rad^i 1))
          (let ((new-rad^i (* rad^i rad)))
            (if (<= new-rad^i max-fixnum)
                (loop (+ i 1) new-rad^i)
                i))))

      (let loop ((i max-rad))
        (if (< 1 i)
            (begin
              (vector-set! t i (block-size-for i))
              (loop (- i 1)))))

      `',t))

  (define block-size (macro-make-block-size))

  (##define-macro (macro-make-rad^block-size)
    (let* ((max-rad 16)
           (t (make-vector (+ max-rad 1) 0)))

      (define max-fixnum 536870911) ;; OK to be conservative

      (define (rad^block-size-for rad)
        (let loop ((i 0) (rad^i 1))
          (let ((new-rad^i (* rad^i rad)))
            (if (<= new-rad^i max-fixnum)
                (loop (+ i 1) new-rad^i)
                rad^i))))

      (let loop ((i max-rad))
        (if (< 1 i)
            (begin
              (vector-set! t i (rad^block-size-for i))
              (loop (- i 1)))))

      `',t))

  (define rad^block-size (macro-make-rad^block-size))

  (define (make-string-from-last-fixnum rad x len pos)
    (let loop ((x x) (len len) (pos pos))
      (if (##fixnum.= x 0)
          (##make-string len)
          (let* ((new-pos
                  (##fixnum.+ pos 1))
                 (s
                  (loop (##fixnum.quotient x rad)
                        (##fixnum.+ len 1)
                        new-pos)))
            (##string-set!
             s
             (##fixnum.- (##string-length s) new-pos)
             (##string-ref ##digit-to-char-table
                           (##fixnum.- (##fixnum.remainder x rad))))
            s))))

  (define (convert-non-last-fixnum s rad x pos)
    (let loop ((x x)
               (size (##vector-ref block-size rad))
               (i (##fixnum.- (##string-length s) pos)))
      (if (##fixnum.< 0 size)
          (let ((new-i (##fixnum.- i 1)))
            (##string-set!
             s
             new-i
             (##string-ref ##digit-to-char-table
                           (##fixnum.remainder x rad)))
            (loop (##fixnum.quotient x rad)
                  (##fixnum.- size 1)
                  new-i)))))

  (define (make-string-from-fixnums rad lst len pos)
    (let loop ((lst lst) (pos pos))
      (let ((new-lst (##cdr lst)))
        (if (##null? new-lst)
            (make-string-from-last-fixnum
             rad
             (##fixnum.- (##car lst))
             (##fixnum.+ len pos)
             pos)
            (let* ((size
                    (##vector-ref block-size rad))
                   (new-pos
                    (##fixnum.+ pos size))
                   (s
                    (loop new-lst new-pos)))
              (convert-non-last-fixnum s rad (##car lst) pos)
              s)))))

  (define (uinteger->fixnums level sqs x lst)
    (cond ((and (##null? lst) (##eq? x 0))
           lst)
          ((##fixnum.= level 0)
           (##cons x lst))
          (else
           (let* ((qr (##exact-int.div x (##car sqs)))
                  (new-level (##fixnum.- level 1))
                  (new-sqs (##cdr sqs))
                  (q (##car qr))
                  (r (##cdr qr)))
             (uinteger->fixnums
              new-level
              new-sqs
              r
              (uinteger->fixnums new-level new-sqs q lst))))))

  (define (uinteger->string x rad len)
    (make-string-from-fixnums
     rad
     (let ((rad^size
            (##vector-ref rad^block-size rad))
           (x-length
            (##integer-length x)))
       (let loop ((level 0)
                  (sqs '())
                  (rad^size^2^level rad^size))
         (let ((new-level
                (##fixnum.+ level 1))
               (new-sqs
                (##cons rad^size^2^level sqs)))
           (if (##fixnum.< x-length
                           (##fixnum.-
                            (##fixnum.* (##integer-length rad^size^2^level) 2)
                            1))
               (uinteger->fixnums new-level new-sqs x '())
               (let ((new-rad^size^2^level
                      (##exact-int.square rad^size^2^level)))
                 (if (##< x new-rad^size^2^level)
                     (uinteger->fixnums new-level new-sqs x '())
                     (loop new-level
                           new-sqs
                           new-rad^size^2^level)))))))
     len
     0))

  (if (##fixnum? x)

      (cond ((##fixnum.negative? x)
             (let ((s (make-string-from-last-fixnum rad x 1 0)))
               (##string-set! s 0 #\-)
               s))
            ((##fixnum.zero? x)
             (if force-sign?
                 (##string #\+ #\0)
                 (##string #\0)))
            (else
             (if force-sign?
                 (let ((s (make-string-from-last-fixnum rad (##fixnum.- x) 1 0)))
                   (##string-set! s 0 #\+)
                   s)
                 (make-string-from-last-fixnum rad (##fixnum.- x) 0 0))))

      (cond ((##bignum.negative? x)
             (let ((s (uinteger->string (##negate x) rad 1)))
               (##string-set! s 0 #\-)
               s))
            (else
             (if force-sign?
                 (let ((s (uinteger->string x rad 1)))
                   (##string-set! s 0 #\+)
                   s)
                 (uinteger->string x rad 0))))))

(define ##digit-to-char-table "0123456789abcdefghijklmnopqrstuvwxyz")

(define-prim (##ratnum.number->string x rad force-sign?)
  (##string-append
   (##exact-int.number->string (macro-ratnum-numerator x) rad force-sign?)
   "/"
   (##exact-int.number->string (macro-ratnum-denominator x) rad #f)))

(##define-macro (macro-r6rs-fp-syntax) #t)
(##define-macro (macro-chez-fp-syntax) #f)

(##define-macro (macro-make-10^constants)
  (define n 326)
  (let ((v (make-vector n)))
    (let loop ((i 0) (x 1))
      (if (< i n)
          (begin
            (vector-set! v i x)
            (loop (+ i 1) (* x 10)))))
    `',v))

(define ##10^-constants
  (if (use-fast-bignum-algorithms)
      (macro-make-10^constants)
      #f))

(define-prim (##flonum.printout v sign-prefix)

  ;; This algorithm is derived from the paper "Printing Floating-Point
  ;; Numbers Quickly and Accurately" by Robert G. Burger and R. Kent Dybvig,
  ;; SIGPLAN'96 Conference on Programming Language Design an Implementation.

  ;; v is a flonum
  ;; f is an exact integer (fixnum or bignum)
  ;; e is an exact integer (fixnum only)

  (define (10^ n) ;; 0 <= n < 326
    (if (use-fast-bignum-algorithms)
        (##vector-ref ##10^-constants n)
        (##expt 10 n)))

  (define (base-10-log x)
    (##define-macro (1/log10) `',(/ (log 10)))
    (##flonum.* (##flonum.log x) (1/log10)))

  (##define-macro (epsilon)
    1e-10)

  (define (scale r s m+ m- round? v)

    ;; r is an exact integer (fixnum or bignum)
    ;; s is an exact integer (fixnum or bignum)
    ;; m+ is an exact integer (fixnum or bignum)
    ;; m- is an exact integer (fixnum or bignum)
    ;; round? is a boolean
    ;; v is a flonum

    (let ((est
           (##flonum->fixnum
            (##flonum.ceiling (##flonum.- (base-10-log v) (epsilon))))))
      (if (##fixnum.negative? est)
          (let ((factor (10^ (##fixnum.- est))))
            (fixup (##* r factor)
                   s
                   (##* m+ factor)
                   (##* m- factor)
                   est
                   round?))
          (let ((factor (10^ est)))
            (fixup r
                   (##* s factor)
                   m+
                   m-
                   est
                   round?)))))

  (define (fixup r s m+ m- k round?)
    (if (if round?
            (##not (##< (##+ r m+) s))
            (##< s (##+ r m+)))
        (##cons (##fixnum.+ k 1)
                (generate r
                          s
                          m+
                          m-
                          round?
                          0))
        (##cons k
                (generate (##* r 10)
                          s
                          (##* m+ 10)
                          (##* m- 10)
                          round?
                          0))))

  (define (generate r s m+ m- round? n)
    (let* ((dr (##exact-int.div r s))
           (d (##car dr))
           (r (##cdr dr))
           (tc (if round?
                   (##not (##< (##+ r m+) s))
                   (##< s (##+ r m+)))))
      (if (if round? (##not (##< m- r)) (##< r m-))
          (let* ((last-digit
                  (if tc
                      (let ((r*2 (##arithmetic-shift r 1)))
                        (if (or (and (##fixnum.even? d)
                                     (##= r*2 s)) ;; tie, round d to even
                                (##< r*2 s))
                            d
                            (##fixnum.+ d 1)))
                      d))
                 (str
                  (##make-string (##fixnum.+ n 1))))
            (##string-set!
             str
             n
             (##string-ref ##digit-to-char-table last-digit))
            str)
          (if tc
              (let ((str
                     (##make-string (##fixnum.+ n 1))))
                (##string-set!
                 str
                 n
                 (##string-ref ##digit-to-char-table (##fixnum.+ d 1)))
                str)
              (let ((str
                     (generate (##* r 10)
                               s
                               (##* m+ 10)
                               (##* m- 10)
                               round?
                               (##fixnum.+ n 1))))
                (##string-set!
                 str
                 n
                 (##string-ref ##digit-to-char-table d))
                str)))))

  (define (flonum->exponent-and-digits v)
    (let* ((x (##flonum.->exact-exponential-format v))
           (f (##vector-ref x 0))
           (e (##vector-ref x 1))
           (round? (##not (##odd? f))))
      (if (##fixnum.negative? e)
          (if (and (##not (##fixnum.= e (macro-flonum-e-min)))
                   (##= f (macro-flonum-+m-min)))
              (scale (##arithmetic-shift f 2)
                     (##arithmetic-shift 1 (##fixnum.- 2 e))
                     2
                     1
                     round?
                     v)
              (scale (##arithmetic-shift f 1)
                     (##arithmetic-shift 1 (##fixnum.- 1 e))
                     1
                     1
                     round?
                     v))
          (let ((2^e (##arithmetic-shift 1 e)))
            (if (##= f (macro-flonum-+m-min))
                (scale (##arithmetic-shift f (##fixnum.+ e 2))
                       4
                       (##arithmetic-shift 1 (##fixnum.+ e 1))
                       2^e
                       round?
                       v)
                (scale (##arithmetic-shift f (##fixnum.+ e 1))
                       2
                       2^e
                       2^e
                       round?
                       v))))))

  (let* ((x (flonum->exponent-and-digits v))
         (e (##car x))
         (d (##cdr x))            ;; d = digits
         (n (##string-length d))) ;; n = number of digits

    (cond ((and (##not (##fixnum.< e 0)) ;; 0<=e<=10
                (##not (##fixnum.< 10 e)))

           (cond ((##fixnum.= e 0) ;; e=0

                  ;; Format 1: .DDD    (0.DDD in chez-fp-syntax)

                  (##string-append sign-prefix
                                   (if (macro-chez-fp-syntax) "0." ".")
                                   d))

                 ((##fixnum.< e n) ;; e<n

                  ;; Format 2: D.DDD up to DDD.D

                  (##string-append sign-prefix
                                   (##substring d 0 e)
                                   "."
                                   (##substring d e n)))

                 ((##fixnum.= e n) ;; e=n

                  ;; Format 3: DDD.    (DDD.0 in chez-fp-syntax)

                  (##string-append sign-prefix
                                   d
                                   (if (macro-chez-fp-syntax) ".0" ".")))

                 (else ;; e>n

                  ;; Format 4: DDD000000.    (DDD000000.0 in chez-fp-syntax)

                  (##string-append sign-prefix
                                   d
                                   (##make-string (##fixnum.- e n) #\0)
                                   (if (macro-chez-fp-syntax) ".0" ".")))))

          ((and (##not (##fixnum.< e -2)) ;; -2<=e<=-1
                (##not (##fixnum.< -1 e)))

           ;; Format 5: .0DDD or .00DDD    (0.0DDD or 0.00DDD in chez-fp-syntax)

           (##string-append sign-prefix
                            (if (macro-chez-fp-syntax) "0." ".")
                            (##make-string (##fixnum.- e) #\0)
                            d))

          (else

           ;; Format 6: D.DDDeEEE
           ;;
           ;; This is the most general format.  We insert a period after
           ;; the first digit (unless there is only one digit) and add
           ;; an exponent.

           (##string-append sign-prefix
                            (##substring d 0 1)
                            (if (##fixnum.= n 1) "" ".")
                            (##substring d 1 n)
                            "e"
                            (##number->string (##fixnum.- e 1) 10))))))

(define-prim (##flonum.number->string x rad force-sign?)

  (define (non-neg-num->str x rad sign-prefix)
    (if (##flonum.zero? x)
        (##string-append sign-prefix (if (macro-chez-fp-syntax) "0.0" "0."))
        (##flonum.printout x sign-prefix)))

  (cond ((##flonum.nan? x)
         (##string-copy (if (or (macro-r6rs-fp-syntax)
                                (macro-chez-fp-syntax))
                            "+nan.0"
                            "+nan.")))
        ((##flonum.negative? (##flonum.copysign (macro-inexact-+1) x))
         (let ((abs-x (##flonum.copysign x (macro-inexact-+1))))
           (cond ((##flonum.= abs-x (macro-inexact-+inf))
                  (##string-copy (if (or (macro-r6rs-fp-syntax)
                                         (macro-chez-fp-syntax))
                                     "-inf.0"
                                     "-inf.")))
                 (else
                  (non-neg-num->str abs-x rad "-")))))
        (else
         (cond ((##flonum.= x (macro-inexact-+inf))
                (##string-copy (if (or (macro-r6rs-fp-syntax)
                                       (macro-chez-fp-syntax))
                                   "+inf.0"
                                   "+inf.")))
               (force-sign?
                (non-neg-num->str x rad "+"))
               (else
                (non-neg-num->str x rad ""))))))

(define-prim (##cpxnum.number->string x rad force-sign?)
  (let* ((real
          (macro-cpxnum-real x))
         (real-str
          (if (##eq? real 0) "" (##number->string real rad force-sign?))))
    (let ((imag (macro-cpxnum-imag x)))
      (cond ((##eq? imag 1)
             (##string-append real-str "+i"))
            ((##eq? imag -1)
             (##string-append real-str "-i"))
            (else
             (##string-append real-str
                              (##number->string imag rad #t)
                              "i"))))))

(define-prim (##number->string x #!optional (rad 10) (force-sign? #f))
  (macro-number-dispatch x '()
    (##exact-int.number->string x rad force-sign?)
    (##exact-int.number->string x rad force-sign?)
    (##ratnum.number->string x rad force-sign?)
    (##flonum.number->string x rad force-sign?)
    (##cpxnum.number->string x rad force-sign?)))

(define-prim (number->string n #!optional (r (macro-absent-obj)))
  (macro-force-vars (n r)
    (let ((rad (if (##eq? r (macro-absent-obj)) 10 r)))
      (if (macro-exact-int? rad)
          (if (or (##eq? rad 2)
                  (##eq? rad 8)
                  (##eq? rad 10)
                  (##eq? rad 16))
              (let ((result (##number->string n rad #f)))
                (if (##null? result)
                    (##fail-check-number 1 number->string n r)
                    result))
              (##raise-range-exception 2 number->string n r))
          (##fail-check-exact-integer 2 number->string n r)))))

(##define-macro (macro-make-char-to-digit-table)
  (let ((t (make-vector 128 99)))
    (vector-set! t (char->integer #\#) 0) ;; #\# counts as 0
    (let loop1 ((i 9))
      (if (not (< i 0))
          (begin
            (vector-set! t (+ (char->integer #\0) i) i)
            (loop1 (- i 1)))))
    (let loop2 ((i 25))
      (if (not (< i 0))
          (begin
            (vector-set! t (+ (char->integer #\A) i) (+ i 10))
            (vector-set! t (+ (char->integer #\a) i) (+ i 10))
            (loop2 (- i 1)))))
    `',(list->u8vector (vector->list t))))

(define ##char-to-digit-table (macro-make-char-to-digit-table))

(define-prim (##string->number str #!optional (rad 10) (check-only? #f))

  ;; The number grammar parsed by this procedure is:
  ;;
  ;; <num R E> : <prefix R E> <complex R E>
  ;;
  ;; <complex R E> : <real R E>
  ;;               | <real R E> @ <real R E>
  ;;               | <real R E> <sign> <ureal R> i
  ;;               | <real R E> <sign-inf-nan R E> i
  ;;               | <real R E> <sign> i
  ;;               | <sign> <ureal R> i
  ;;               | <sign-inf-nan R E> i
  ;;               | <sign> i
  ;;
  ;; <real R E> : <ureal R>
  ;;            | <sign> <ureal R>
  ;;            | <sign-inf-nan R E>
  ;;
  ;; <sign-inf-nan R i> : +inf.0
  ;;                    | -inf.0
  ;;                    | +nan.0
  ;; <sign-inf-nan R empty> : <sign-inf-nan R i>
  ;;
  ;; <ureal R> : <uinteger R>
  ;;           | <uinteger R> / <uinteger R>
  ;;           | <decimal R>
  ;;
  ;; <decimal 10> : <uinteger 10> <suffix>
  ;;              | . <digit 10>+ #* <suffix>
  ;;              | <digit 10>+ . <digit 10>* #* <suffix>
  ;;              | <digit 10>+ #+ . #* <suffix>
  ;;
  ;; <uinteger R> : <digit R>+ #*
  ;;
  ;; <prefix R E> : <radix R E> <exactness E>
  ;;              | <exactness E> <radix R E>
  ;;
  ;; <suffix> : <empty>
  ;;          | <exponent marker> <digit 10>+
  ;;          | <exponent marker> <sign> <digit 10>+
  ;;
  ;; <exponent marker> : e | s | f | d | l
  ;; <sign> : + | -
  ;; <exactness empty> : <empty>
  ;; <exactness i> : #i
  ;; <exactness e> : #e
  ;; <radix 2> : #b
  ;; <radix 8> : #o
  ;; <radix 10> : <empty> | #d
  ;; <radix 16> : #x
  ;; <digit 2> : 0 | 1
  ;; <digit 8> : 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
  ;; <digit 10> : 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
  ;; <digit 16> : <digit 10> | a | b | c | d | e | f

  (##define-macro (macro-make-exact-10^n-table)

    (define max-exact-power-of-10 22) ;; (floor (inexact->exact (/ (log (expt 2 (macro-flonum-m-bits-plus-1))) (log 5))))

    (let ((t (make-vector (+ max-exact-power-of-10 1))))

      (let loop ((i max-exact-power-of-10))
        (if (not (< i 0))
            (begin
              (vector-set! t i (exact->inexact (expt 10 i)))
              (loop (- i 1)))))

      `',(list->f64vector (vector->list t))))

  (define exact-10^n-table (macro-make-exact-10^n-table))

  (##define-macro (macro-make-block-size)
    (let* ((max-rad 16)
           (t (make-vector (+ max-rad 1) 0)))

      (define max-fixnum 536870911) ;; OK to be conservative

      (define (block-size-for rad)
        (let loop ((i 0) (rad^i 1))
          (let ((new-rad^i (* rad^i rad)))
            (if (<= new-rad^i max-fixnum)
                (loop (+ i 1) new-rad^i)
                i))))

      (let loop ((i max-rad))
        (if (< 1 i)
            (begin
              (vector-set! t i (block-size-for i))
              (loop (- i 1)))))

      `',t))

  (define block-size (macro-make-block-size))

  (##define-macro (macro-make-rad^block-size)
    (let* ((max-rad 16)
           (t (make-vector (+ max-rad 1) 0)))

      (define max-fixnum 536870911) ;; OK to be conservative

      (define (rad^block-size-for rad)
        (let loop ((i 0) (rad^i 1))
          (let ((new-rad^i (* rad^i rad)))
            (if (<= new-rad^i max-fixnum)
                (loop (+ i 1) new-rad^i)
                rad^i))))

      (let loop ((i max-rad))
        (if (< 1 i)
            (begin
              (vector-set! t i (rad^block-size-for i))
              (loop (- i 1)))))

      `',t))

  (define rad^block-size (macro-make-rad^block-size))

  (define (substring->uinteger-fixnum str rad i j)

    ;; Simple case: result is known to fit in a fixnum.

    (let loop ((i i) (n 0))
      (if (##fixnum.< i j)
          (let ((c (##string-ref str i)))
            (if (##char<? c 128)
                (loop (##fixnum.+ i 1)
                      (##fixnum.+ (##fixnum.* n rad)
                                  (##u8vector-ref ##char-to-digit-table c)))
                (loop (##fixnum.+ i 1)
                      (##fixnum.* n rad))))
          n)))

  (define (substring->uinteger-aux sqs width str rad i j)

    ;; Divide-and-conquer algorithm (fast for large bignums if bignum
    ;; multiplication is fast).

    (if (##null? sqs)
        (substring->uinteger-fixnum str rad i j)
        (let* ((new-sqs (##cdr sqs))
               (new-width (##fixnum.quotient width 2))
               (mid (##fixnum.- j new-width)))
          (if (##fixnum.< i mid)
              (let* ((a (substring->uinteger-aux new-sqs new-width str rad i mid))
                     (b (substring->uinteger-aux new-sqs new-width str rad mid j)))
                (##+ (##* a (##car sqs)) b))
              (substring->uinteger-aux new-sqs new-width str rad i j)))))

  (define (squares rad n)
    (let loop ((rad rad) (n n) (lst '()))
      (if (##fixnum.= n 1)
          (##cons rad lst)
          (loop (##exact-int.square rad)
                (##fixnum.- n 1)
                (##cons rad lst)))))

  (define (substring->uinteger str rad i j)

    ;; Converts a substring into an unsigned integer.  Selects a fast
    ;; conversion algorithm when result fits in a fixnum.

    (let ((len (##fixnum.- j i))
          (size (##vector-ref block-size rad)))
      (if (##fixnum.< size len)
          (let ((levels
                 (##integer-length (##fixnum.quotient (##fixnum.- len 1) size))))
            (substring->uinteger-aux
             (squares (##vector-ref rad^block-size rad) levels)
             (##fixnum.arithmetic-shift-left size levels)
             str
             rad
             i
             j))
          (substring->uinteger-fixnum str rad i j))))

  (define (float-substring->uinteger str i j)

    ;; Converts a substring containing the decimals of a floating-point
    ;; number into an unsigned integer (any period is simply skipped).

    (let loop1 ((i i) (n 0))
      (if (##not (##fixnum.< i j))
          n
          (let ((c (##string-ref str i)))
            (if (##char=? c #\.)
                (loop1 (##fixnum.+ i 1) n)
                (let ((new-n
                       (##fixnum.+ (##fixnum.* n 10)
                                   (if (##char<? c 128)
                                       (##u8vector-ref ##char-to-digit-table c)
                                       0))))
                  (if (##fixnum.< new-n (macro-max-fixnum32-div-10))
                      (loop1 (##fixnum.+ i 1) new-n)
                      (let loop2 ((i i) (n n))
                        (if (##not (##fixnum.< i j))
                            n
                            (let ((c (##string-ref str i)))
                              (if (##char=? c #\.)
                                  (loop2 (##fixnum.+ i 1) n)
                                  (let ((new-n
                                         (##+
                                          (##* n 10)
                                          (if (##char<? c 128)
                                              (##u8vector-ref ##char-to-digit-table c)
                                              0))))
                                    (loop2 (##fixnum.+ i 1) new-n)))))))))))))

  (define (uinteger str rad i)
    (and (##fixnum.< i (##string-length str))
         (let ((c (##string-ref str i)))
           (and (##char<? c 128)
                (##not (##char=? c #\#))
                (##fixnum.< (##u8vector-ref ##char-to-digit-table c) rad)
                (digits-and-sharps str rad (##fixnum.+ i 1))))))

  (define (digits-and-sharps str rad i)
    (let loop ((i i))
      (if (##fixnum.< i (##string-length str))
          (let ((c (##string-ref str i)))
            (if (##char<? c 128)
                (if (##char=? c #\#)
                    (sharps str (##fixnum.+ i 1))
                    (if (##fixnum.< (##u8vector-ref ##char-to-digit-table c) rad)
                        (loop (##fixnum.+ i 1))
                        i))
                i))
          i)))

  (define (sharps str i)
    (let loop ((i i))
      (if (##fixnum.< i (##string-length str))
          (if (##char=? (##string-ref str i) #\#)
              (loop (##fixnum.+ i 1))
              i)
          i)))

  (define (suffix str i1)
    (if (##fixnum.< (##fixnum.+ i1 1) (##string-length str))
        (let ((c1 (##string-ref str i1)))
          (if (or (##char=? c1 #\e) (##char=? c1 #\E)
                  (##char=? c1 #\s) (##char=? c1 #\S)
                  (##char=? c1 #\f) (##char=? c1 #\F)
                  (##char=? c1 #\d) (##char=? c1 #\D)
                  (##char=? c1 #\l) (##char=? c1 #\L))
              (let ((c2 (##string-ref str (##fixnum.+ i1 1))))
                (let ((i2
                       (if (or (##char=? c2 #\+) (##char=? c2 #\-))
                           (uinteger str 10 (##fixnum.+ i1 2))
                           (uinteger str 10 (##fixnum.+ i1 1)))))
                  (if (and i2
                           (##not (##char=? (##string-ref str (##fixnum.- i2 1))
                                            #\#)))
                      i2
                      i1)))
              i1))
        i1))

  (define (ureal str rad e i1)
    (let ((i2 (uinteger str rad i1)))
      (if i2
          (if (##fixnum.< i2 (##string-length str))
              (let ((c (##string-ref str i2)))
                (cond ((##char=? c #\/)
                       (let ((i3 (uinteger str rad (##fixnum.+ i2 1))))
                         (and i3
                              (let ((inexact-num?
                                     (or (##eq? e 'i)
                                         (and (##not e)
                                              (or (##char=? (##string-ref
                                                             str
                                                             (##fixnum.- i2 1))
                                                            #\#)
                                                  (##char=? (##string-ref
                                                             str
                                                             (##fixnum.- i3 1))
                                                            #\#))))))
                                (if (and (##not inexact-num?)
                                         (##eq? (substring->uinteger
                                                 str
                                                 rad
                                                 (##fixnum.+ i2 1)
                                                 i3)
                                                0))
                                    #f
                                    (##vector i3 i2))))))
                      ((##fixnum.= rad 10)
                       (if (##char=? c #\.)
                           (let ((i3
                                  (if (##char=? (##string-ref str (##fixnum.- i2 1))
                                                #\#)
                                      (sharps str (##fixnum.+ i2 1))
                                      (digits-and-sharps str 10 (##fixnum.+ i2 1)))))
                             (and i3
                                  (let ((i4 (suffix str i3)))
                                    (##vector i4 i3 i2))))
                           (let ((i3 (suffix str i2)))
                             (if (##fixnum.= i2 i3)
                                 i2
                                 (##vector i3 i2 i2)))))
                      (else
                       i2)))
              i2)
          (and (##fixnum.= rad 10)
               (##fixnum.< i1 (##string-length str))
               (##char=? (##string-ref str i1) #\.)
               (let ((i3 (uinteger str rad (##fixnum.+ i1 1))))
                 (and i3
                      (let ((i4 (suffix str i3)))
                        (##vector i4 i3 i1))))))))

  (define (inf-nan str sign i e)
    (and (##not (##eq? e 'e))
         (if (##fixnum.< (##fixnum.+ i (if (or (macro-r6rs-fp-syntax)
                                               (macro-chez-fp-syntax))
                                           4
                                           3))
                         (##string-length str))
             (and (##char=? (##string-ref str (##fixnum.+ i 3)) #\.)
                  (if (or (macro-r6rs-fp-syntax)
                          (macro-chez-fp-syntax))
                      (##char=? (##string-ref str (##fixnum.+ i 4)) #\0)
                      #t)
                  (or (and (let ((c (##string-ref str i)))
                             (or (##char=? c #\i) (##char=? c #\I)))
                           (let ((c (##string-ref str (##fixnum.+ i 1))))
                             (or (##char=? c #\n) (##char=? c #\N)))
                           (let ((c (##string-ref str (##fixnum.+ i 2))))
                             (or (##char=? c #\f) (##char=? c #\F))))
                      (and (##not (##char=? sign #\-))
                           (let ((c (##string-ref str i)))
                             (or (##char=? c #\n) (##char=? c #\N)))
                           (let ((c (##string-ref str (##fixnum.+ i 1))))
                             (or (##char=? c #\a) (##char=? c #\A)))
                           (let ((c (##string-ref str (##fixnum.+ i 2))))
                             (or (##char=? c #\n) (##char=? c #\N)))))
                  (##vector (##fixnum.+ i (if (or (macro-r6rs-fp-syntax)
                                                  (macro-chez-fp-syntax))
                                              5
                                              4))))
             #f)))

  (define (make-rec x y)
    (##make-rectangular x y))

  (define (make-pol x y e)
    (let ((n (##make-polar x y)))
      (if (##eq? e 'e)
          (##inexact->exact n)
          n)))

  (define (make-inexact-real sign uinteger exponent)
    (let ((n
           (if (and (##fixnum? uinteger)
                    (##flonum.<-fixnum-exact? uinteger)
                    (##fixnum? exponent)
                    (##fixnum.< (##fixnum.- exponent)
                                (##f64vector-length exact-10^n-table))
                    (##fixnum.< exponent
                                (##f64vector-length exact-10^n-table)))
               (if (##fixnum.< exponent 0)
                   (##flonum./ (##flonum.<-fixnum uinteger)
                               (##f64vector-ref exact-10^n-table
                                                (##fixnum.- exponent)))
                   (##flonum.* (##flonum.<-fixnum uinteger)
                               (##f64vector-ref exact-10^n-table
                                                exponent)))
               (##exact->inexact
                (##* uinteger (##expt 10 exponent))))))
      (if (##char=? sign #\-)
          (##flonum.copysign n (macro-inexact--1))
          n)))

  (define (get-zero e)
    (if (##eq? e 'i)
        (macro-inexact-+0)
        0))

  (define (get-one sign e)
    (if (##eq? e 'i)
        (if (##char=? sign #\-) (macro-inexact--1) (macro-inexact-+1))
        (if (##char=? sign #\-) -1 1)))

  (define (get-real start sign str rad e i)
    (if (##fixnum? i)
        (let* ((abs-n
                (substring->uinteger str rad start i))
               (n
                (if (##char=? sign #\-)
                    (##negate abs-n)
                    abs-n)))
          (if (or (##eq? e 'i)
                  (and (##not e)
                       (##char=? (##string-ref str (##fixnum.- i 1)) #\#)))
              (##exact->inexact n)
              n))
        (let ((j (##vector-ref i 0))
              (len (##vector-length i)))
          (cond ((##fixnum.= len 3) ;; xxx.yyyEzzz
                 (let* ((after-frac-part
                         (##vector-ref i 1))
                        (unadjusted-exponent
                         (if (##fixnum.= after-frac-part j) ;; no exponent part?
                             0
                             (let* ((c
                                     (##string-ref
                                      str
                                      (##fixnum.+ after-frac-part 1)))
                                    (n
                                     (substring->uinteger
                                      str
                                      10
                                      (if (or (##char=? c #\+) (##char=? c #\-))
                                          (##fixnum.+ after-frac-part 2)
                                          (##fixnum.+ after-frac-part 1))
                                      j)))
                               (if (##char=? c #\-)
                                   (##negate n)
                                   n))))
                        (c
                         (##string-ref str start))
                        (uinteger
                         (float-substring->uinteger str start after-frac-part))
                        (decimals-after-point
                         (##fixnum.-
                          (##fixnum.- after-frac-part (##vector-ref i 2))
                          1))
                        (exponent
                         (if (##fixnum.< 0 decimals-after-point)
                             (if (and (##fixnum? unadjusted-exponent)
                                      (##fixnum.< (##fixnum.- unadjusted-exponent
                                                              decimals-after-point)
                                                  unadjusted-exponent))
                                 (##fixnum.- unadjusted-exponent
                                             decimals-after-point)
                                 (##- unadjusted-exponent
                                      decimals-after-point))
                             unadjusted-exponent)))
                   (if (##eq? e 'e)
                       (##*
                        (if (##char=? sign #\-)
                            (##negate uinteger)
                            uinteger)
                        (##expt 10 exponent))
                       (make-inexact-real sign uinteger exponent))))
                ((##fixnum.= len 2) ;; xxx/yyy
                 (let* ((after-num
                         (##vector-ref i 1))
                        (inexact-num?
                         (or (##eq? e 'i)
                             (and (##not e)
                                  (or (##char=? (##string-ref
                                                 str
                                                 (##fixnum.- after-num 1))
                                                #\#)
                                      (##char=? (##string-ref
                                                 str
                                                 (##fixnum.- j 1))
                                                #\#)))))
                        (abs-num
                         (substring->uinteger str rad start after-num))
                        (den
                         (substring->uinteger str
                                              rad
                                              (##fixnum.+ after-num 1)
                                              j)))

                   (define (num-div-den)
                     (##/ (if (##char=? sign #\-)
                              (##negate abs-num)
                              abs-num)
                          den))

                   (if inexact-num?
                       (if (##eq? den 0)
                           (let ((n
                                  (if (##eq? abs-num 0)
                                      (macro-inexact-+nan)
                                      (macro-inexact-+inf))))
                             (if (##char=? sign #\-)
                                 (##flonum.copysign n (macro-inexact--1))
                                 n))
                           (##exact->inexact (num-div-den)))
                       (num-div-den))))
                (else ;; (##fixnum.= len 1) ;; inf or nan
                 (let* ((c
                         (##string-ref str start))
                        (n
                         (if (or (##char=? c #\i) (##char=? c #\I))
                             (macro-inexact-+inf)
                             (macro-inexact-+nan))))
                   (if (##char=? sign #\-)
                       (##flonum.copysign n (macro-inexact--1))
                       n)))))))

  (define (i-end str i)
    (and (##fixnum.= (##fixnum.+ i 1) (##string-length str))
         (let ((c (##string-ref str i)))
           (or (##char=? c #\i) (##char=? c #\I)))))

  (define (complex start sign str rad e i)
    (let ((j (if (##fixnum? i) i (##vector-ref i 0))))
      (let ((c (##string-ref str j)))
        (cond ((##char=? c #\@)
               (let ((j+1 (##fixnum.+ j 1)))
                 (if (##fixnum.< j+1 (##string-length str))
                     (let* ((sign2
                             (##string-ref str j+1))
                            (start2
                             (if (or (##char=? sign2 #\+) (##char=? sign2 #\-))
                                 (##fixnum.+ j+1 1)
                                 j+1))
                            (k
                             (or (ureal str rad e start2)
                                 (and (##fixnum.< j+1 start2)
                                      (inf-nan str sign2 start2 e)))))
                       (and k
                            (let ((l (if (##fixnum? k) k (##vector-ref k 0))))
                              (and (##fixnum.= l (##string-length str))
                                   (or check-only?
                                       (make-pol
                                        (get-real start sign str rad e i)
                                        (get-real start2 sign2 str rad e k)
                                        e))))))
                     #f)))
              ((or (##char=? c #\+) (##char=? c #\-))
               (let* ((start2
                       (##fixnum.+ j 1))
                      (k
                       (or (ureal str rad e start2)
                           (inf-nan str c start2 e))))
                 (if (##not k)
                     (if (i-end str start2)
                         (or check-only?
                             (make-rec
                              (get-real start sign str rad e i)
                              (get-one c e)))
                         #f)
                     (let ((l (if (##fixnum? k) k (##vector-ref k 0))))
                       (and (i-end str l)
                            (or check-only?
                                (make-rec
                                 (get-real start sign str rad e i)
                                 (get-real start2 c str rad e k))))))))
              (else
               #f)))))

  (define (after-prefix start str rad e)

    ;; invariant: start = 0, 2 or 4, (string-length str) > start

    (let ((c (##string-ref str start)))
      (if (or (##char=? c #\+) (##char=? c #\-))
          (let ((i (or (ureal str rad e (##fixnum.+ start 1))
                       (inf-nan str c (##fixnum.+ start 1) e))))
            (if (##not i)
                (if (i-end str (##fixnum.+ start 1))
                    (or check-only?
                        (make-rec
                         (get-zero e)
                         (get-one c e)))
                    #f)
                (let ((j (if (##fixnum? i) i (##vector-ref i 0))))
                  (cond ((##fixnum.= j (##string-length str))
                         (or check-only?
                             (get-real (##fixnum.+ start 1) c str rad e i)))
                        ((i-end str j)
                         (or check-only?
                             (make-rec
                              (get-zero e)
                              (get-real (##fixnum.+ start 1) c str rad e i))))
                        (else
                         (complex (##fixnum.+ start 1) c str rad e i))))))
          (let ((i (ureal str rad e start)))
            (if (##not i)
                #f
                (let ((j (if (##fixnum? i) i (##vector-ref i 0))))
                  (cond ((##fixnum.= j (##string-length str))
                         (or check-only?
                             (get-real start #\+ str rad e i)))
                        (else
                         (complex start #\+ str rad e i)))))))))

  (define (radix-prefix c)
    (cond ((or (##char=? c #\b) (##char=? c #\B))  2)
          ((or (##char=? c #\o) (##char=? c #\O))  8)
          ((or (##char=? c #\d) (##char=? c #\D)) 10)
          ((or (##char=? c #\x) (##char=? c #\X)) 16)
          (else                                   #f)))

  (define (exactness-prefix c)
    (cond ((or (##char=? c #\i) (##char=? c #\I)) 'i)
          ((or (##char=? c #\e) (##char=? c #\E)) 'e)
          (else                                   #f)))

  (cond ((##fixnum.< 2 (##string-length str)) ;; >= 3 chars
         (if (##char=? (##string-ref str 0) #\#)
             (let ((rad1 (radix-prefix (##string-ref str 1))))
               (if rad1
                   (if (and (##fixnum.< 4 (##string-length str)) ;; >= 5 chars
                            (##char=? (##string-ref str 2) #\#))
                       (let ((e1 (exactness-prefix (##string-ref str 3))))
                         (if e1
                             (after-prefix 4 str rad1 e1)
                             #f))
                       (after-prefix 2 str rad1 #f))
                   (let ((e2 (exactness-prefix (##string-ref str 1))))
                     (if e2
                         (if (and (##fixnum.< 4 (##string-length str)) ;; >= 5 chars
                                  (##char=? (##string-ref str 2) #\#))
                             (let ((rad2 (radix-prefix (##string-ref str 3))))
                               (if rad2
                                   (after-prefix 4 str rad2 e2)
                                   #f))
                             (after-prefix 2 str rad e2))
                         #f))))
             (after-prefix 0 str rad #f)))
        ((##fixnum.< 0 (##string-length str)) ;; >= 1 char
         (after-prefix 0 str rad #f))
        (else
         #f)))

(define-prim (string->number str #!optional (r (macro-absent-obj)))
  (macro-force-vars (str r)
    (macro-check-string str 1 (string->number str r)
      (let ((rad (if (##eq? r (macro-absent-obj)) 10 r)))
        (if (macro-exact-int? rad)
            (if (or (##eq? rad 2)
                    (##eq? rad 8)
                    (##eq? rad 10)
                    (##eq? rad 16))
                (##string->number str rad #f)
                (##raise-range-exception 2 string->number str r))
            (##fail-check-exact-integer 2 string->number str r))))))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Bitwise operations.

(define-prim (##bitwise-ior x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (define (bignum-bitwise-ior x x-length y y-length)
    (if (##bignum.negative? x)
        (let ((result (##bignum.make x-length x #f)))
          (##declare (not interrupts-enabled))
          (let loop1 ((i 0))
            (if (##fixnum.< i x-length)
                (begin
                  (##bignum.adigit-bitwise-ior! result i y i)
                  (loop1 (##fixnum.+ i 1)))
                (##bignum.normalize! result))))
        (let ((result (##bignum.make y-length y #f)))
          (##declare (not interrupts-enabled))
          (let loop2 ((i 0))
            (if (##fixnum.< i x-length)
                (begin
                  (##bignum.adigit-bitwise-ior! result i x i)
                  (loop2 (##fixnum.+ i 1)))
                (##bignum.normalize! result))))))

  (cond ((##fixnum? x)
         (cond ((##fixnum? y)
                (##fixnum.bitwise-ior x y))
               ((##bignum? y)
                (let* ((x-bignum (##bignum.<-fixnum x))
                       (x-length (##bignum.adigit-length x-bignum))
                       (y-length (##bignum.adigit-length y)))
                  (bignum-bitwise-ior x-bignum x-length y y-length)))
               (else
                (type-error-on-y))))
        ((##bignum? x)
         (let ((x-length (##bignum.adigit-length x)))
           (cond ((##fixnum? y)
                  (let* ((y-bignum (##bignum.<-fixnum y))
                         (y-length (##bignum.adigit-length y-bignum)))
                    (bignum-bitwise-ior y-bignum y-length x x-length)))
                 ((##bignum? y)
                  (let ((y-length (##bignum.adigit-length y)))
                    (if (##fixnum.< x-length y-length)
                        (bignum-bitwise-ior x x-length y y-length)
                        (bignum-bitwise-ior y y-length x x-length))))
                 (else
                  (type-error-on-y)))))
        (else
         (type-error-on-x))))

(define-prim-nary (bitwise-ior x y)
  0
  (if (macro-exact-int? x) x '(1))
  (##bitwise-ior x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-exact-integer))

(define-prim (##bitwise-xor x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (define (bignum-bitwise-xor x x-length y y-length)
    (let ((result (##bignum.make y-length y #f)))
      (##declare (not interrupts-enabled))
      (let loop1 ((i 0))
        (if (##fixnum.< i x-length)
            (begin
              (##bignum.adigit-bitwise-xor! result i x i)
              (loop1 (##fixnum.+ i 1)))
            (if (##bignum.negative? x)
                (let loop2 ((i i))
                  (if (##fixnum.< i y-length)
                      (begin
                        (##bignum.adigit-bitwise-not! result i)
                        (loop2 (##fixnum.+ i 1)))
                      (##bignum.normalize! result)))
                (##bignum.normalize! result))))))

  (cond ((##fixnum? x)
         (cond ((##fixnum? y)
                (##fixnum.bitwise-xor x y))
               ((##bignum? y)
                (let* ((x-bignum (##bignum.<-fixnum x))
                       (x-length (##bignum.adigit-length x-bignum))
                       (y-length (##bignum.adigit-length y)))
                  (bignum-bitwise-xor x-bignum x-length y y-length)))
               (else
                (type-error-on-y))))
        ((##bignum? x)
         (let ((x-length (##bignum.adigit-length x)))
           (cond ((##fixnum? y)
                  (let* ((y-bignum (##bignum.<-fixnum y))
                         (y-length (##bignum.adigit-length y-bignum)))
                    (bignum-bitwise-xor y-bignum y-length x x-length)))
                 ((##bignum? y)
                  (let ((y-length (##bignum.adigit-length y)))
                    (if (##fixnum.< x-length y-length)
                        (bignum-bitwise-xor x x-length y y-length)
                        (bignum-bitwise-xor y y-length x x-length))))
                 (else
                  (type-error-on-y)))))
        (else
         (type-error-on-x))))

(define-prim-nary (bitwise-xor x y)
  0
  (if (macro-exact-int? x) x '(1))
  (##bitwise-xor x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-exact-integer))

(define-prim (##bitwise-and x y)

  (##define-macro (type-error-on-x) `'(1))
  (##define-macro (type-error-on-y) `'(2))

  (define (bignum-bitwise-and x x-length y y-length)
    (if (##bignum.negative? x)
        (let ((result (##bignum.make y-length y #f)))
          (##declare (not interrupts-enabled))
          (let loop1 ((i 0))
            (if (##fixnum.< i x-length)
                (begin
                  (##bignum.adigit-bitwise-and! result i x i)
                  (loop1 (##fixnum.+ i 1)))
                (##bignum.normalize! result))))
        (let ((result (##bignum.make x-length x #f)))
          (##declare (not interrupts-enabled))
          (let loop2 ((i 0))
            (if (##fixnum.< i x-length)
                (begin
                  (##bignum.adigit-bitwise-and! result i y i)
                  (loop2 (##fixnum.+ i 1)))
                (##bignum.normalize! result))))))

  (cond ((##fixnum? x)
         (cond ((##fixnum? y)
                (##fixnum.bitwise-and x y))
               ((##bignum? y)
                (let* ((x-bignum (##bignum.<-fixnum x))
                       (x-length (##bignum.adigit-length x-bignum))
                       (y-length (##bignum.adigit-length y)))
                  (bignum-bitwise-and x-bignum x-length y y-length)))
               (else
                (type-error-on-y))))
        ((##bignum? x)
         (let ((x-length (##bignum.adigit-length x)))
           (cond ((##fixnum? y)
                  (let* ((y-bignum (##bignum.<-fixnum y))
                         (y-length (##bignum.adigit-length y-bignum)))
                    (bignum-bitwise-and y-bignum y-length x x-length)))
                 ((##bignum? y)
                  (let ((y-length (##bignum.adigit-length y)))
                    (if (##fixnum.< x-length y-length)
                        (bignum-bitwise-and x x-length y y-length)
                        (bignum-bitwise-and y y-length x x-length))))
                 (else
                  (type-error-on-y)))))
        (else
         (type-error-on-x))))

(define-prim-nary (bitwise-and x y)
  -1
  (if (macro-exact-int? x) x '(1))
  (##bitwise-and x y)
  macro-force-vars
  macro-no-check
  (##pair? ##fail-check-exact-integer))

(define-prim (##bitwise-not x)

  (define (type-error)
    (##fail-check-exact-integer 1 bitwise-not x))

  (cond ((##fixnum? x)
         (##fixnum.bitwise-not x))
        ((##bignum? x)
         (##bignum.make (##bignum.adigit-length x) x #t))
        (else
         (type-error))))

(define-prim (bitwise-not x)
  (macro-force-vars (x)
    (##bitwise-not x)))

(define-prim (##arithmetic-shift x y)

  (define (type-error-on-x)
    (##fail-check-exact-integer 1 arithmetic-shift x y))

  (define (type-error-on-y)
    (##fail-check-exact-integer 2 arithmetic-shift x y))

  (define (overflow)
    (##raise-heap-overflow-exception)
    (##arithmetic-shift x y))

  (define (general-fixnum-fixnum-case)
    (##bignum.arithmetic-shift (##bignum.<-fixnum x) y))

  (cond ((##fixnum? x)
         (cond ((##fixnum? y)
                (cond ((##fixnum.zero? y)
                       x)
                      ((##fixnum.negative? y) ;; right shift
                       (if (##fixnum.< (##fixnum.- ##fixnum-width) y)
                           (##fixnum.arithmetic-shift-right x (##fixnum.- y))
                           (if (##fixnum.negative? x)
                               -1
                               0)))
                      (else ;; left shift
                       (if (##fixnum.< y ##fixnum-width)
                           (let ((result (##fixnum.arithmetic-shift-left x y)))
                             (if (##fixnum.=
                                  (##fixnum.arithmetic-shift-right result y)
                                  x)
                                 result
                                 (general-fixnum-fixnum-case)))
                           (general-fixnum-fixnum-case)))))
               ((##bignum? y)
                (cond ((##fixnum.zero? x)
                       0)
                      ((##bignum.negative? y)
                       (if (##fixnum.negative? x)
                           -1
                           0))
                      (else
                       (overflow))))
               (else
                (type-error-on-y))))
        ((##bignum? x)
         (cond ((##eq? y 0)
                x)
               ((##fixnum? y)
                (##bignum.arithmetic-shift x y))
               ((##bignum? y)
                (cond ((##bignum.negative? y)
                       (if (##bignum.negative? x)
                           -1
                           0))
                      (else
                       (overflow))))
               (else
                (type-error-on-y))))
        (else
         (type-error-on-x))))

(define-prim (arithmetic-shift x y)
  (macro-force-vars (x y)
    (##arithmetic-shift x y)))

(define-prim (##bit-count x)

  (define (type-error)
    (##fail-check-exact-integer 1 bit-count x))

  (cond ((##fixnum? x)
         (##fxbit-count x))
        ((##bignum? x)
         (let ((x-length (##bignum.mdigit-length x)))
           (let loop ((i (##fixnum.- x-length 1))
                      (n 0))
             (if (##fixnum.< i 0)
                 (if (##bignum.negative? x)
                     (##fixnum.- (##fixnum.* x-length ##bignum.mdigit-width) n)
                     n)
                 (loop (##fixnum.- i 1)
                       (##fixnum.+ n (##fxbit-count (##bignum.mdigit-ref x i))))))))
        (else
         (type-error))))

(define-prim (bit-count x)
  (macro-force-vars (x)
    (##bit-count x)))

(define-prim (##integer-length x)

  (define (type-error)
    (##fail-check-exact-integer 1 integer-length x))

  (cond ((##fixnum? x)
         (##fxlength x))
        ((##bignum? x)
         (let ((x-length (##bignum.mdigit-length x)))
           (if (##bignum.negative? x)
               (let loop1 ((i (##fixnum.- x-length 1)))
                 (let ((mdigit (##bignum.mdigit-ref x i)))
                   (if (##fixnum.= mdigit ##bignum.mdigit-base-minus-1)
                       (loop1 (##fixnum.- i 1))
                       (##fixnum.+
                        (##fxlength (##fixnum.- ##bignum.mdigit-base-minus-1 mdigit))
                        (##fixnum.* i ##bignum.mdigit-width)))))
               (let loop2 ((i (##fixnum.- x-length 1)))
                 (let ((mdigit (##bignum.mdigit-ref x i)))
                   (if (##fixnum.= mdigit 0)
                       (loop2 (##fixnum.- i 1))
                       (##fixnum.+
                        (##fxlength mdigit)
                        (##fixnum.* i ##bignum.mdigit-width))))))))
        (else
         (type-error))))

(define-prim (integer-length x)
  (macro-force-vars (x)
    (##integer-length x)))

(define-prim (##bitwise-merge x y z)
  (##bitwise-ior (##bitwise-and (##bitwise-not x) y)
                 (##bitwise-and x z)))

(define-prim (bitwise-merge x y z)
  (macro-force-vars (x y z)
    (cond ((##not (macro-exact-int? x))
           (##fail-check-exact-integer 1 bitwise-merge x y z))
          ((##not (macro-exact-int? y))
           (##fail-check-exact-integer 2 bitwise-merge x y z))
          ((##not (macro-exact-int? z))
           (##fail-check-exact-integer 3 bitwise-merge x y z))
          (else
           (##bitwise-merge x y z)))))

(define-prim (##bit-set? x y)

  (define (type-error-on-x)
    (##fail-check-exact-integer 1 bit-set? x y))

  (define (type-error-on-y)
    (##fail-check-exact-integer 2 bit-set? x y))

  (define (range-error)
    (##raise-range-exception 1 bit-set? x y))

  (cond ((##fixnum? x)
         (cond ((##fixnum? y)
                (if (##fixnum.negative? x)
                    (range-error)
                    (if (##fixnum.< x ##fixnum-width)
                        (##fixnum.odd? (##fixnum.arithmetic-shift-right y x))
                        (##fixnum.negative? y))))
               ((##bignum? y)
                (if (##fixnum.negative? x)
                    (range-error)
                    (let ((i (##fixnum.quotient x ##bignum.mdigit-width)))
                      (if (##fixnum.< i (##bignum.mdigit-length y))
                          (##fixnum.odd?
                           (##fixnum.arithmetic-shift-right
                            (##bignum.mdigit-ref y i)
                            (##fixnum.modulo x ##bignum.mdigit-width)))
                          (##bignum.negative? y)))))
               (else
                (type-error-on-y))))
        ((##bignum? x)
         (cond ((##fixnum? y)
                (if (##bignum.negative? x)
                    (range-error)
                    (##fixnum.negative? y)))
               ((##bignum? y)
                (if (##bignum.negative? x)
                    (range-error)
                    (##bignum.negative? y)))
               (else
                (type-error-on-y))))
        (else
         (type-error-on-x))))

(define-prim (bit-set? x y)
  (macro-force-vars (x y)
    (##bit-set? x y)))

(define-prim (##any-bits-set? x y)
  (##not (##eq? (##bitwise-and x y) 0)))

(define-prim (any-bits-set? x y)
  (macro-force-vars (x y)
    (cond ((##not (macro-exact-int? x))
           (##fail-check-exact-integer 1 any-bits-set? x y))
          ((##not (macro-exact-int? y))
           (##fail-check-exact-integer 2 any-bits-set? x y))
          (else
           (##any-bits-set? x y)))))

(define-prim (##all-bits-set? x y)
  (##= x (##bitwise-and x y)))

(define-prim (all-bits-set? x y)
  (macro-force-vars (x y)
    (cond ((##not (macro-exact-int? x))
           (##fail-check-exact-integer 1 all-bits-set? x y))
          ((##not (macro-exact-int? y))
           (##fail-check-exact-integer 2 all-bits-set? x y))
          (else
           (##all-bits-set? x y)))))

(define-prim (##first-bit-set x)

  (define (type-error)
    (##fail-check-exact-integer 1 first-bit-set x))

  (cond ((##fixnum? x)
         (##fxfirst-bit-set x))
        ((##bignum? x)
         (let ((x-length (##bignum.mdigit-length x)))
           (let loop ((i 0))
             (let ((mdigit (##bignum.mdigit-ref x i)))
               (if (##fixnum.= mdigit 0)
                   (loop (##fixnum.+ i 1))
                   (##fixnum.+
                    (##fxfirst-bit-set mdigit)
                    (##fixnum.* i ##bignum.mdigit-width)))))))
        (else
         (type-error))))

(define-prim (first-bit-set x)
  (macro-force-vars (x)
    (##first-bit-set x)))

(define ##extract-bit-field-fixnum-limit
  (##fixnum.- ##fixnum-width 1))

(define-prim (##extract-bit-field size position n)

  ;; size and position must be nonnegative

  (define (fixup-top-word result size)
    (##declare (not interrupts-enabled))
    (let ((size-words (##fixnum.quotient  size ##bignum.mdigit-width))
          (size-bits  (##fixnum.remainder size ##bignum.mdigit-width)))
      (let loop ((i (##fixnum.- (##bignum.mdigit-length result) 1)))
        (cond ((##fixnum.< size-words i)
               (##bignum.mdigit-set! result i 0)
               (loop (##fixnum.- i 1)))
              ((##eq? size-words i)
               (##bignum.mdigit-set!
                result i
                (##fixnum.bitwise-and
                 (##bignum.mdigit-ref result i)
                 (##fixnum.bitwise-not (##fixnum.arithmetic-shift-left -1 size-bits))))
               (##bignum.normalize! result))
              (else
               (##bignum.normalize! result))))))

  (cond ((##bignum? size)
         (if (##negative? n)
             (##bignum.make ##max-fixnum #f #f) ;; generates heap overflow
             (##arithmetic-shift n (##- position))))
        ((##bignum? position)
         (if (##negative? n)
             (##extract-bit-field size 0 -1)
             0))
        ((and (##fixnum? n)
              (##fixnum.< size ##extract-bit-field-fixnum-limit))
         (##fixnum.bitwise-and (##fixnum.arithmetic-shift-right
                                n
                                (##fixnum.min position ##extract-bit-field-fixnum-limit))
                               (##fixnum.bitwise-not (##fixnum.arithmetic-shift-left -1 size))))
        (else
         (let* ((n (if (##fixnum? n)
                       (##bignum.<-fixnum n)
                       n))
                (n-length (##bignum.adigit-length n))
                (n-negative? (##bignum.negative? n))
                (result-bit-size
                 (if n-negative?
                     size
                     (##fixnum.min
                      (##fixnum.- (##fixnum.* ##bignum.adigit-width
                                              n-length)
                                  position
                                  1) ;; the top bit of a nonnegative bignum is always 0
                      size))))
           (if (##fixnum.<= result-bit-size 0)
               0
               (let* ((result-word-size
                       (##fixnum.+ (##fixnum.quotient result-bit-size
                                                      ##bignum.adigit-width)
                                   1))
                      (result (if (##eq? position 0)
                                  ;; copy lowest result-word-size
                                  ;; words of n to result
                                  (##bignum.make result-word-size n #f)
                                  (##bignum.make result-word-size #f n-negative?)))
                      (word-shift (##fixnum.quotient position ##bignum.adigit-width))
                      (bit-shift (##fixnum.remainder position ##bignum.adigit-width))
                      (divider (##fixnum.- ##bignum.adigit-width bit-shift))
                      )
                 (cond ((##eq? position 0)
                        (fixup-top-word result size))
                       ((##eq? bit-shift 0)
                        (let ((word-limit (##fixnum.min (##fixnum.+ word-shift result-word-size)
                                                        n-length)))
                          (##declare (not interrupts-enabled))
                          (let loop ((i 0)
                                     (j word-shift))
                            (if (##fixnum.< j word-limit)
                                (begin
                                  (##bignum.adigit-copy! result i n j)
                                  (loop (##fixnum.+ i 1)
                                        (##fixnum.+ j 1)))
                                (fixup-top-word result size)))))
                       (else
                        (let ((left-fill (if n-negative?
                                             ##bignum.adigit-ones
                                             ##bignum.adigit-zeros))
                              (word-limit (##fixnum.- (##fixnum.min (##fixnum.+ word-shift result-word-size)
                                                                    n-length)
                                                      1)))
                          (##declare (not interrupts-enabled))
                          (let loop ((i 0)
                                     (j word-shift))
                            (cond ((##fixnum.< j word-limit)
                                   (##bignum.adigit-cat! result i
                                                         n (##fixnum.+ j 1)
                                                         n j
                                                         divider)
                                   (loop (##fixnum.+ i 1)
                                         (##fixnum.+ j 1)))
                                  ((##fixnum.< j (##fixnum.- n-length 1))
                                   (##bignum.adigit-cat! result i
                                                         n (##fixnum.+ j 1)
                                                         n j
                                                         divider)
                                   (fixup-top-word result size))
                                  ((##fixnum.= j (##fixnum.- n-length 1))
                                   (##bignum.adigit-cat! result i
                                                         left-fill 0
                                                         n j
                                                         divider)
                                   (fixup-top-word result size))
                                  (else
                                   (fixup-top-word result size)))))))))))))

(define-prim (extract-bit-field size position n)
  (macro-force-vars (size position n)
    (macro-check-index
     size
     1
     (extract-bit-field size position n)
     (macro-check-index
      position
      2
      (extract-bit-field size position n)
      (if (##not (macro-exact-int? n))
          (##fail-check-exact-integer 3 extract-bit-field size position n)
          (##extract-bit-field size position n))))))

(define-prim (##test-bit-field? size position n)
  (##not (##eq? (##extract-bit-field size position n)
                0)))

(define-prim (test-bit-field? size position n)
  (macro-force-vars (size position n)
    (macro-check-index
     size
     1
     (test-bit-field? size position n)
     (macro-check-index
      position
      2
      (test-bit-field? size position n)
      (if (##not (macro-exact-int? n))
          (##fail-check-exact-integer 3 test-bit-field? size position n)
          (##test-bit-field? size position n))))))

(define-prim (##clear-bit-field size position n)
  (##replace-bit-field size position 0 n))

(define-prim (clear-bit-field size position n)
  (macro-force-vars (size position n)
    (macro-check-index
     size
     1
     (clear-bit-field size position n)
     (macro-check-index
      position
      2
      (clear-bit-field size position n)
      (if (##not (macro-exact-int? n))
           (##fail-check-exact-integer 3 clear-bit-field size position n)
           (##clear-bit-field size position n))))))

(define-prim (##replace-bit-field size position newfield n)
  (let ((m (##bit-mask size)))
    (##bitwise-ior
     (##bitwise-and n (##bitwise-not (##arithmetic-shift m position)))
     (##arithmetic-shift (##bitwise-and newfield m) position))))

(define-prim (replace-bit-field size position newfield n)
  (macro-force-vars (size position newfield n)
    (macro-check-index
     size
     1
     (replace-bit-field size position newfield n)
     (macro-check-index
      position
      2
      (replace-bit-field size position newfield n)
      (cond ((##not (macro-exact-int? newfield))
             (##fail-check-exact-integer 3 replace-bit-field size position newfield n))
            ((##not (macro-exact-int? n))
             (##fail-check-exact-integer 4 replace-bit-field size position newfield n))
            (else
             (##replace-bit-field size position newfield n)))))))

(define-prim (##copy-bit-field size position from to)
  (##bitwise-merge
   (##arithmetic-shift (##bit-mask size) position)
   to
   from))

(define-prim (copy-bit-field size position from to)
  (macro-force-vars (size position from to)
    (macro-check-index
     size
     1
     (copy-bit-field size position from to)
     (macro-check-index
      position
      2
      (copy-bit-field size position from to)
      (cond ((##not (macro-exact-int? from))
             (##fail-check-exact-integer 3 copy-bit-field size position from to))
            ((##not (macro-exact-int? to))
             (##fail-check-exact-integer 4 copy-bit-field size position from to))
            (else
             (##copy-bit-field size position from to)))))))

(define-prim (##bit-mask size)
  (##bitwise-not (##arithmetic-shift -1 size)))

;;;----------------------------------------------------------------------------

;;; Fixnum operations
;;; -----------------

(##define-macro (define-prim-fixnum form . special-body)
  (let ((body (if (null? special-body) form `(begin ,@special-body))))
    (cond ((= 1 (length (cdr form)))
           (let* ((name-fn (car form))
                  (name-param1 (cadr form)))
             `(define-prim ,form
                (macro-force-vars (,name-param1)
                  (macro-check-fixnum
                    ,name-param1
                    1
                    ,form
                    ,body)))))
          ((= 2 (length (cdr form)))
           (let* ((name-fn (car form))
                  (name-param1 (cadr form))
                  (name-param2 (caddr form)))
             `(define-prim ,form
                (macro-force-vars (,name-param1 ,name-param2)
                  (macro-check-fixnum
                    ,name-param1
                    1
                    ,form
                    (macro-check-fixnum
                      ,name-param2
                      2
                      ,form
                      ,body))))))
          (else
           (error "define-prim-fixnum supports only 1 or 2 parameter procedures")))))

(define-prim (fixnum? obj)
  (##fixnum? obj))

(define-prim-nary-bool (##fx= x y)
  #t
  #t
  (##fx= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fx= x y)
  #t
  #t
  (##fx= x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary-bool (##fx< x y)
  #t
  #t
  (##fx< x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fx< x y)
  #t
  #t
  (##fx< x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary-bool (##fx> x y)
  #t
  #t
  (##fx> x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fx> x y)
  #t
  #t
  (##fx> x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary-bool (##fx<= x y)
  #t
  #t
  (##fx<= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fx<= x y)
  #t
  #t
  (##fx<= x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary-bool (##fx>= x y)
  #t
  #t
  (##fx>= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fx>= x y)
  #t
  #t
  (##fx>= x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim (##fxzero? x))

(define-prim-fixnum (fxzero? x)
  (##fxzero? x))

(define-prim (##fxpositive? x))

(define-prim-fixnum (fxpositive? x)
  (##fxpositive? x))

(define-prim (##fxnegative? x))

(define-prim-fixnum (fxnegative? x)
  (##fxnegative? x))

(define-prim (##fxodd? x))

(define-prim-fixnum (fxodd? x)
  (##fxodd? x))

(define-prim (##fxeven? x))

(define-prim-fixnum (fxeven? x)
  (##fxeven? x))

(define-prim-nary (##fxmax x y)
  ()
  x
  (##fxmax x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxmax x y)
  ()
  x
  (##fxmax x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fxmin x y)
  ()
  x
  (##fxmin x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxmin x y)
  ()
  x
  (##fxmin x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fxwrap+ x y)
  0
  x
  (##fxwrap+ x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxwrap+ x y)
  0
  x
  (##fxwrap+ x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fx+ x y)
  0
  x
  (##fx+ x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fx+ x y)
  0
  x
  (##fx+? x y)
  macro-force-vars
  macro-check-fixnum
  (##not ##raise-fixnum-overflow-exception))

(define-prim (##fx+? x y))

(define-prim-nary (##fxwrap* x y)
  1
  x
  (##fxwrap* x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxwrap* x y)
  1
  x
  (##fxwrap* x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fx* x y)
  1
  x
  (##fx* x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fx* x y)
  1
  x
  ((lambda (x y)
     (cond ((##eqv? y 0)
            0)
           ((##eqv? y -1)
            (##fx-? x))
           (else
            (##fx*? x y))))
   x
   y)
  macro-force-vars
  macro-check-fixnum
  (##not ##raise-fixnum-overflow-exception))

(define-prim (##fx*? x y))

(define-prim-nary (##fxwrap- x y)
  ()
  (##fxwrap- x)
  (##fxwrap- x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxwrap- x y)
  ()
  (##fxwrap- x)
  (##fxwrap- x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fx- x y)
  ()
  (##fx- x)
  (##fx- x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fx- x y)
  ()
  (##fx-? x)
  (##fx-? x y)
  macro-force-vars
  macro-check-fixnum
  (##not ##raise-fixnum-overflow-exception))

(define-prim (##fx-? x #!optional (y (macro-absent-obj)))
  (if (##eq? y (macro-absent-obj))
      (##fx-? x)
      (##fx-? x y)))

(define-prim (##fxwrapquotient x y))

(define-prim-fixnum (fxwrapquotient x y)
  (if (##eq? y 0)
      (##raise-divide-by-zero-exception fxwrapquotient x y)
      (##fxwrapquotient x y)))

(define-prim (##fxquotient x y))

(define-prim-fixnum (fxquotient x y)
  (if (##eq? y 0)
      (##raise-divide-by-zero-exception fxquotient x y)
      (if (##eq? y -1)
          (or (##fx-? x)
              (##raise-fixnum-overflow-exception fxquotient x y))
          (##fxquotient x y))))

(define-prim (##fxremainder x y))

(define-prim-fixnum (fxremainder x y)
  (if (##eq? y 0)
      (##raise-divide-by-zero-exception fxremainder x y)
      (##fxremainder x y)))

(define-prim (##fxmodulo x y))

(define-prim-fixnum (fxmodulo x y)
  (if (##eq? y 0)
      (##raise-divide-by-zero-exception fxmodulo x y)
      (##fxmodulo x y)))

(define-prim (##fxnot x)
  (##fx- -1 x))

(define-prim-fixnum (fxnot x)
  (##fxnot x))

(define-prim-nary (##fxand x y)
  -1
  x
  (##fxand x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxand x y)
  -1
  x
  (##fxand x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fxior x y)
  0
  x
  (##fxior x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxior x y)
  0
  x
  (##fxior x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim-nary (##fxxor x y)
  0
  x
  (##fxxor x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fxxor x y)
  0
  x
  (##fxxor x y)
  macro-force-vars
  macro-check-fixnum)

(define-prim (##fxif x y z))

(define-prim (fxif x y z)
  (macro-force-vars (x y z)
    (macro-check-fixnum
      x
      1
      (fxif x y z)
      (macro-check-fixnum
        y
        2
        (fxif x y z)
        (macro-check-fixnum
          z
          3
          (fxif x y z)
          (##fxif x y z))))))

(define-prim (##fxbit-count x))

(define-prim (fxbit-count x)
  (macro-force-vars (x)
    (macro-check-fixnum
      x
      1
      (fxbit-count x)
      (##fxbit-count x))))

(define-prim (##fxlength x))

(define-prim (fxlength x)
  (macro-force-vars (x)
    (macro-check-fixnum
      x
      1
      (fxlength x)
      (##fxlength x))))

(define-prim (##fxfirst-bit-set x))

(define-prim (fxfirst-bit-set x)
  (macro-force-vars (x)
    (macro-check-fixnum
      x
      1
      (fxfirst-bit-set x)
      (##fxfirst-bit-set x))))

(define-prim (##fxbit-set? x y))

(define-prim (fxbit-set? x y)
  (macro-force-vars (x y)
    (macro-check-fixnum-range-incl
      x
      1
      0
      ##fixnum-width
      (fxbit-set? x y)
      (macro-check-fixnum
        y
        2
        (fxbit-set? x y)
        (##fxbit-set? x y)))))

(define-prim (##fxwraparithmetic-shift x y))

(define-prim (fxwraparithmetic-shift x y)
  (macro-force-vars (x y)
    (macro-check-fixnum
      x
      1
      (fxwraparithmetic-shift x y)
      (macro-check-fixnum-range-incl
        y
        2
        ##fixnum-width-neg
        ##fixnum-width
        (fxwraparithmetic-shift x y)
        (##fxwraparithmetic-shift x y)))))

(define-prim (##fxarithmetic-shift x y))

(define-prim-fixnum (fxarithmetic-shift x y)
  (or (##fxarithmetic-shift? x y)
      (##raise-fixnum-overflow-exception fxarithmetic-shift x y)))

(define-prim (##fxarithmetic-shift? x y))

(define-prim (##fxwraparithmetic-shift-left x y))

(define-prim (fxwraparithmetic-shift-left x y)
  (macro-force-vars (x y)
    (macro-check-fixnum
      x
      1
      (fxwraparithmetic-shift-left x y)
      (macro-check-fixnum-range-incl
        y
        2
        0
        ##fixnum-width
        (fxwraparithmetic-shift-left x y)
        (##fxwraparithmetic-shift-left x y)))))

(define-prim (##fxarithmetic-shift-left x y))

(define-prim-fixnum (fxarithmetic-shift-left x y)
  (or (##fxarithmetic-shift-left? x y)
      (if (##fx< y 0)
          (##raise-range-exception 2 fxarithmetic-shift-left x y)
          (##raise-fixnum-overflow-exception fxarithmetic-shift-left x y))))

(define-prim (##fxarithmetic-shift-left? x y))

(define-prim (##fxarithmetic-shift-right x y))

(define-prim-fixnum (fxarithmetic-shift-right x y)
  (or (##fxarithmetic-shift-right? x y)
      (##raise-range-exception 2 fxarithmetic-shift-right x y)))

(define-prim (##fxarithmetic-shift-right? x y))

(define-prim (##fxwraplogical-shift-right x y))

(define-prim-fixnum (fxwraplogical-shift-right x y)
  (or (##fxwraplogical-shift-right? x y)
      (##raise-range-exception 2 fxwraplogical-shift-right x y)))

(define-prim (##fxwraplogical-shift-right? x y))

(define-prim (##fxwrapabs x))

(define-prim-fixnum (fxwrapabs x)
  (##fxwrapabs x))

(define-prim (##fxabs x))

(define-prim-fixnum (fxabs x)
  (or (##fxabs? x)
      (##raise-fixnum-overflow-exception fxabs x)))

(define-prim (##fxabs? x))

(define-prim (##fx->char x))
(define-prim (##fx<-char x))

(define-prim (##fixnum->char x))
(define-prim (##char->fixnum x))




;;;;;;;;;;;;;;;;;;;;;;;; old procedures

(define-prim-nary-bool (##fixnum.= x y)
  #t
  #t
  (##fixnum.= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##fixnum.< x y)
  #t
  #t
  (##fixnum.< x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##fixnum.> x y)
  #t
  #t
  (##fixnum.> x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##fixnum.<= x y)
  #t
  #t
  (##fixnum.<= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##fixnum.>= x y)
  #t
  #t
  (##fixnum.>= x y)
  macro-no-force
  macro-no-check)

(define-prim (##fixnum.zero? x))

(define-prim (##fixnum.positive? x))

(define-prim (##fixnum.negative? x))

(define-prim (##fixnum.odd? x))

(define-prim (##fixnum.even? x))

(define-prim-nary (##fixnum.max x y)
  ()
  x
  (##fixnum.max x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.min x y)
  ()
  x
  (##fixnum.min x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.wrap+ x y)
  0
  x
  (##fixnum.wrap+ x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.+ x y)
  0
  x
  (##fixnum.+ x y)
  macro-no-force
  macro-no-check)

(define-prim (##fixnum.+? x y))

(define-prim-nary (##fixnum.wrap* x y)
  1
  x
  (##fixnum.wrap* x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.* x y)
  1
  x
  (##fixnum.* x y)
  macro-no-force
  macro-no-check)

(define-prim (##fixnum.*? x y))

(define-prim-nary (##fixnum.wrap- x y)
  ()
  (##fixnum.wrap- x)
  (##fixnum.wrap- x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.- x y)
  ()
  (##fixnum.- x)
  (##fixnum.- x y)
  macro-no-force
  macro-no-check)

(define-prim (##fixnum.-? x #!optional (y (macro-absent-obj)))
  (if (##eq? y (macro-absent-obj))
      (##fixnum.-? x)
      (##fixnum.-? x y)))

(define-prim (##fixnum.wrapquotient x y))

(define-prim (##fixnum.quotient x y))

(define-prim (##fixnum.remainder x y))

(define-prim (##fixnum.modulo x y))

(define-prim (##fixnum.bitwise-not x)
  (##fixnum.- -1 x))

(define-prim-nary (##fixnum.bitwise-and x y)
  -1
  x
  (##fixnum.bitwise-and x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.bitwise-ior x y)
  0
  x
  (##fixnum.bitwise-ior x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##fixnum.bitwise-xor x y)
  0
  x
  (##fixnum.bitwise-xor x y)
  macro-no-force
  macro-no-check)

(define-prim (##fixnum.wraparithmetic-shift x y))

(define-prim (##fixnum.arithmetic-shift x y))

(define-prim (##fixnum.arithmetic-shift? x y))

(define-prim (##fixnum.wraparithmetic-shift-left x y))

(define-prim (##fixnum.arithmetic-shift-left x y))

(define-prim (##fixnum.arithmetic-shift-left? x y))

(define-prim (##fixnum.arithmetic-shift-right x y))

(define-prim (##fixnum.arithmetic-shift-right? x y))

(define-prim (##fixnum.wraplogical-shift-right x y))

(define-prim (##fixnum.wraplogical-shift-right? x y))

(define-prim (##fixnum.wrapabs x))

(define-prim (##fixnum.abs x))

(define-prim (##fixnum.abs? x))

(define-prim (##fixnum.->char x))
(define-prim (##fixnum.<-char x))

;;;----------------------------------------------------------------------------

;; Bignum operations
;; -----------------

;; The bignum operations were mostly implemented by the "Uber numerical
;; analyst Brad Lucier (http://www.math.purdue.edu/~lucier) with some
;; coding guidance from Marc Feeley.

;; Bignums are represented with 'adigit' vectors.  Each element is an
;; integer containing ##bignum.adigit-width bits (typically 64 bits).
;; These bits encode an integer in two's complement representation.
;; The first element contains the least significant bits and the most
;; significant bit of the last element is the sign (0=positive,
;; 1=negative).

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define-prim (##bignum.negative? x))
(define-prim (##bignum.adigit-length x))
(define-prim (##bignum.adigit-inc! x i))
(define-prim (##bignum.adigit-dec! x i))
(define-prim (##bignum.adigit-add! x i y j carry))
(define-prim (##bignum.adigit-sub! x i y j borrow))
(define-prim (##bignum.mdigit-length x))
(define-prim (##bignum.mdigit-ref x i))
(define-prim (##bignum.mdigit-set! x i mdigit))
(define-prim (##bignum.mdigit-mul! x i y j multiplier carry))
(define-prim (##bignum.mdigit-div! x i y j quotient borrow))
(define-prim (##bignum.mdigit-quotient u j v_n-1))
(define-prim (##bignum.mdigit-remainder u j v_n-1 q-hat))
(define-prim (##bignum.mdigit-test? q-hat v_n-2 r-hat u_j-2))

(define-prim (##bignum.adigit-ones? x i))
(define-prim (##bignum.adigit-zero? x i))
(define-prim (##bignum.adigit-negative? x i))
(define-prim (##bignum.adigit-= x y i))
(define-prim (##bignum.adigit-< x y i))
(define-prim (##bignum.->fixnum x))
(define-prim (##bignum.<-fixnum x))
(define-prim (##bignum.adigit-shrink! x n))
(define-prim (##bignum.adigit-copy! x i y j))
(define-prim (##bignum.adigit-cat! x i hi j lo k divider))
(define-prim (##bignum.adigit-bitwise-and! x i y j))
(define-prim (##bignum.adigit-bitwise-ior! x i y j))
(define-prim (##bignum.adigit-bitwise-xor! x i y j))
(define-prim (##bignum.adigit-bitwise-not! x i))

(define-prim (##bignum.fdigit-length x))
(define-prim (##bignum.fdigit-ref x i))
(define-prim (##bignum.fdigit-set! x i fdigit))

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Bignum related constants.

(define ##bignum.adigit-ones #xffffffffffffffff)
(define ##bignum.adigit-zeros #x10000000000000000)

(define ##bignum.fdigit-base
  (##fixnum.arithmetic-shift-left 1 ##bignum.fdigit-width))

(define ##bignum.mdigit-base
  (##fixnum.arithmetic-shift-left 1 ##bignum.mdigit-width))

(define ##bignum.inexact-mdigit-base
  (##flonum.<-fixnum ##bignum.mdigit-base))

(define ##bignum.mdigit-base-minus-1
  (##fixnum.- ##bignum.mdigit-base 1))

(define ##bignum.minus-mdigit-base
  (##fixnum.- ##bignum.mdigit-base))

(define ##bignum.max-fixnum-div-mdigit-base
  (##fixnum.quotient ##max-fixnum ##bignum.mdigit-base))

(define ##bignum.min-fixnum-div-mdigit-base
  (##fixnum.quotient ##min-fixnum ##bignum.mdigit-base))

(define ##bignum.2*min-fixnum
  (if (##fixnum? -1073741824)
      -4611686018427387904 ;; (- (expt 2 62))
      -1073741824))        ;; (- (expt 2 30))

;;; The following global variables control when each of the three
;;; multiplication algorithms are used.

(define ##bignum.naive-mul-max-width 1400)
(set! ##bignum.naive-mul-max-width ##bignum.naive-mul-max-width)

(define ##bignum.fft-mul-min-width 20000)
(set! ##bignum.fft-mul-min-width ##bignum.fft-mul-min-width)

(define ##bignum.fft-mul-max-width
  (if (##fixnum? -1073741824) ;; to avoid creating f64vectors that are too long
      536870912
      4194304))
(set! ##bignum.fft-mul-max-width ##bignum.fft-mul-max-width)


(define ##bignum.fast-gcd-size ##bignum.naive-mul-max-width)  ;; must be >= 64
(set! ##bignum.fast-gcd-size ##bignum.fast-gcd-size)

;;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;;; Operations where arguments are in bignum format

(define-prim (##bignum.make k x complement?)
  (##declare (not interrupts-enabled))
  (let ((v (##c-code "
long i;
long n = ___INT(___ARG1);
#if ___BIG_ABASE_WIDTH == 32
long words = ___WORDS((n*(___BIG_ABASE_WIDTH/8))) + 1;
#else
#if ___WS == 4
long words = ___WORDS((n*(___BIG_ABASE_WIDTH/8))) + 2;
#else
long words = ___WORDS((n*(___BIG_ABASE_WIDTH/8))) + 1;
#endif
#endif
___SCMOBJ result;

if (n > ___CAST(___WORD, ___LMASK>>___LF)/(___BIG_ABASE_WIDTH/8))
  result = ___FIX(___HEAP_OVERFLOW_ERR); /* requested object is too big! */
else if (words > ___MSECTION_BIGGEST)
  {
    ___FRAME_STORE_RA(___R0)
    ___W_ALL
#if ___BIG_ABASE_WIDTH == 32
    result = ___alloc_scmobj (___sBIGNUM, n<<2, ___STILL);
#else
    result = ___alloc_scmobj (___sBIGNUM, n<<3, ___STILL);
#endif
    ___R_ALL
    ___SET_R0(___FRAME_FETCH_RA)
    if (!___FIXNUMP(result))
      ___still_obj_refcount_dec (result);
  }
else
  {
    ___BOOL overflow = 0;
    ___hp += words;
    if (___hp > ___ps->heap_limit)
      {
        ___FRAME_STORE_RA(___R0)
        ___W_ALL
        overflow = ___heap_limit () && ___garbage_collect (0);
        ___R_ALL
        ___SET_R0(___FRAME_FETCH_RA)
      }
    else
      ___hp -= words;
    if (overflow)
      result = ___FIX(___HEAP_OVERFLOW_ERR);
    else
      {
#if ___BIG_ABASE_WIDTH == 32
        result = ___TAG(___hp, ___tSUBTYPED);
#else
#if ___WS == 4
        result = ___TAG(___CAST(___SCMOBJ*,___CAST(___SCMOBJ,___hp+2)&~7)-1,
                        ___tSUBTYPED);
#else
        result = ___TAG(___hp, ___tSUBTYPED);
#endif
#endif
#if ___BIG_ABASE_WIDTH == 32
        ___HEADER(result) = ___MAKE_HD_BYTES((n<<2), ___sBIGNUM);
#else
        ___HEADER(result) = ___MAKE_HD_BYTES((n<<3), ___sBIGNUM);
#endif
        ___hp += words;
      }
  }
if (!___FIXNUMP(result))
  {
    ___SCMOBJ x = ___ARG2;
    ___SCMOBJ len;
    if (x == ___FAL)
      len = 0;
    else
      {
        len = ___INT(___BIGALENGTH(x));
        if (len > n)
          len = n;
      }
#if ___BIG_ABASE_WIDTH == 32
    if (___ARG3 == ___FAL)
      {
        for (i=0; i<len; i++)
          ___STORE_U32(___BODY_AS(result,___tSUBTYPED),i,
                       ___FETCH_U32(___BODY_AS(x,___tSUBTYPED),i));
        if (x != ___FAL &&
            ___FETCH_S32(___BODY_AS(x,___tSUBTYPED),(i-1)) < 0)
          for (; i<n; i++)
            ___STORE_U32(___BODY_AS(result,___tSUBTYPED),i,___BIG_ABASE_MIN_1);
        else
          for (; i<n; i++)
            ___STORE_U32(___BODY_AS(result,___tSUBTYPED),i,0);
      }
    else
      {
        for (i=0; i<len; i++)
          ___STORE_U32(___BODY_AS(result,___tSUBTYPED),i,
                       ~___FETCH_U32(___BODY_AS(x,___tSUBTYPED),i));
        if (x != ___FAL &&
            ___FETCH_S32(___BODY_AS(x,___tSUBTYPED),(i-1)) < 0)
          for (; i<n; i++)
            ___STORE_U32(___BODY_AS(result,___tSUBTYPED),i,0);
        else
          for (; i<n; i++)
            ___STORE_U32(___BODY_AS(result,___tSUBTYPED),i,___BIG_ABASE_MIN_1);
      }
#else
    if (___ARG3 == ___FAL)
      {
        for (i=0; i<len; i++)
          ___STORE_U64(___BODY_AS(result,___tSUBTYPED),i,
                       ___FETCH_U64(___BODY_AS(x,___tSUBTYPED),i));
        if (x != ___FAL &&
            ___FETCH_S64(___BODY_AS(x,___tSUBTYPED),(i-1)) < 0)
          for (; i<n; i++)
            ___STORE_U64(___BODY_AS(result,___tSUBTYPED),i,___BIG_ABASE_MIN_1);
        else
          for (; i<n; i++)
            ___STORE_U64(___BODY_AS(result,___tSUBTYPED),i,0);
      }
    else
      {
        for (i=0; i<len; i++)
          ___STORE_U64(___BODY_AS(result,___tSUBTYPED),i,
                       ~___FETCH_U64(___BODY_AS(x,___tSUBTYPED),i));
        if (x != ___FAL &&
            ___FETCH_S64(___BODY_AS(x,___tSUBTYPED),(i-1)) < 0)
          for (; i<n; i++)
            ___STORE_U64(___BODY_AS(result,___tSUBTYPED),i,0);
        else
          for (; i<n; i++)
            ___STORE_U64(___BODY_AS(result,___tSUBTYPED),i,___BIG_ABASE_MIN_1);
      }
#endif
  }
___RESULT = result;
" k x complement?)))
    (if (##fixnum? v)
        (begin
          (##raise-heap-overflow-exception)
          (##bignum.make k x complement?))
        v)))

;;; Bignum comparison.

(define-prim (##bignum.= x y)

  ;; x is a normalized bignum, y is a normalized bignum

  (##declare (not interrupts-enabled))

  (let ((x-length (##bignum.adigit-length x)))
    (and (##fixnum.= x-length (##bignum.adigit-length y))
         (let loop ((i (##fixnum.- x-length 1)))
           (or (##fixnum.< i 0)
               (and (##bignum.adigit-= x y i)
                    (loop (##fixnum.- i 1))))))))

(define-prim (##bignum.< x y)

  ;; x is a normalized bignum, y is a normalized bignum

  (##declare (not interrupts-enabled))

  (define (loop i)
    (and (##not (##fixnum.< i 0))
         (or (##bignum.adigit-< x y i)
             (and (##bignum.adigit-= x y i)
                  (loop (##fixnum.- i 1))))))

  (if (##bignum.negative? x)
      (if (##bignum.negative? y)
          (let ((x-length (##bignum.adigit-length x))
                (y-length (##bignum.adigit-length y)))
            (or (##fixnum.< y-length x-length)
                (and (##fixnum.= x-length y-length)
                     (loop (##fixnum.- x-length 1)))))
          #t)
      (if (##bignum.negative? y)
          #f
          (let ((x-length (##bignum.adigit-length x))
                (y-length (##bignum.adigit-length y)))
            (or (##fixnum.< x-length y-length)
                (and (##fixnum.= x-length y-length)
                     (loop (##fixnum.- x-length 1))))))))

;;; Bignum addition and subtraction.

(define-prim (##bignum.+ x y)

  ;; x is an unnormalized bignum, y is an unnormalized bignum

  (define (add x x-length y y-length)
    (let* ((result-length
            (##fixnum.+ y-length
                        (if (##eq? (##bignum.negative? x)
                                   (##bignum.negative? y))
                            1
                            0)))
           (result
            (##bignum.make result-length y #f)))

      (##declare (not interrupts-enabled))

      (let loop ((i 0)
                 (carry 0))
        (if (##fixnum.< i x-length)
            (loop (##fixnum.+ i 1)
                  (##bignum.adigit-add! result i x i carry))
            (##bignum.propagate-carry-and-normalize!
             result
             result-length
             x-length
             (##bignum.negative? x)
             (##fixnum.zero? carry))))))

  (let ((x-length (##bignum.adigit-length x))
        (y-length (##bignum.adigit-length y)))
    (if (##fixnum.< x-length y-length)
        (add x x-length y y-length)
        (add y y-length x x-length))))

(define-prim (##bignum.- x y)

  ;; x is an unnormalized bignum, y is an unnormalized bignum

  (let ((x-length (##bignum.adigit-length x))
        (y-length (##bignum.adigit-length y)))
    (if (##fixnum.< x-length y-length)

        (let* ((result-length
                (##fixnum.+ y-length
                            (if (##eq? (##bignum.negative? x)
                                       (##bignum.negative? y))
                                0
                                1)))
               (result
                (##bignum.make result-length y #t)))

          (##declare (not interrupts-enabled))

          (let loop1 ((i 0)
                      (carry 1))
            (if (##fixnum.< i x-length)
                (loop1 (##fixnum.+ i 1)
                       (##bignum.adigit-add! result i x i carry))
                (##bignum.propagate-carry-and-normalize!
                 result
                 result-length
                 x-length
                 (##bignum.negative? x)
                 (##fixnum.zero? carry)))))

        (let* ((result-length
                (##fixnum.+ x-length
                            (if (##eq? (##bignum.negative? x)
                                       (##bignum.negative? y))
                                0
                                1)))
               (result
                (##bignum.make result-length x #f)))

          (##declare (not interrupts-enabled))

          (let loop2 ((i 0)
                      (borrow 0))
            (if (##fixnum.< i y-length)
                (loop2 (##fixnum.+ i 1)
                       (##bignum.adigit-sub! result i y i borrow))
                (##bignum.propagate-carry-and-normalize!
                 result
                 result-length
                 y-length
                 (##not (##bignum.negative? y))
                 (##not (##fixnum.zero? borrow)))))))))

(define-prim (##bignum.propagate-carry-and-normalize!
              result
              result-length
              i
              borrow?
              propagate?)

  (##declare (not interrupts-enabled))

  (if (##eq? borrow? propagate?)
      (if borrow?

          (let loop1 ((i i)
                      (borrow 1))
            (if (and (##not (##fixnum.zero? borrow))
                     (##fixnum.< i result-length))
                (loop1 (##fixnum.+ i 1)
                       (##bignum.adigit-dec! result i))
                (##bignum.normalize! result)))

          (let loop2 ((i i)
                      (carry 1))
            (if (and (##not (##fixnum.zero? carry))
                     (##fixnum.< i result-length))
                (loop2 (##fixnum.+ i 1)
                       (##bignum.adigit-inc! result i))
                (##bignum.normalize! result))))

      (##bignum.normalize! result)))

(define-prim (##bignum.normalize! result)

  (##declare (not interrupts-enabled))

  (let ((n (##fixnum.- (##bignum.adigit-length result) 1)))

    (cond ((##bignum.adigit-zero? result n)
           (let loop1 ((i (##fixnum.- n 1)))
             (cond ((##fixnum.< i 0)
                    0)
                   ((##bignum.adigit-zero? result i)
                    (loop1 (##fixnum.- i 1)))
                   ((##bignum.adigit-negative? result i)
                    (##bignum.adigit-shrink! result (##fixnum.+ i 2)))
                   (else
                    (or (and (##fixnum.= i 0)
                             (##bignum.->fixnum result))
                        (##bignum.adigit-shrink! result (##fixnum.+ i 1)))))))

          ((##bignum.adigit-ones? result n)
           (let loop2 ((i (##fixnum.- n 1)))
             (cond ((##fixnum.< i 0)
                    -1)
                   ((##bignum.adigit-ones? result i)
                    (loop2 (##fixnum.- i 1)))
                   ((##not (##bignum.adigit-negative? result i))
                    (##bignum.adigit-shrink! result (##fixnum.+ i 2)))
                   (else
                    (or (and (##fixnum.= i 0)
                             (##bignum.->fixnum result))
                        (##bignum.adigit-shrink! result (##fixnum.+ i 1)))))))

          ((and (##fixnum.= n 0)
                (##bignum.->fixnum result))
           =>
           (lambda (x) x))

          (else
           result))))

;;; Bignum multiplication.

(define-prim (##bignum.* x y)

  (define (fft-mul x y)

    ;; Marc, the results of make-w should be cached, since bigger
    ;; tables can be used for any smaller size FFT.

    ;; This code works for x and y up to 536,870,912 bits, with
    ;; results up to 1Gb; numbers of this size require 8Gb, or 1GB, of
    ;; intermediate storage. It is always faster than the old code,
    ;; and it is mathematically correct.  (Whether it is
    ;; programmatically correct is, of course, another matter, but I
    ;; have tested it extensively.)

    ;; This is an experiment.

    ;; This code implements bignum multiplication based on
    ;; double-precision FFT computations rather than on
    ;; number-theoretic FFTs and the Chinese remainder theorem.

    ;; The theory is in the article

    ;; Rapid multiplication modulo the sum and difference of highly
    ;; composite numbers, by Colin Percival

    ;; The complex roots of unity ("twiddle factors") need to be
    ;; computed in such a way that there is a known bound on the
    ;; error.  I did this with a "computable reals" package I wrote.
    ;; I did not know a bound for the roots of unity in Ooura's FFT,
    ;; which is what we previously used..

    ;; If you use a different complex FFT, then you need to ensure
    ;; that the same operations are done as in this FFT (perhaps in a
    ;; somewhat different order), or that you prove the corresponding
    ;; theorem for your FFT that Percival proved in his paper.  On a
    ;; 2GHz PPC 970, my complex FFT seems to be about half as fast as
    ;; FFTW's complex FFT, so that doesn't seem too bad for one
    ;; written by hand in Scheme.

    ;; After years of fiddling around, I finally understook the
    ;; weighted FT transform and the so-called right-angle
    ;; convolution.  See section 8.3.2 the book "Algorithms for
    ;; Programmers" by Jo"rg Arndt, currently available at
    ;; www.jjj.de/fxt/fxtbook.pdf for a description of the right-angle
    ;; transform.  It's also covered in "Prime Numbers" by Crandall
    ;; and Pomerance, and was originally introduced in 1994 by
    ;; Crandall and Fagin.

    ;; The basic reference for the fft codes is
    ;; {\it Inside the FFT Black Box,} by Eleanor Chu and Alan George,
    ;; CRC Press, New York, 2000.  In the end, I should say that these
    ;; codes are just motivated by this book.

    ;; One of the biggest problem in translating their notation is
    ;; that they work with complex numbers, and we're working with
    ;; pairs of reals.  Let us assume that all complex numbers are
    ;; stored with adjacent real and imaginary parts, real first.

    #|

    The strategy in the next function is to calculate a 2^n'th
    root of unity by multiplying entries from up to three look-up
    tables, each of which has lut-table-size complex entries, stored
    as pairs of f64s.  Each of the tables contains correctly-rounded
    complex roots of unity, as computed by my computable-reals code.

    The j'th entry of the first table is

    exp(\pi/2 * i * (bit-reverse j log-lut-table-size)/lut-table-size),  j = 0,...,lut-table-size - 1.

    where (bit-reverse j k) reverses the bits of j when
    considered as a bit string of length k.

    The j'th entry of the second table is

    exp(\pi/2 * i * j/lut-table-size^2), j = 0,...,lut-table-size-1

    and the j'th entry in the third table is

    exp(\pi/2 * i * j/lut-table-size^3), j = 0,...,lut-table-size-1

    From these three tables we construct a lut w in bit-reverse
    order of size 2^log-n.

    Any table we construct is also usable for ffts of a smaller size.

    The errors in the tables are as follows.

    When log-lut-table-size=10, we have the error in the first
    table is bounded by

    7.241394152931137e-17

    Theoretically, it should be bounded by

    > (* (sqrt 1/2) (expt 2. -53))
    7.850462293418875e-17

    The maximum error in the product of the first two tables is bounded by

    2.5438950740364204e-16

    The error in the general product of two correctly-rounded
    complex floating-point numbers of magnitude one is bounded by

    > (* (+ (sqrt 5) (sqrt 1/2) (sqrt 1/2)) (expt 2. -53))
    4.052626611931048e-16

    but what we're seeing here is that the entries of the second
    table have real part close to 1 and imaginary part <
    pi/2*2^{-10}, so (a) the error in the entries of the second table
    is much closer to 1/2 epsilon rather than (sqrt 1/2) epsilon,
    and (2) we might expect an error of about sqrt(2)epsilon in the
    complex product instead of the general result of sqrt(5)epsilon,
    or

    > (* (+ (sqrt 2) (sqrt 1/2) 1/2) (expt 2. -53))
    2.910250200338241e-16

    The maximum error in the product of entries from all three tables is

    4.158491068379826e-16

    which we can plug into the error bounds.  Using the above
    heuristics, we would expect it to be <

    > (* (+ (sqrt 2) (sqrt 2) (sqrt 1/2) 1/2 1/2) (expt 2. -53))
    5.035454171334594e-16

    and we have the general bound of

    > (* (+ (* 2 (sqrt 5)) (* 3 (sqrt 1/2))) (expt 2. -53))
    7.320206994520208e-16

    so I'm glad I measured it.

    And, yes, I waited six days to compute the difference between
    the computed roots of unity and the exact roots of unity for all
    2^{30} products from the three tables.

    When log-lut-table-size=9, the corresponding maximum errors are

    7.113686303921851e-17

    for entries in the first table,

    2.4506454051660923e-16

    for products of entries in the first two tables, and

    4.164343159519809e-16

    for products from all three tables.

    Added later:

    We could try a different strategy here.

    If it's necessary to multiply entries of all three tables to populate
    the result, we multiply the entries from the last two tables first to
    get a multiplier.  Because the real parts of the second and third table
    entries are nearly one and the imaginary parts are < 2^{-9} or so, the
    rounding error in each entry is about 1/2 epsilon instead of (sqrt 1/2)
    epsilon, and the biggest error in the product is 1/2 epsilon in the
    product of the real parts and then another 1/2 epsilon when subtracting
    the product of the imaginary parts.  So the total error is about

    (* (+ 1/2 1/2 1/2 1/2) (expt 2 -53))

    or 2.220446049250313e-16.

    The final product adds further error of (sqrt 1/2) epsilon in the
    entries in the first table and then (sqrt 2) epsilon in the product.
    So my guess is that the total error in the product of three entries
    from the table will be bounded by

    (* (+ 1/2 1/2 1/2 1/2 (sqrt 1/2) (sqrt 2)) (expt 2 -53))

    or 4.575584737275976e-16.

    |#

    (define lut-table-size 512)
    (define lut-table-size^2 262144)
    (define lut-table-size^3 134217728)
    (define log-lut-table-size 9)

    (define low-lut
    '#f64(1. 0.
       .7071067811865476 .7071067811865476
       .9238795325112867 .3826834323650898
       .3826834323650898 .9238795325112867
       .9807852804032304 .19509032201612828
       .5555702330196022 .8314696123025452
       .8314696123025452 .5555702330196022
       .19509032201612828 .9807852804032304
       .9951847266721969 .0980171403295606
       .6343932841636455 .773010453362737
       .881921264348355 .47139673682599764
       .2902846772544624 .9569403357322088
       .9569403357322088 .2902846772544624
       .47139673682599764 .881921264348355
       .773010453362737 .6343932841636455
       .0980171403295606 .9951847266721969
       .9987954562051724 .049067674327418015
       .6715589548470184 .7409511253549591
       .9039892931234433 .4275550934302821
       .33688985339222005 .9415440651830208
       .970031253194544 .2429801799032639
       .5141027441932218 .8577286100002721
       .8032075314806449 .5956993044924334
       .14673047445536175 .989176509964781
       .989176509964781 .14673047445536175
       .5956993044924334 .8032075314806449
       .8577286100002721 .5141027441932218
       .2429801799032639 .970031253194544
       .9415440651830208 .33688985339222005
       .4275550934302821 .9039892931234433
       .7409511253549591 .6715589548470184
       .049067674327418015 .9987954562051724
       .9996988186962042 .024541228522912288
       .6895405447370669 .7242470829514669
       .9142097557035307 .40524131400498986
       .35989503653498817 .9329927988347388
       .9757021300385286 .2191012401568698
       .5349976198870973 .8448535652497071
       .8175848131515837 .5758081914178453
       .17096188876030122 .9852776423889412
       .99247953459871 .1224106751992162
       .6152315905806268 .7883464276266062
       .8700869911087115 .49289819222978404
       .26671275747489837 .9637760657954398
       .9495281805930367 .31368174039889146
       .4496113296546066 .8932243011955153
       .7572088465064846 .6531728429537768
       .07356456359966743 .9972904566786902
       .9972904566786902 .07356456359966743
       .6531728429537768 .7572088465064846
       .8932243011955153 .4496113296546066
       .31368174039889146 .9495281805930367
       .9637760657954398 .26671275747489837
       .49289819222978404 .8700869911087115
       .7883464276266062 .6152315905806268
       .1224106751992162 .99247953459871
       .9852776423889412 .17096188876030122
       .5758081914178453 .8175848131515837
       .8448535652497071 .5349976198870973
       .2191012401568698 .9757021300385286
       .9329927988347388 .35989503653498817
       .40524131400498986 .9142097557035307
       .7242470829514669 .6895405447370669
       .024541228522912288 .9996988186962042
       .9999247018391445 .012271538285719925
       .6983762494089728 .7157308252838187
       .9191138516900578 .3939920400610481
       .37131719395183754 .9285060804732156
       .9783173707196277 .20711137619221856
       .5453249884220465 .8382247055548381
       .8245893027850253 .5657318107836132
       .18303988795514095 .9831054874312163
       .9939069700023561 .11022220729388306
       .6248594881423863 .7807372285720945
       .8760700941954066 .4821837720791228
       .2785196893850531 .9604305194155658
       .9533060403541939 .3020059493192281
       .46053871095824 .8876396204028539
       .765167265622459 .6438315428897915
       .0857973123444399 .996312612182778
       .9981181129001492 .06132073630220858
       .6624157775901718 .7491363945234594
       .8986744656939538 .43861623853852766
       .3253102921622629 .9456073253805213
       .9669764710448521 .25486565960451457
       .5035383837257176 .8639728561215867
       .7958369046088836 .6055110414043255
       .1345807085071262 .99090263542778
       .9873014181578584 .15885814333386145
       .5857978574564389 .8104571982525948
       .8513551931052652 .524589682678469
       .2310581082806711 .9729399522055602
       .937339011912575 .34841868024943456
       .4164295600976372 .9091679830905224
       .7326542716724128 .680600997795453
       .03680722294135883 .9993223845883495
       .9993223845883495 .03680722294135883
       .680600997795453 .7326542716724128
       .9091679830905224 .4164295600976372
       .34841868024943456 .937339011912575
       .9729399522055602 .2310581082806711
       .524589682678469 .8513551931052652
       .8104571982525948 .5857978574564389
       .15885814333386145 .9873014181578584
       .99090263542778 .1345807085071262
       .6055110414043255 .7958369046088836
       .8639728561215867 .5035383837257176
       .25486565960451457 .9669764710448521
       .9456073253805213 .3253102921622629
       .43861623853852766 .8986744656939538
       .7491363945234594 .6624157775901718
       .06132073630220858 .9981181129001492
       .996312612182778 .0857973123444399
       .6438315428897915 .765167265622459
       .8876396204028539 .46053871095824
       .3020059493192281 .9533060403541939
       .9604305194155658 .2785196893850531
       .4821837720791228 .8760700941954066
       .7807372285720945 .6248594881423863
       .11022220729388306 .9939069700023561
       .9831054874312163 .18303988795514095
       .5657318107836132 .8245893027850253
       .8382247055548381 .5453249884220465
       .20711137619221856 .9783173707196277
       .9285060804732156 .37131719395183754
       .3939920400610481 .9191138516900578
       .7157308252838187 .6983762494089728
       .012271538285719925 .9999247018391445
       .9999811752826011 .006135884649154475
       .7027547444572253 .7114321957452164
       .9215140393420419 .3883450466988263
       .37700741021641826 .9262102421383114
       .9795697656854405 .2011046348420919
       .5504579729366048 .83486287498638
       .8280450452577558 .560661576197336
       .18906866414980622 .9819638691095552
       .9945645707342554 .10412163387205457
       .629638238914927 .7768884656732324
       .8790122264286335 .47679923006332214
       .2844075372112718 .9587034748958716
       .9551411683057707 .29615088824362384
       .4659764957679662 .8847970984309378
       .7691033376455796 .6391244448637757
       .09190895649713272 .9957674144676598
       .9984755805732948 .05519524434968994
       .6669999223036375 .745057785441466
       .901348847046022 .43309381885315196
       .33110630575987643 .9435934581619604
       .9685220942744173 .24892760574572018
       .508830142543107 .8608669386377673
       .799537269107905 .600616479383869
       .14065823933284924 .9900582102622971
       .9882575677307495 .15279718525844344
       .5907597018588743 .8068475535437992
       .8545579883654005 .5193559901655896
       .2370236059943672 .9715038909862518
       .9394592236021899 .3426607173119944
       .4220002707997997 .9065957045149153
       .7368165688773699 .6760927035753159
       .04293825693494082 .9990777277526454
       .9995294175010931 .030674803176636626
       .6850836677727004 .7284643904482252
       .9117060320054299 .41084317105790397
       .3541635254204904 .9351835099389476
       .9743393827855759 .22508391135979283
       .5298036246862947 .8481203448032972
       .8140363297059484 .5808139580957645
       .16491312048996992 .9863080972445987
       .9917097536690995 .12849811079379317
       .6103828062763095 .7921065773002124
       .8670462455156926 .49822766697278187
       .2607941179152755 .9653944416976894
       .9475855910177411 .3195020308160157
       .44412214457042926 .8959662497561851
       .7531867990436125 .6578066932970786
       .06744391956366406 .9977230666441916
       .9968202992911657 .07968243797143013
       .6485144010221124 .7612023854842618
       .8904487232447579 .45508358712634384
       .30784964004153487 .9514350209690083
       .9621214042690416 .272621355449949
       .48755016014843594 .8730949784182901
       .7845565971555752 .6200572117632892
       .11631863091190477 .9932119492347945
       .984210092386929 .17700422041214875
       .5707807458869673 .8211025149911046
       .8415549774368984 .5401714727298929
       .21311031991609136 .9770281426577544
       .9307669610789837 .36561299780477385
       .39962419984564684 .9166790599210427
       .7200025079613817 .693971460889654
       .01840672990580482 .9998305817958234
       .9998305817958234 .01840672990580482
       .693971460889654 .7200025079613817
       .9166790599210427 .39962419984564684
       .36561299780477385 .9307669610789837
       .9770281426577544 .21311031991609136
       .5401714727298929 .8415549774368984
       .8211025149911046 .5707807458869673
       .17700422041214875 .984210092386929
       .9932119492347945 .11631863091190477
       .6200572117632892 .7845565971555752
       .8730949784182901 .48755016014843594
       .272621355449949 .9621214042690416
       .9514350209690083 .30784964004153487
       .45508358712634384 .8904487232447579
       .7612023854842618 .6485144010221124
       .07968243797143013 .9968202992911657
       .9977230666441916 .06744391956366406
       .6578066932970786 .7531867990436125
       .8959662497561851 .44412214457042926
       .3195020308160157 .9475855910177411
       .9653944416976894 .2607941179152755
       .49822766697278187 .8670462455156926
       .7921065773002124 .6103828062763095
       .12849811079379317 .9917097536690995
       .9863080972445987 .16491312048996992
       .5808139580957645 .8140363297059484
       .8481203448032972 .5298036246862947
       .22508391135979283 .9743393827855759
       .9351835099389476 .3541635254204904
       .41084317105790397 .9117060320054299
       .7284643904482252 .6850836677727004
       .030674803176636626 .9995294175010931
       .9990777277526454 .04293825693494082
       .6760927035753159 .7368165688773699
       .9065957045149153 .4220002707997997
       .3426607173119944 .9394592236021899
       .9715038909862518 .2370236059943672
       .5193559901655896 .8545579883654005
       .8068475535437992 .5907597018588743
       .15279718525844344 .9882575677307495
       .9900582102622971 .14065823933284924
       .600616479383869 .799537269107905
       .8608669386377673 .508830142543107
       .24892760574572018 .9685220942744173
       .9435934581619604 .33110630575987643
       .43309381885315196 .901348847046022
       .745057785441466 .6669999223036375
       .05519524434968994 .9984755805732948
       .9957674144676598 .09190895649713272
       .6391244448637757 .7691033376455796
       .8847970984309378 .4659764957679662
       .29615088824362384 .9551411683057707
       .9587034748958716 .2844075372112718
       .47679923006332214 .8790122264286335
       .7768884656732324 .629638238914927
       .10412163387205457 .9945645707342554
       .9819638691095552 .18906866414980622
       .560661576197336 .8280450452577558
       .83486287498638 .5504579729366048
       .2011046348420919 .9795697656854405
       .9262102421383114 .37700741021641826
       .3883450466988263 .9215140393420419
       .7114321957452164 .7027547444572253
       .006135884649154475 .9999811752826011
       .9999952938095762 .003067956762965976
       .7049340803759049 .7092728264388657
       .9227011283338785 .38551605384391885
       .37984720892405116 .9250492407826776
       .9801821359681174 .1980984107179536
       .5530167055800276 .8331701647019132
       .829761233794523 .5581185312205561
       .19208039704989244 .9813791933137546
       .9948793307948056 .10106986275482782
       .6320187359398091 .7749531065948739
       .8804708890521608 .47410021465055
       .2873474595447295 .9578264130275329
       .9560452513499964 .29321916269425863
       .46868882203582796 .8833633386657316
       .7710605242618138 .6367618612362842
       .094963495329639 .9954807554919269
       .9986402181802653 .052131704680283324
       .6692825883466361 .7430079521351217
       .9026733182372588 .4303264813400826
       .3339996514420094 .9425731976014469
       .9692812353565485 .24595505033579462
       .5114688504379704 .8593018183570084
       .8013761717231402 .5981607069963423
       .14369503315029444 .9896220174632009
       .9887216919603238 .1497645346773215
       .5932322950397998 .8050313311429635
       .8561473283751945 .5167317990176499
       .2400030224487415 .9707721407289504
       .9405060705932683 .33977688440682685
       .4247796812091088 .9052967593181188
       .7388873244606151 .673829000378756
       .04600318213091463 .9989412931868569
       .9996188224951786 .027608145778965743
       .6873153408917592 .726359155084346
       .9129621904283982 .4080441628649787
       .35703096123343003 .9340925504042589
       .9750253450669941 .22209362097320354
       .532403127877198 .8464909387740521
       .8158144108067338 .5783137964116556
       .16793829497473117 .9857975091675675
       .9920993131421918 .12545498341154623
       .6128100824294097 .79023022143731
       .8685707059713409 .49556526182577254
       .2637546789748314 .9645897932898128
       .9485613499157303 .31659337555616585
       .4468688401623742 .8945994856313827
       .7552013768965365 .6554928529996153
       .07050457338961387 .9975114561403035
       .997060070339483 .07662386139203149
       .6508466849963809 .7592091889783881
       .8918407093923427 .4523495872337709
       .3107671527496115 .9504860739494817
       .9629532668736839 .2696683255729151
       .49022648328829116 .8715950866559511
       .7864552135990858 .617647307937804
       .11936521481099137 .9928504144598651
       .9847485018019042 .17398387338746382
       .5732971666980422 .819347520076797
       .8432082396418454 .5375870762956455
       .21610679707621952 .9763697313300211
       .9318842655816681 .3627557243673972
       .40243465085941843 .9154487160882678
       .7221281939292153 .6917592583641577
       .021474080275469508 .9997694053512153
       .9998823474542126 .015339206284988102
       .696177131491463 .7178700450557317
       .9179007756213905 .3968099874167103
       .3684668299533723 .9296408958431812
       .9776773578245099 .2101118368804696
       .5427507848645159 .8398937941959995
       .8228497813758263 .5682589526701316
       .18002290140569951 .9836624192117303
       .9935641355205953 .11327095217756435
       .62246127937415 .7826505961665757
       .8745866522781761 .4848692480007911
       .27557181931095814 .9612804858113206
       .9523750127197659 .30492922973540243
       .45781330359887723 .8890483558546646
       .7631884172633813 .6461760129833164
       .08274026454937569 .9965711457905548
       .997925286198596 .06438263092985747
       .6601143420674205 .7511651319096864
       .8973245807054183 .44137126873171667
       .32240767880106985 .9466009130832835
       .9661900034454125 .257831102162159
       .5008853826112408 .8655136240905691
       .7939754775543372 .6079497849677736
       .13154002870288312 .9913108598461154
       .9868094018141855 .16188639378011183
       .5833086529376983 .8122505865852039
       .8497417680008524 .5271991347819014
       .22807208317088573 .973644249650812
       .9362656671702783 .35129275608556715
       .41363831223843456 .9104412922580672
       .7305627692278276 .6828455463852481
       .03374117185137759 .9994306045554617
       .9992047586183639 .03987292758773981
       .6783500431298615 .7347388780959635
       .9078861164876663 .41921688836322396
       .34554132496398904 .9384035340631081
       .9722264970789363 .23404195858354343
       .5219752929371544 .8529606049303636
       .808656181588175 .5882815482226453
       .15582839765426523 .9877841416445722
       .9904850842564571 .13762012158648604
       .6030665985403482 .7976908409433912
       .8624239561110405 .5061866453451553
       .25189781815421697 .9677538370934755
       .9446048372614803 .32820984357909255
       .4358570799222555 .9000158920161603
       .7471006059801801 .6647109782033449
       .05825826450043576 .9983015449338929
       .996044700901252 .0888535525825246
       .6414810128085832 .7671389119358204
       .8862225301488806 .4632597835518602
       .2990798263080405 .9542280951091057
       .9595715130819845 .281464937925758
       .479493757660153 .8775452902072612
       .778816512381476 .6272518154951441
       .10717242495680884 .9942404494531879
       .9825393022874412 .18605515166344666
       .5631993440138341 .8263210628456635
       .836547727223512 .5478940591731002
       .20410896609281687 .9789481753190622
       .9273625256504011 .374164062971458
       .39117038430225387 .9203182767091106
       .7135848687807936 .7005687939432483
       .00920375478205982 .9999576445519639
       .9999576445519639 .00920375478205982
       .7005687939432483 .7135848687807936
       .9203182767091106 .39117038430225387
       .374164062971458 .9273625256504011
       .9789481753190622 .20410896609281687
       .5478940591731002 .836547727223512
       .8263210628456635 .5631993440138341
       .18605515166344666 .9825393022874412
       .9942404494531879 .10717242495680884
       .6272518154951441 .778816512381476
       .8775452902072612 .479493757660153
       .281464937925758 .9595715130819845
       .9542280951091057 .2990798263080405
       .4632597835518602 .8862225301488806
       .7671389119358204 .6414810128085832
       .0888535525825246 .996044700901252
       .9983015449338929 .05825826450043576
       .6647109782033449 .7471006059801801
       .9000158920161603 .4358570799222555
       .32820984357909255 .9446048372614803
       .9677538370934755 .25189781815421697
       .5061866453451553 .8624239561110405
       .7976908409433912 .6030665985403482
       .13762012158648604 .9904850842564571
       .9877841416445722 .15582839765426523
       .5882815482226453 .808656181588175
       .8529606049303636 .5219752929371544
       .23404195858354343 .9722264970789363
       .9384035340631081 .34554132496398904
       .41921688836322396 .9078861164876663
       .7347388780959635 .6783500431298615
       .03987292758773981 .9992047586183639
       .9994306045554617 .03374117185137759
       .6828455463852481 .7305627692278276
       .9104412922580672 .41363831223843456
       .35129275608556715 .9362656671702783
       .973644249650812 .22807208317088573
       .5271991347819014 .8497417680008524
       .8122505865852039 .5833086529376983
       .16188639378011183 .9868094018141855
       .9913108598461154 .13154002870288312
       .6079497849677736 .7939754775543372
       .8655136240905691 .5008853826112408
       .257831102162159 .9661900034454125
       .9466009130832835 .32240767880106985
       .44137126873171667 .8973245807054183
       .7511651319096864 .6601143420674205
       .06438263092985747 .997925286198596
       .9965711457905548 .08274026454937569
       .6461760129833164 .7631884172633813
       .8890483558546646 .45781330359887723
       .30492922973540243 .9523750127197659
       .9612804858113206 .27557181931095814
       .4848692480007911 .8745866522781761
       .7826505961665757 .62246127937415
       .11327095217756435 .9935641355205953
       .9836624192117303 .18002290140569951
       .5682589526701316 .8228497813758263
       .8398937941959995 .5427507848645159
       .2101118368804696 .9776773578245099
       .9296408958431812 .3684668299533723
       .3968099874167103 .9179007756213905
       .7178700450557317 .696177131491463
       .015339206284988102 .9998823474542126
       .9997694053512153 .021474080275469508
       .6917592583641577 .7221281939292153
       .9154487160882678 .40243465085941843
       .3627557243673972 .9318842655816681
       .9763697313300211 .21610679707621952
       .5375870762956455 .8432082396418454
       .819347520076797 .5732971666980422
       .17398387338746382 .9847485018019042
       .9928504144598651 .11936521481099137
       .617647307937804 .7864552135990858
       .8715950866559511 .49022648328829116
       .2696683255729151 .9629532668736839
       .9504860739494817 .3107671527496115
       .4523495872337709 .8918407093923427
       .7592091889783881 .6508466849963809
       .07662386139203149 .997060070339483
       .9975114561403035 .07050457338961387
       .6554928529996153 .7552013768965365
       .8945994856313827 .4468688401623742
       .31659337555616585 .9485613499157303
       .9645897932898128 .2637546789748314
       .49556526182577254 .8685707059713409
       .79023022143731 .6128100824294097
       .12545498341154623 .9920993131421918
       .9857975091675675 .16793829497473117
       .5783137964116556 .8158144108067338
       .8464909387740521 .532403127877198
       .22209362097320354 .9750253450669941
       .9340925504042589 .35703096123343003
       .4080441628649787 .9129621904283982
       .726359155084346 .6873153408917592
       .027608145778965743 .9996188224951786
       .9989412931868569 .04600318213091463
       .673829000378756 .7388873244606151
       .9052967593181188 .4247796812091088
       .33977688440682685 .9405060705932683
       .9707721407289504 .2400030224487415
       .5167317990176499 .8561473283751945
       .8050313311429635 .5932322950397998
       .1497645346773215 .9887216919603238
       .9896220174632009 .14369503315029444
       .5981607069963423 .8013761717231402
       .8593018183570084 .5114688504379704
       .24595505033579462 .9692812353565485
       .9425731976014469 .3339996514420094
       .4303264813400826 .9026733182372588
       .7430079521351217 .6692825883466361
       .052131704680283324 .9986402181802653
       .9954807554919269 .094963495329639
       .6367618612362842 .7710605242618138
       .8833633386657316 .46868882203582796
       .29321916269425863 .9560452513499964
       .9578264130275329 .2873474595447295
       .47410021465055 .8804708890521608
       .7749531065948739 .6320187359398091
       .10106986275482782 .9948793307948056
       .9813791933137546 .19208039704989244
       .5581185312205561 .829761233794523
       .8331701647019132 .5530167055800276
       .1980984107179536 .9801821359681174
       .9250492407826776 .37984720892405116
       .38551605384391885 .9227011283338785
       .7092728264388657 .7049340803759049
       .003067956762965976 .9999952938095762
       ))

    (define med-lut
    '#f64(1. 0.
       .9999999999820472 5.9921124526424275e-6
       .9999999999281892 1.1984224905069707e-5
       .9999999998384257 1.7976337357066685e-5
       .9999999997127567 2.396844980841822e-5
       .9999999995511824 2.9960562258909154e-5
       .9999999993537025 3.5952674708324344e-5
       .9999999991203175 4.1944787156448635e-5
       .9999999988510269 4.793689960306688e-5
       .9999999985458309 5.3929012047963936e-5
       .9999999982047294 5.992112449092465e-5
       .9999999978277226 6.591323693173387e-5
       .9999999974148104 7.190534937017645e-5
       .9999999969659927 7.789746180603723e-5
       .9999999964812697 8.388957423910108e-5
       .9999999959606412 8.988168666915283e-5
       .9999999954041073 9.587379909597734e-5
       .999999994811668 1.0186591151935948e-4
       .9999999941833233 1.0785802393908407e-4
       .9999999935190732 1.1385013635493597e-4
       .9999999928189177 1.1984224876670004e-4
       .9999999920828567 1.2583436117416112e-4
       .9999999913108903 1.3182647357710405e-4
       .9999999905030187 1.3781858597531374e-4
       .9999999896592414 1.4381069836857496e-4
       .9999999887795589 1.498028107566726e-4
       .9999999878639709 1.5579492313939151e-4
       .9999999869124775 1.6178703551651655e-4
       .9999999859250787 1.6777914788783258e-4
       .9999999849017744 1.737712602531244e-4
       .9999999838425648 1.797633726121769e-4
       .9999999827474497 1.8575548496477492e-4
       .9999999816164293 1.9174759731070332e-4
       .9999999804495034 1.9773970964974692e-4
       .9999999792466722 2.037318219816906e-4
       .9999999780079355 2.0972393430631923e-4
       .9999999767332933 2.1571604662341763e-4
       .9999999754227459 2.2170815893277063e-4
       .9999999740762929 2.2770027123416315e-4
       .9999999726939346 2.3369238352737996e-4
       .9999999712756709 2.3968449581220595e-4
       .9999999698215016 2.45676608088426e-4
       .9999999683314271 2.5166872035582493e-4
       .9999999668054471 2.5766083261418755e-4
       .9999999652435617 2.636529448632988e-4
       .9999999636457709 2.696450571029434e-4
       .9999999620120748 2.756371693329064e-4
       .9999999603424731 2.8162928155297243e-4
       .9999999586369661 2.876213937629265e-4
       .9999999568955537 2.936135059625534e-4
       .9999999551182358 2.99605618151638e-4
       .9999999533050126 3.055977303299651e-4
       .9999999514558838 3.115898424973196e-4
       .9999999495708498 3.1758195465348636e-4
       .9999999476499103 3.235740667982502e-4
       .9999999456930654 3.2956617893139595e-4
       .9999999437003151 3.3555829105270853e-4
       .9999999416716594 3.4155040316197275e-4
       .9999999396070982 3.475425152589734e-4
       .9999999375066316 3.535346273434955e-4
       .9999999353702598 3.595267394153237e-4
       .9999999331979824 3.6551885147424295e-4
       .9999999309897996 3.7151096352003814e-4
       .9999999287457114 3.7750307555249406e-4
       .9999999264657179 3.8349518757139556e-4
       .9999999241498189 3.8948729957652753e-4
       .9999999217980144 3.954794115676748e-4
       .9999999194103046 4.0147152354462224e-4
       .9999999169866894 4.0746363550715466e-4
       .9999999145271687 4.134557474550569e-4
       .9999999120317428 4.194478593881139e-4
       .9999999095004113 4.2543997130611036e-4
       .9999999069331744 4.314320832088313e-4
       .9999999043300322 4.3742419509606144e-4
       .9999999016909845 4.4341630696758576e-4
       .9999998990160315 4.4940841882318896e-4
       .9999998963051729 4.55400530662656e-4
       .999999893558409 4.613926424857717e-4
       .9999998907757398 4.673847542923209e-4
       .9999998879571651 4.7337686608208844e-4
       .9999998851026849 4.793689778548592e-4
       .9999998822122994 4.8536108961041806e-4
       .9999998792860085 4.913532013485497e-4
       .9999998763238122 4.973453130690393e-4
       .9999998733257104 5.033374247716714e-4
       .9999998702917032 5.09329536456231e-4
       .9999998672217907 5.153216481225028e-4
       .9999998641159727 5.213137597702719e-4
       .9999998609742493 5.27305871399323e-4
       .9999998577966206 5.332979830094408e-4
       .9999998545830864 5.392900946004105e-4
       .9999998513336468 5.452822061720168e-4
       .9999998480483018 5.512743177240444e-4
       .9999998447270514 5.572664292562783e-4
       .9999998413698955 5.632585407685033e-4
       .9999998379768343 5.692506522605043e-4
       .9999998345478677 5.752427637320661e-4
       .9999998310829956 5.812348751829735e-4
       .9999998275822183 5.872269866130116e-4
       .9999998240455354 5.93219098021965e-4
       .9999998204729471 5.992112094096185e-4
       .9999998168644535 6.052033207757572e-4
       .9999998132200545 6.111954321201659e-4
       .99999980953975 6.171875434426292e-4
       .9999998058235401 6.231796547429323e-4
       .9999998020714248 6.291717660208597e-4
       .9999997982834041 6.351638772761965e-4
       .9999997944594781 6.411559885087275e-4
       .9999997905996466 6.471480997182375e-4
       .9999997867039097 6.531402109045114e-4
       .9999997827722674 6.591323220673341e-4
       .9999997788047197 6.651244332064902e-4
       .9999997748012666 6.711165443217649e-4
       .9999997707619082 6.771086554129428e-4
       .9999997666866443 6.83100766479809e-4
       .9999997625754748 6.89092877522148e-4
       .9999997584284002 6.950849885397449e-4
       .9999997542454201 7.010770995323844e-4
       .9999997500265345 7.070692104998515e-4
       .9999997457717437 7.130613214419311e-4
       .9999997414810473 7.190534323584079e-4
       .9999997371544456 7.250455432490666e-4
       .9999997327919384 7.310376541136925e-4
       .9999997283935259 7.3702976495207e-4
       .999999723959208 7.430218757639842e-4
       .9999997194889846 7.490139865492199e-4
       .9999997149828559 7.55006097307562e-4
       .9999997104408218 7.609982080387952e-4
       .9999997058628822 7.669903187427045e-4
       .9999997012490373 7.729824294190747e-4
       .9999996965992869 7.789745400676906e-4
       .9999996919136313 7.849666506883372e-4
       .99999968719207 7.909587612807992e-4
       .9999996824346035 7.969508718448614e-4
       .9999996776412315 8.029429823803089e-4
       .9999996728119542 8.089350928869263e-4
       .9999996679467715 8.149272033644986e-4
       .9999996630456833 8.209193138128106e-4
       .9999996581086897 8.269114242316472e-4
       .9999996531357909 8.329035346207931e-4
       .9999996481269865 8.388956449800333e-4
       .9999996430822767 8.448877553091527e-4
       .9999996380016616 8.508798656079359e-4
       .999999632885141 8.56871975876168e-4
       .9999996277327151 8.628640861136338e-4
       .9999996225443838 8.68856196320118e-4
       .9999996173201471 8.748483064954056e-4
       .999999612060005 8.808404166392814e-4
       .9999996067639574 8.868325267515304e-4
       .9999996014320045 8.928246368319371e-4
       .9999995960641462 8.988167468802867e-4
       .9999995906603825 9.048088568963639e-4
       .9999995852207133 9.108009668799535e-4
       .9999995797451389 9.167930768308405e-4
       .9999995742336589 9.227851867488095e-4
       .9999995686862736 9.287772966336457e-4
       .9999995631029829 9.347694064851338e-4
       .9999995574837868 9.407615163030585e-4
       .9999995518286853 9.467536260872047e-4
       .9999995461376784 9.527457358373575e-4
       .9999995404107661 9.587378455533015e-4
       .9999995346479484 9.647299552348216e-4
       .9999995288492254 9.707220648817027e-4
       .9999995230145969 9.767141744937296e-4
       .9999995171440631 9.827062840706872e-4
       .9999995112376238 9.886983936123602e-4
       .9999995052952791 9.946905031185337e-4
       .9999994993170291 .0010006826125889925
       .9999994933028736 .0010066747220235214
       .9999994872528128 .001012666831421905
       .9999994811668466 .0010186589407839286
       .999999475044975 .0010246510501093766
       .9999994688871979 .0010306431593980344
       .9999994626935156 .0010366352686496862
       .9999994564639277 .0010426273778641173
       .9999994501984345 .0010486194870411127
       .999999443897036 .0010546115961804568
       .999999437559732 .0010606037052819344
       .9999994311865227 .0010665958143453308
       .9999994247774079 .0010725879233704307
       .9999994183323877 .0010785800323570187
       .9999994118514622 .0010845721413048801
       .9999994053346313 .0010905642502137994
       .9999993987818949 .0010965563590835613
       .9999993921932533 .0011025484679139511
       .9999993855687062 .0011085405767047535
       .9999993789082536 .0011145326854557532
       .9999993722118957 .001120524794166735
       .9999993654796325 .0011265169028374842
       .9999993587114638 .0011325090114677853
       .9999993519073898 .001138501120057423
       .9999993450674104 .0011444932286061825
       .9999993381915255 .0011504853371138485
       .9999993312797354 .0011564774455802057
       .9999993243320398 .0011624695540050393
       .9999993173484387 .001168461662388134
       .9999993103289324 .0011744537707292742
       .9999993032735206 .0011804458790282454
       .9999992961822035 .0011864379872848323
       .9999992890549809 .0011924300954988195
       .999999281891853 .001198422203669992
       .9999992746928197 .0012044143117981348
       .999999267457881 .0012104064198830327
       .999999260187037 .0012163985279244702
       .9999992528802875 .0012223906359222325
       .9999992455376326 .0012283827438761045
       .9999992381590724 .0012343748517858707
       .9999992307446068 .0012403669596513162
       .9999992232942359 .001246359067472226
       .9999992158079595 .0012523511752483847
       .9999992082857777 .001258343282979577
       .9999992007276906 .001264335390665588
       .999999193133698 .0012703274983062026
       .9999991855038001 .0012763196059012057
       .9999991778379967 .001282311713450382
       .9999991701362881 .0012883038209535163
       .999999162398674 .0012942959284103935
       .9999991546251547 .0013002880358207985
       .9999991468157298 .001306280143184516
       .9999991389703996 .001312272250501331
       .999999131089164 .0013182643577710285
       .999999123172023 .0013242564649933932
       .9999991152189767 .0013302485721682098
       .9999991072300249 .001336240679295263
       .9999990992051678 .0013422327863743383
       .9999990911444054 .0013482248934052201
       .9999990830477375 .0013542170003876934
       .9999990749151643 .001360209107321543
       .9999990667466857 .0013662012142065536
       .9999990585423016 .0013721933210425101
       .9999990503020123 .0013781854278291975
       .9999990420258176 .0013841775345664006
       .9999990337137175 .0013901696412539043
       .999999025365712 .0013961617478914935
       .999999016981801 .0014021538544789526
       .9999990085619848 .001408145961016067
       .9999990001062631 .0014141380675026214
       .9999989916146361 .0014201301739384005
       .9999989830871038 .0014261222803231893
       .9999989745236659 .0014321143866567725
       .9999989659243228 .001438106492938935
       .9999989572890743 .0014440985991694619
       .9999989486179204 .0014500907053481378
       .9999989399108612 .0014560828114747475
       .9999989311678965 .0014620749175490758
       .9999989223890265 .001468067023570908
       .9999989135742512 .0014740591295400284
       .9999989047235704 .0014800512354562223
       .9999988958369843 .0014860433413192743
       .9999988869144928 .0014920354471289693
       .9999988779560959 .0014980275528850922
       .9999988689617937 .0015040196585874275
       .9999988599315861 .0015100117642357607
       .999998850865473 .0015160038698298762
       .9999988417634548 .001521995975369559
       .999998832625531 .0015279880808545937
       .9999988234517019 .0015339801862847657
       .9999988142419675 .0015399722916598592
       .9999988049963277 .0015459643969796596
       .9999987957147825 .0015519565022439512
       .9999987863973319 .0015579486074525195
       .9999987770439759 .001563940712605149
       .9999987676547146 .0015699328177016243
       .999998758229548 .0015759249227417307
       .9999987487684759 .0015819170277252528
       .9999987392714985 .0015879091326519755
       .9999987297386157 .0015939012375216837
       .9999987201698276 .0015998933423341623
       .9999987105651341 .001605885447089196
       .9999987009245352 .0016118775517865696
       .999998691248031 .0016178696564260683
       .9999986815356214 .0016238617610074765
       .9999986717873064 .0016298538655305794
       .9999986620030861 .0016358459699951618
       .9999986521829605 .0016418380744010084
       .9999986423269294 .0016478301787479041
       .999998632434993 .0016538222830356339
       .9999986225071512 .0016598143872639823
       .999998612543404 .0016658064914327345
       .9999986025437515 .0016717985955416754
       .9999985925081937 .0016777906995905894
       .9999985824367305 .0016837828035792617
       .9999985723293618 .0016897749075074774
       .999998562186088 .0016957670113750207
       .9999985520069086 .0017017591151816769
       .9999985417918239 .0017077512189272307
       .999998531540834 .001713743322611467
       .9999985212539385 .0017197354262341706
       .9999985109311378 .0017257275297951264
       .9999985005724317 .0017317196332941192
       .9999984901778203 .0017377117367309341
       .9999984797473034 .0017437038401053556
       .9999984692808812 .0017496959434171687
       .9999984587785538 .0017556880466661582
       .9999984482403208 .001761680149852109
       .9999984376661826 .0017676722529748061
       .999998427056139 .0017736643560340342
       .99999841641019 .001779656459029578
       .9999984057283358 .0017856485619612225
       .9999983950105761 .0017916406648287528
       .999998384256911 .0017976327676319532
       .9999983734673407 .001803624870370609
       .9999983626418649 .0018096169730445048
       .9999983517804839 .0018156090756534257
       .9999983408831975 .0018216011781971562
       .9999983299500057 .0018275932806754815
       .9999983189809085 .0018335853830881864
       .999998307975906 .0018395774854350557
       .9999982969349982 .001845569587715874
       .9999982858581851 .0018515616899304264
       .9999982747454665 .001857553792078498
       .9999982635968426 .001863545894159873
       .9999982524123134 .0018695379961743367
       .9999982411918789 .001875530098121674
       .9999982299355389 .0018815222000016696
       .9999982186432936 .0018875143018141083
       .999998207315143 .0018935064035587748
       .999998195951087 .0018994985052354545
       .9999981845511257 .0019054906068439318
       .9999981731152591 .0019114827083839918
       .999998161643487 .001917474809855419
       .9999981501358096 .0019234669112579987
       .999998138592227 .0019294590125915154
       .9999981270127389 .0019354511138557542
       .9999981153973455 .0019414432150504997
       .9999981037460468 .0019474353161755369
       .9999980920588427 .001953427417230651
       .9999980803357332 .001959419518215626
       .9999980685767185 .0019654116191302473
       .9999980567817984 .0019714037199743
       .9999980449509729 .0019773958207475683
       .9999980330842422 .0019833879214498375
       .999998021181606 .001989380022080892
       .9999980092430646 .0019953721226405176
       .9999979972686177 .002001364223128498
       .9999979852582656 .002007356323544619
       .9999979732120081 .002013348423888665
       .9999979611298453 .002019340524160421
       .9999979490117771 .0020253326243596715
       .9999979368578036 .0020313247244862017
       .9999979246679247 .002037316824539796
       .9999979124421405 .00204330892452024
       .999997900180451 .002049301024427318
       .9999978878828562 .0020552931242608153
       .9999978755493559 .002061285224020516
       .9999978631799504 .0020672773237062057
       .9999978507746395 .002073269423317669
       .9999978383334234 .0020792615228546903
       .9999978258563018 .002085253622317055
       .999997813343275 .0020912457217045484
       .9999978007943428 .002097237821016954
       .9999977882095052 .0021032299202540577
       .9999977755887623 .0021092220194156444
       .9999977629321142 .0021152141185014984
       .9999977502395607 .0021212062175114043
       .9999977375111019 .002127198316445148
       .9999977247467376 .0021331904153025134
       .9999977119464681 .002139182514083286
       .9999976991102932 .0021451746127872503
       .9999976862382131 .002151166711414191
       .9999976733302276 .0021571588099638934
       .9999976603863368 .0021631509084361423
       .9999976474065406 .002169143006830722
       .9999976343908391 .002175135105147418
       .9999976213392323 .0021811272033860148
       .9999976082517201 .002187119301546297
       .9999975951283027 .00219311139962805
       .9999975819689799 .0021991034976310588
       .9999975687737518 .0022050955955551076
       .9999975555426184 .0022110876933999816
       .9999975422755796 .0022170797911654654
       .9999975289726355 .002223071888851344
       .9999975156337861 .0022290639864574026
       .9999975022590314 .0022350560839834253
       .9999974888483714 .002241048181429198
       .999997475401806 .0022470402787945045
       .9999974619193353 .00225303237607913
       .9999974484009593 .0022590244732828596
       .9999974348466779 .0022650165704054784
       .9999974212564913 .0022710086674467703
       .9999974076303992 .002277000764406521
       .9999973939684019 .002282992861284515
       .9999973802704993 .0022889849580805368
       .9999973665366915 .0022949770547943723
       .9999973527669782 .0023009691514258054
       .9999973389613596 .002306961247974621
       .9999973251198357 .0023129533444406045
       .9999973112424065 .0023189454408235406
       .999997297329072 .0023249375371232135
       .9999972833798322 .002330929633339409
       .999997269394687 .0023369217294719113
       .9999972553736366 .0023429138255205055
       .9999972413166809 .0023489059214849765
       .9999972272238198 .002354898017365109
       .9999972130950534 .0023608901131606883
       .9999971989303816 .0023668822088714985
       .9999971847298047 .0023728743044973246
       .9999971704933224 .0023788664000379523
       .9999971562209347 .0023848584954931653
       .9999971419126418 .0023908505908627493
       .9999971275684435 .0023968426861464883
       .99999711318834 .002402834781344168
       .9999970987723311 .0024088268764555732
       .9999970843204169 .002414818971480488
       .9999970698325974 .002420811066418698
       .9999970553088726 .0024268031612699878
       .9999970407492426 .002432795256034142
       .9999970261537071 .002438787350710946
       .9999970115222664 .002444779445300184
       .9999969968549204 .0024507715398016418
       .9999969821516691 .002456763634215103
       .9999969674125124 .002462755728540353
       .9999969526374506 .0024687478227771774
       .9999969378264834 .00247473991692536
       .9999969229796108 .002480732010984686
       .999996908096833 .0024867241049549406
       .9999968931781499 .002492716198835908
       .9999968782235614 .0024987082926273734
       .9999968632330677 .002504700386329122
       .9999968482066687 .002510692479940938
       .9999968331443644 .0025166845734626068
       .9999968180461547 .0025226766668939127
       .9999968029120399 .002528668760234641
       .9999967877420196 .002534660853484576
       .9999967725360941 .0025406529466435036
       .9999967572942633 .002546645039711208
       .9999967420165272 .002552637132687474
       .9999967267028858 .002558629225572086
       .9999967113533391 .0025646213183648297
       .9999966959678871 .0025706134110654896
       .9999966805465298 .002576605503673851
       .9999966650892672 .0025825975961896977
       .9999966495960994 .0025885896886128153
       .9999966340670262 .0025945817809429885
       .9999966185020478 .0026005738731800024
       .9999966029011641 .0026065659653236417
       .999996587264375 .002612558057373691
       .9999965715916808 .002618550149329935
       .9999965558830811 .0026245422411921592
       .9999965401385762 .002630534332960148
       .9999965243581661 .002636526424633687
       .9999965085418506 .0026425185162125596
       .9999964926896299 .0026485106076965517
       .9999964768015038 .0026545026990854484
       .9999964608774725 .0026604947903790337
       .9999964449175359 .0026664868815770926
       .999996428921694 .0026724789726794104
       .9999964128899468 .002678471063685772
       .9999963968222944 .0026844631545959617
       .9999963807187366 .002690455245409765
       .9999963645792737 .002696447336126966
       .9999963484039053 .00270243942674735
       .9999963321926317 .002708431517270702
       .9999963159454529 .0027144236076968066
       .9999962996623687 .0027204156980254485
       .9999962833433793 .002726407788256413
       .9999962669884847 .002732399878389485
       .9999962505976846 .0027383919684244484
       .9999962341709794 .002744384058361089
       .9999962177083689 .0027503761481991913
       .999996201209853 .0027563682379385403
       .9999961846754319 .0027623603275789207
       .9999961681051056 .0027683524171201175
       .999996151498874 .002774344506561915
       .9999961348567371 .002780336595904099
       .9999961181786949 .0027863286851464537
       .9999961014647475 .0027923207742887642
       .9999960847148948 .0027983128633308155
       .9999960679291368 .002804304952272392
       .9999960511074735 .002810297041113279
       .9999960342499049 .0028162891298532606
       .9999960173564312 .0028222812184921227
       .9999960004270521 .002828273307029649
       .9999959834617678 .002834265395465626
       .9999959664605781 .0028402574837998367
       .9999959494234832 .002846249572032067
       .9999959323504831 .0028522416601621014
       .9999959152415777 .002858233748189725
       .999995898096767 .002864225836114723
       .9999958809160512 .0028702179239368793
       .9999958636994299 .0028762100116559793
       .9999958464469034 .0028822020992718077
       .9999958291584717 .0028881941867841495
       .9999958118341348 .0028941862741927895
       .9999957944738925 .0029001783614975127
       .999995777077745 .002906170448698104
       .9999957596456922 .0029121625357943475
       .9999957421777342 .002918154622786029
       .999995724673871 .0029241467096729327
       .9999957071341024 .002930138796454844
       .9999956895584287 .0029361308831315474
       .9999956719468496 .0029421229697028273
       .9999956542993652 .0029481150561684695
       .9999956366159757 .0029541071425282584
       .9999956188966809 .002960099228781979
       .9999956011414808 .002966091314929416
       .9999955833503754 .002972083400970354
       .9999955655233649 .0029780754869045785
       .9999955476604491 .0029840675727318736
       .999995529761628 .002990059658452025
       .9999955118269016 .0029960517440648163
       .99999549385627 .0030020438295700336
       .9999954758497331 .0030080359149674612
       .999995457807291 .003014028000256884
       .9999954397289438 .003020020085438087
       .9999954216146911 .0030260121705108552
       .9999954034645333 .003032004255474973
       .9999953852784702 .003037996340330225
       .9999953670565019 .003043988425076397
       .9999953487986284 .003049980509713273
       .9999953305048496 .0030559725942406386
       .9999953121751655 .003061964678658278
       ))

    (define high-lut
    '#f64(1. 0.
       .9999999999999999 1.1703344634137277e-8
       .9999999999999998 2.3406689268274554e-8
       .9999999999999993 3.5110033902411824e-8
       .9999999999999989 4.6813378536549095e-8
       .9999999999999983 5.851672317068635e-8
       .9999999999999976 7.022006780482361e-8
       .9999999999999967 8.192341243896085e-8
       .9999999999999957 9.362675707309808e-8
       .9999999999999944 1.0533010170723531e-7
       .9999999999999931 1.170334463413725e-7
       .9999999999999917 1.287367909755097e-7
       .9999999999999901 1.4044013560964687e-7
       .9999999999999885 1.5214348024378403e-7
       .9999999999999866 1.6384682487792116e-7
       .9999999999999846 1.7555016951205827e-7
       .9999999999999825 1.8725351414619535e-7
       .9999999999999802 1.989568587803324e-7
       .9999999999999778 2.1066020341446942e-7
       .9999999999999752 2.2236354804860645e-7
       .9999999999999726 2.3406689268274342e-7
       .9999999999999698 2.4577023731688034e-7
       .9999999999999668 2.5747358195101726e-7
       .9999999999999638 2.6917692658515413e-7
       .9999999999999606 2.8088027121929094e-7
       .9999999999999571 2.9258361585342776e-7
       .9999999999999537 3.042869604875645e-7
       .99999999999995 3.159903051217012e-7
       .9999999999999463 3.276936497558379e-7
       .9999999999999424 3.3939699438997453e-7
       .9999999999999384 3.5110033902411114e-7
       .9999999999999342 3.6280368365824763e-7
       .9999999999999298 3.7450702829238413e-7
       .9999999999999254 3.8621037292652057e-7
       .9999999999999208 3.979137175606569e-7
       .9999999999999161 4.0961706219479325e-7
       .9999999999999113 4.2132040682892953e-7
       .9999999999999063 4.330237514630657e-7
       .9999999999999011 4.447270960972019e-7
       .9999999999998959 4.5643044073133796e-7
       .9999999999998904 4.68133785365474e-7
       .9999999999998849 4.7983712999961e-7
       .9999999999998792 4.915404746337459e-7
       .9999999999998733 5.032438192678817e-7
       .9999999999998674 5.149471639020175e-7
       .9999999999998613 5.266505085361531e-7
       .9999999999998551 5.383538531702888e-7
       .9999999999998487 5.500571978044243e-7
       .9999999999998422 5.617605424385598e-7
       .9999999999998356 5.734638870726952e-7
       .9999999999998288 5.851672317068305e-7
       .9999999999998219 5.968705763409657e-7
       .9999999999998148 6.085739209751009e-7
       .9999999999998076 6.202772656092359e-7
       .9999999999998003 6.319806102433709e-7
       .9999999999997928 6.436839548775058e-7
       .9999999999997853 6.553872995116406e-7
       .9999999999997775 6.670906441457753e-7
       .9999999999997696 6.7879398877991e-7
       .9999999999997616 6.904973334140445e-7
       .9999999999997534 7.02200678048179e-7
       .9999999999997452 7.139040226823132e-7
       .9999999999997368 7.256073673164475e-7
       .9999999999997282 7.373107119505817e-7
       .9999999999997194 7.490140565847157e-7
       .9999999999997107 7.607174012188497e-7
       .9999999999997017 7.724207458529835e-7
       .9999999999996926 7.841240904871172e-7
       .9999999999996834 7.958274351212508e-7
       .9999999999996739 8.075307797553844e-7
       .9999999999996644 8.192341243895178e-7
       .9999999999996547 8.309374690236511e-7
       .999999999999645 8.426408136577842e-7
       .9999999999996351 8.543441582919173e-7
       .999999999999625 8.660475029260503e-7
       .9999999999996148 8.777508475601831e-7
       .9999999999996044 8.894541921943158e-7
       .999999999999594 9.011575368284484e-7
       .9999999999995833 9.128608814625808e-7
       .9999999999995726 9.245642260967132e-7
       .9999999999995617 9.362675707308454e-7
       .9999999999995507 9.479709153649775e-7
       .9999999999995395 9.596742599991095e-7
       .9999999999995283 9.713776046332412e-7
       .9999999999995168 9.83080949267373e-7
       .9999999999995052 9.947842939015044e-7
       .9999999999994935 1.006487638535636e-6
       .9999999999994816 1.0181909831697673e-6
       .9999999999994696 1.0298943278038984e-6
       .9999999999994575 1.0415976724380293e-6
       .9999999999994453 1.0533010170721601e-6
       .9999999999994329 1.065004361706291e-6
       .9999999999994204 1.0767077063404215e-6
       .9999999999994077 1.088411050974552e-6
       .9999999999993949 1.1001143956086822e-6
       .9999999999993819 1.1118177402428122e-6
       .9999999999993688 1.1235210848769423e-6
       .9999999999993556 1.135224429511072e-6
       .9999999999993423 1.1469277741452017e-6
       .9999999999993288 1.1586311187793313e-6
       .9999999999993151 1.1703344634134605e-6
       .9999999999993014 1.1820378080475897e-6
       .9999999999992875 1.1937411526817187e-6
       .9999999999992735 1.2054444973158477e-6
       .9999999999992593 1.2171478419499764e-6
       .9999999999992449 1.2288511865841048e-6
       .9999999999992305 1.2405545312182331e-6
       .999999999999216 1.2522578758523615e-6
       .9999999999992012 1.2639612204864894e-6
       .9999999999991863 1.2756645651206173e-6
       .9999999999991713 1.287367909754745e-6
       .9999999999991562 1.2990712543888725e-6
       .9999999999991409 1.3107745990229998e-6
       .9999999999991255 1.3224779436571269e-6
       .9999999999991099 1.3341812882912537e-6
       .9999999999990943 1.3458846329253806e-6
       .9999999999990785 1.3575879775595072e-6
       .9999999999990625 1.3692913221936337e-6
       .9999999999990464 1.3809946668277597e-6
       .9999999999990302 1.3926980114618857e-6
       .9999999999990138 1.4044013560960117e-6
       .9999999999989974 1.4161047007301373e-6
       .9999999999989807 1.4278080453642627e-6
       .9999999999989639 1.439511389998388e-6
       .999999999998947 1.451214734632513e-6
       .99999999999893 1.462918079266638e-6
       .9999999999989128 1.4746214239007625e-6
       .9999999999988954 1.486324768534887e-6
       .999999999998878 1.4980281131690111e-6
       .9999999999988604 1.5097314578031353e-6
       .9999999999988426 1.5214348024372591e-6
       .9999999999988247 1.5331381470713828e-6
       .9999999999988067 1.544841491705506e-6
       .9999999999987886 1.5565448363396294e-6
       .9999999999987703 1.5682481809737524e-6
       .9999999999987519 1.579951525607875e-6
       .9999999999987333 1.5916548702419977e-6
       .9999999999987146 1.60335821487612e-6
       .9999999999986958 1.615061559510242e-6
       .9999999999986768 1.626764904144364e-6
       .9999999999986577 1.6384682487784858e-6
       .9999999999986384 1.6501715934126072e-6
       .9999999999986191 1.6618749380467283e-6
       .9999999999985996 1.6735782826808495e-6
       .9999999999985799 1.6852816273149702e-6
       .9999999999985602 1.6969849719490907e-6
       .9999999999985402 1.708688316583211e-6
       .9999999999985201 1.720391661217331e-6
       .9999999999985 1.732095005851451e-6
       .9999999999984795 1.7437983504855706e-6
       .9999999999984591 1.7555016951196899e-6
       .9999999999984385 1.767205039753809e-6
       .9999999999984177 1.778908384387928e-6
       .9999999999983968 1.7906117290220465e-6
       .9999999999983759 1.802315073656165e-6
       .9999999999983546 1.814018418290283e-6
       .9999999999983333 1.825721762924401e-6
       .9999999999983119 1.8374251075585186e-6
       .9999999999982904 1.8491284521926361e-6
       .9999999999982686 1.8608317968267533e-6
       .9999999999982468 1.8725351414608702e-6
       .9999999999982249 1.8842384860949866e-6
       .9999999999982027 1.8959418307291031e-6
       .9999999999981805 1.9076451753632194e-6
       .999999999998158 1.919348519997335e-6
       .9999999999981355 1.9310518646314507e-6
       .9999999999981128 1.942755209265566e-6
       .9999999999980901 1.954458553899681e-6
       .9999999999980671 1.966161898533796e-6
       .999999999998044 1.9778652431679103e-6
       .9999999999980208 1.9895685878020246e-6
       .9999999999979975 2.0012719324361386e-6
       .999999999997974 2.012975277070252e-6
       .9999999999979503 2.0246786217043656e-6
       .9999999999979265 2.0363819663384787e-6
       .9999999999979027 2.048085310972592e-6
       .9999999999978786 2.0597886556067045e-6
       .9999999999978545 2.0714920002408167e-6
       .9999999999978302 2.0831953448749286e-6
       .9999999999978058 2.0948986895090404e-6
       .9999999999977811 2.106602034143152e-6
       .9999999999977564 2.118305378777263e-6
       .9999999999977315 2.1300087234113738e-6
       .9999999999977065 2.1417120680454843e-6
       .9999999999976814 2.153415412679595e-6
       .9999999999976561 2.1651187573137046e-6
       .9999999999976307 2.1768221019478143e-6
       .9999999999976051 2.188525446581924e-6
       .9999999999975795 2.200228791216033e-6
       .9999999999975536 2.2119321358501417e-6
       .9999999999975278 2.22363548048425e-6
       .9999999999975017 2.2353388251183586e-6
       .9999999999974754 2.247042169752466e-6
       .999999999997449 2.2587455143865738e-6
       .9999999999974225 2.2704488590206814e-6
       .9999999999973959 2.282152203654788e-6
       .9999999999973691 2.293855548288895e-6
       .9999999999973422 2.305558892923001e-6
       .9999999999973151 2.317262237557107e-6
       .999999999997288 2.328965582191213e-6
       .9999999999972606 2.340668926825318e-6
       .9999999999972332 2.352372271459423e-6
       .9999999999972056 2.364075616093528e-6
       .9999999999971778 2.3757789607276323e-6
       .99999999999715 2.3874823053617365e-6
       .999999999997122 2.3991856499958403e-6
       .9999999999970938 2.4108889946299437e-6
       .9999999999970656 2.4225923392640466e-6
       .9999999999970371 2.4342956838981495e-6
       .9999999999970085 2.445999028532252e-6
       .9999999999969799 2.457702373166354e-6
       .999999999996951 2.4694057178004558e-6
       .999999999996922 2.4811090624345574e-6
       .9999999999968929 2.4928124070686583e-6
       .9999999999968637 2.504515751702759e-6
       .9999999999968343 2.5162190963368595e-6
       .9999999999968048 2.5279224409709594e-6
       .9999999999967751 2.5396257856050594e-6
       .9999999999967454 2.5513291302391585e-6
       .9999999999967154 2.5630324748732576e-6
       .9999999999966853 2.5747358195073563e-6
       .9999999999966551 2.5864391641414546e-6
       .9999999999966248 2.5981425087755525e-6
       .9999999999965944 2.6098458534096503e-6
       .9999999999965637 2.6215491980437473e-6
       .999999999996533 2.6332525426778443e-6
       .9999999999965021 2.644955887311941e-6
       .999999999996471 2.656659231946037e-6
       .99999999999644 2.6683625765801328e-6
       .9999999999964087 2.680065921214228e-6
       .9999999999963772 2.6917692658483234e-6
       .9999999999963456 2.703472610482418e-6
       .999999999996314 2.7151759551165123e-6
       .9999999999962821 2.7268792997506064e-6
       .9999999999962501 2.7385826443846996e-6
       .9999999999962179 2.750285989018793e-6
       .9999999999961857 2.761989333652886e-6
       .9999999999961533 2.7736926782869783e-6
       .9999999999961208 2.78539602292107e-6
       .9999999999960881 2.797099367555162e-6
       .9999999999960553 2.808802712189253e-6
       .9999999999960224 2.8205060568233443e-6
       .9999999999959893 2.832209401457435e-6
       .9999999999959561 2.8439127460915247e-6
       .9999999999959227 2.8556160907256145e-6
       .9999999999958893 2.867319435359704e-6
       .9999999999958556 2.879022779993793e-6
       .9999999999958219 2.8907261246278814e-6
       .9999999999957879 2.90242946926197e-6
       .999999999995754 2.9141328138960576e-6
       .9999999999957198 2.925836158530145e-6
       .9999999999956855 2.9375395031642317e-6
       .999999999995651 2.9492428477983186e-6
       .9999999999956164 2.9609461924324046e-6
       .9999999999955816 2.9726495370664905e-6
       .9999999999955468 2.9843528817005757e-6
       .9999999999955118 2.996056226334661e-6
       .9999999999954767 3.007759570968745e-6
       .9999999999954414 3.0194629156028294e-6
       .999999999995406 3.0311662602369133e-6
       .9999999999953705 3.0428696048709963e-6
       .9999999999953348 3.0545729495050794e-6
       .999999999995299 3.066276294139162e-6
       .999999999995263 3.0779796387732437e-6
       .9999999999952269 3.0896829834073255e-6
       .9999999999951907 3.101386328041407e-6
       .9999999999951543 3.1130896726754873e-6
       .9999999999951178 3.1247930173095678e-6
       .9999999999950812 3.136496361943648e-6
       .9999999999950444 3.148199706577727e-6
       .9999999999950075 3.1599030512118063e-6
       .9999999999949705 3.171606395845885e-6
       .9999999999949333 3.183309740479963e-6
       .999999999994896 3.195013085114041e-6
       .9999999999948584 3.206716429748118e-6
       .9999999999948209 3.218419774382195e-6
       .9999999999947832 3.2301231190162714e-6
       .9999999999947453 3.2418264636503477e-6
       .9999999999947072 3.253529808284423e-6
       .9999999999946692 3.265233152918498e-6
       .9999999999946309 3.276936497552573e-6
       .9999999999945924 3.288639842186647e-6
       .9999999999945539 3.300343186820721e-6
       .9999999999945152 3.312046531454794e-6
       .9999999999944763 3.323749876088867e-6
       .9999999999944373 3.3354532207229395e-6
       .9999999999943983 3.3471565653570115e-6
       .9999999999943591 3.358859909991083e-6
       .9999999999943197 3.370563254625154e-6
       .9999999999942801 3.3822665992592245e-6
       .9999999999942405 3.3939699438932944e-6
       .9999999999942008 3.4056732885273643e-6
       .9999999999941608 3.4173766331614334e-6
       .9999999999941207 3.429079977795502e-6
       .9999999999940805 3.4407833224295702e-6
       .9999999999940402 3.452486667063638e-6
       .9999999999939997 3.4641900116977054e-6
       .999999999993959 3.4758933563317723e-6
       .9999999999939183 3.4875967009658384e-6
       .9999999999938775 3.4993000455999045e-6
       .9999999999938364 3.5110033902339697e-6
       .9999999999937953 3.5227067348680345e-6
       .999999999993754 3.534410079502099e-6
       .9999999999937126 3.546113424136163e-6
       .999999999993671 3.5578167687702264e-6
       .9999999999936293 3.5695201134042896e-6
       .9999999999935875 3.581223458038352e-6
       .9999999999935454 3.592926802672414e-6
       .9999999999935033 3.6046301473064755e-6
       .9999999999934611 3.6163334919405365e-6
       .9999999999934187 3.628036836574597e-6
       .9999999999933762 3.639740181208657e-6
       .9999999999933334 3.6514435258427166e-6
       .9999999999932907 3.6631468704767755e-6
       .9999999999932477 3.674850215110834e-6
       .9999999999932047 3.686553559744892e-6
       .9999999999931615 3.6982569043789496e-6
       .9999999999931181 3.7099602490130064e-6
       .9999999999930747 3.7216635936470627e-6
       .999999999993031 3.733366938281119e-6
       .9999999999929873 3.745070282915174e-6
       .9999999999929433 3.756773627549229e-6
       .9999999999928992 3.768476972183284e-6
       .9999999999928552 3.7801803168173377e-6
       .9999999999928109 3.791883661451391e-6
       .9999999999927663 3.803587006085444e-6
       .9999999999927218 3.8152903507194965e-6
       .9999999999926771 3.826993695353548e-6
       .9999999999926322 3.838697039987599e-6
       .9999999999925873 3.85040038462165e-6
       .9999999999925421 3.862103729255701e-6
       .9999999999924968 3.87380707388975e-6
       .9999999999924514 3.885510418523799e-6
       .9999999999924059 3.897213763157848e-6
       .9999999999923602 3.9089171077918965e-6
       .9999999999923144 3.9206204524259435e-6
       .9999999999922684 3.9323237970599905e-6
       .9999999999922223 3.9440271416940376e-6
       .9999999999921761 3.955730486328084e-6
       .9999999999921297 3.967433830962129e-6
       .9999999999920832 3.9791371755961736e-6
       .9999999999920366 3.990840520230218e-6
       .9999999999919899 4.002543864864262e-6
       .9999999999919429 4.014247209498305e-6
       .9999999999918958 4.025950554132348e-6
       .9999999999918486 4.03765389876639e-6
       .9999999999918013 4.049357243400431e-6
       .9999999999917539 4.061060588034472e-6
       .9999999999917063 4.072763932668513e-6
       .9999999999916586 4.084467277302553e-6
       .9999999999916107 4.096170621936592e-6
       .9999999999915626 4.107873966570632e-6
       .9999999999915146 4.119577311204669e-6
       .9999999999914663 4.131280655838707e-6
       .9999999999914179 4.142984000472745e-6
       .9999999999913692 4.154687345106781e-6
       .9999999999913206 4.166390689740817e-6
       .9999999999912718 4.178094034374852e-6
       .9999999999912228 4.189797379008887e-6
       .9999999999911737 4.201500723642921e-6
       .9999999999911244 4.213204068276955e-6
       .999999999991075 4.224907412910988e-6
       .9999999999910255 4.236610757545021e-6
       .9999999999909759 4.248314102179053e-6
       .9999999999909261 4.260017446813084e-6
       .9999999999908762 4.271720791447115e-6
       .9999999999908261 4.283424136081145e-6
       .9999999999907759 4.295127480715175e-6
       .9999999999907256 4.306830825349204e-6
       .9999999999906751 4.3185341699832325e-6
       .9999999999906245 4.33023751461726e-6
       .9999999999905738 4.3419408592512875e-6
       .9999999999905229 4.353644203885314e-6
       .9999999999904718 4.36534754851934e-6
       .9999999999904207 4.377050893153365e-6
       .9999999999903694 4.38875423778739e-6
       .999999999990318 4.400457582421414e-6
       .9999999999902665 4.4121609270554384e-6
       .9999999999902147 4.423864271689461e-6
       .9999999999901629 4.435567616323483e-6
       .9999999999901109 4.447270960957506e-6
       .9999999999900587 4.458974305591527e-6
       .9999999999900065 4.470677650225547e-6
       .9999999999899541 4.482380994859567e-6
       .9999999999899016 4.494084339493587e-6
       .9999999999898489 4.5057876841276054e-6
       .9999999999897962 4.517491028761624e-6
       .9999999999897432 4.529194373395641e-6
       .9999999999896901 4.5408977180296584e-6
       .999999999989637 4.552601062663675e-6
       .9999999999895836 4.564304407297691e-6
       .99999999998953 4.5760077519317055e-6
       .9999999999894764 4.5877110965657195e-6
       .9999999999894227 4.5994144411997335e-6
       .9999999999893688 4.611117785833747e-6
       .9999999999893148 4.622821130467759e-6
       .9999999999892606 4.634524475101771e-6
       .9999999999892063 4.646227819735783e-6
       .9999999999891518 4.657931164369793e-6
       .9999999999890973 4.669634509003803e-6
       .9999999999890425 4.681337853637813e-6
       .9999999999889877 4.693041198271821e-6
       .9999999999889327 4.704744542905829e-6
       .9999999999888776 4.716447887539837e-6
       .9999999999888223 4.728151232173843e-6
       .9999999999887669 4.73985457680785e-6
       .9999999999887114 4.751557921441855e-6
       .9999999999886556 4.76326126607586e-6
       .9999999999885999 4.774964610709864e-6
       .9999999999885439 4.786667955343868e-6
       .9999999999884878 4.798371299977871e-6
       .9999999999884316 4.810074644611873e-6
       .9999999999883752 4.821777989245874e-6
       .9999999999883187 4.833481333879875e-6
       .9999999999882621 4.845184678513876e-6
       .9999999999882053 4.856888023147875e-6
       .9999999999881484 4.868591367781874e-6
       .9999999999880914 4.880294712415872e-6
       .9999999999880341 4.89199805704987e-6
       .9999999999879768 4.903701401683867e-6
       .9999999999879194 4.915404746317863e-6
       .9999999999878618 4.9271080909518585e-6
       .9999999999878041 4.938811435585853e-6
       .9999999999877462 4.9505147802198475e-6
       .9999999999876882 4.962218124853841e-6
       .99999999998763 4.973921469487834e-6
       .9999999999875717 4.985624814121826e-6
       .9999999999875133 4.997328158755817e-6
       .9999999999874548 5.009031503389808e-6
       .9999999999873961 5.0207348480237985e-6
       .9999999999873372 5.032438192657788e-6
       .9999999999872783 5.0441415372917765e-6
       .9999999999872192 5.055844881925764e-6
       .9999999999871599 5.067548226559752e-6
       .9999999999871007 5.079251571193739e-6
       .9999999999870411 5.090954915827725e-6
       .9999999999869814 5.10265826046171e-6
       .9999999999869217 5.1143616050956945e-6
       .9999999999868617 5.126064949729678e-6
       .9999999999868017 5.1377682943636615e-6
       .9999999999867415 5.149471638997644e-6
       .9999999999866811 5.161174983631626e-6
       .9999999999866207 5.172878328265607e-6
       .9999999999865601 5.184581672899587e-6
       .9999999999864994 5.196285017533567e-6
       .9999999999864384 5.2079883621675455e-6
       .9999999999863775 5.219691706801524e-6
       .9999999999863163 5.2313950514355015e-6
       .999999999986255 5.243098396069478e-6
       .9999999999861935 5.254801740703454e-6
       .999999999986132 5.266505085337429e-6
       .9999999999860703 5.278208429971404e-6
       .9999999999860084 5.289911774605378e-6
       .9999999999859465 5.301615119239351e-6
       .9999999999858843 5.313318463873323e-6
       .9999999999858221 5.325021808507295e-6
       .9999999999857597 5.336725153141267e-6
       .9999999999856971 5.3484284977752366e-6
       .9999999999856345 5.360131842409206e-6
       .9999999999855717 5.371835187043175e-6
       .9999999999855087 5.383538531677143e-6
       .9999999999854456 5.3952418763111104e-6
       .9999999999853825 5.406945220945077e-6
       .9999999999853191 5.418648565579043e-6
       .9999999999852557 5.4303519102130076e-6
       .9999999999851921 5.4420552548469724e-6
       .9999999999851282 5.453758599480936e-6
       .9999999999850644 5.465461944114899e-6
       .9999999999850003 5.47716528874886e-6
       .9999999999849362 5.488868633382822e-6
       .9999999999848719 5.500571978016782e-6
       .9999999999848074 5.512275322650742e-6
       .9999999999847429 5.523978667284702e-6
       .9999999999846781 5.53568201191866e-6
       .9999999999846133 5.547385356552617e-6
       .9999999999845482 5.5590887011865745e-6
       .9999999999844832 5.57079204582053e-6
       .9999999999844179 5.582495390454486e-6
       .9999999999843525 5.59419873508844e-6
       .9999999999842869 5.605902079722394e-6
       .9999999999842213 5.617605424356347e-6
       .9999999999841555 5.629308768990299e-6
       .9999999999840895 5.641012113624251e-6
       .9999999999840234 5.652715458258201e-6
       .9999999999839572 5.664418802892152e-6
       .9999999999838908 5.6761221475261e-6
       .9999999999838243 5.687825492160048e-6
       .9999999999837577 5.699528836793996e-6
       .9999999999836909 5.711232181427943e-6
       .999999999983624 5.722935526061889e-6
       .9999999999835569 5.734638870695834e-6
       .9999999999834898 5.746342215329779e-6
       .9999999999834225 5.758045559963722e-6
       .999999999983355 5.769748904597665e-6
       .9999999999832874 5.781452249231607e-6
       .9999999999832196 5.793155593865548e-6
       .9999999999831518 5.804858938499489e-6
       .9999999999830838 5.816562283133429e-6
       .9999999999830157 5.8282656277673675e-6
       .9999999999829474 5.839968972401306e-6
       .9999999999828789 5.851672317035243e-6
       .9999999999828104 5.86337566166918e-6
       .9999999999827417 5.875079006303115e-6
       .9999999999826729 5.88678235093705e-6
       .9999999999826039 5.898485695570985e-6
       .9999999999825349 5.910189040204917e-6
       .9999999999824656 5.92189238483885e-6
       .9999999999823962 5.933595729472782e-6
       .9999999999823267 5.945299074106713e-6
       .9999999999822571 5.957002418740643e-6
       .9999999999821872 5.9687057633745715e-6
       .9999999999821173 5.9804091080085e-6
       ))

    (define low-lut-rac
    '#f64(1. 0.
       .9999952938095762 .003067956762965976
       .9999811752826011 .006135884649154475
       .9999576445519639 .00920375478205982
       .9999247018391445 .012271538285719925
       .9998823474542126 .015339206284988102
       .9998305817958234 .01840672990580482
       .9997694053512153 .021474080275469508
       .9996988186962042 .024541228522912288
       .9996188224951786 .027608145778965743
       .9995294175010931 .030674803176636626
       .9994306045554617 .03374117185137759
       .9993223845883495 .03680722294135883
       .9992047586183639 .03987292758773981
       .9990777277526454 .04293825693494082
       .9989412931868569 .04600318213091463
       .9987954562051724 .049067674327418015
       .9986402181802653 .052131704680283324
       .9984755805732948 .05519524434968994
       .9983015449338929 .05825826450043576
       .9981181129001492 .06132073630220858
       .997925286198596 .06438263092985747
       .9977230666441916 .06744391956366406
       .9975114561403035 .07050457338961387
       .9972904566786902 .07356456359966743
       .997060070339483 .07662386139203149
       .9968202992911657 .07968243797143013
       .9965711457905548 .08274026454937569
       .996312612182778 .0857973123444399
       .996044700901252 .0888535525825246
       .9957674144676598 .09190895649713272
       .9954807554919269 .094963495329639
       .9951847266721969 .0980171403295606
       .9948793307948056 .10106986275482782
       .9945645707342554 .10412163387205457
       .9942404494531879 .10717242495680884
       .9939069700023561 .11022220729388306
       .9935641355205953 .11327095217756435
       .9932119492347945 .11631863091190477
       .9928504144598651 .11936521481099137
       .99247953459871 .1224106751992162
       .9920993131421918 .12545498341154623
       .9917097536690995 .12849811079379317
       .9913108598461154 .13154002870288312
       .99090263542778 .1345807085071262
       .9904850842564571 .13762012158648604
       .9900582102622971 .14065823933284924
       .9896220174632009 .14369503315029444
       .989176509964781 .14673047445536175
       .9887216919603238 .1497645346773215
       .9882575677307495 .15279718525844344
       .9877841416445722 .15582839765426523
       .9873014181578584 .15885814333386145
       .9868094018141855 .16188639378011183
       .9863080972445987 .16491312048996992
       .9857975091675675 .16793829497473117
       .9852776423889412 .17096188876030122
       .9847485018019042 .17398387338746382
       .984210092386929 .17700422041214875
       .9836624192117303 .18002290140569951
       .9831054874312163 .18303988795514095
       .9825393022874412 .18605515166344666
       .9819638691095552 .18906866414980622
       .9813791933137546 .19208039704989244
       .9807852804032304 .19509032201612828
       .9801821359681174 .1980984107179536
       .9795697656854405 .2011046348420919
       .9789481753190622 .20410896609281687
       .9783173707196277 .20711137619221856
       .9776773578245099 .2101118368804696
       .9770281426577544 .21311031991609136
       .9763697313300211 .21610679707621952
       .9757021300385286 .2191012401568698
       .9750253450669941 .22209362097320354
       .9743393827855759 .22508391135979283
       .973644249650812 .22807208317088573
       .9729399522055602 .2310581082806711
       .9722264970789363 .23404195858354343
       .9715038909862518 .2370236059943672
       .9707721407289504 .2400030224487415
       .970031253194544 .2429801799032639
       .9692812353565485 .24595505033579462
       .9685220942744173 .24892760574572018
       .9677538370934755 .25189781815421697
       .9669764710448521 .25486565960451457
       .9661900034454125 .257831102162159
       .9653944416976894 .2607941179152755
       .9645897932898128 .2637546789748314
       .9637760657954398 .26671275747489837
       .9629532668736839 .2696683255729151
       .9621214042690416 .272621355449949
       .9612804858113206 .27557181931095814
       .9604305194155658 .2785196893850531
       .9595715130819845 .281464937925758
       .9587034748958716 .2844075372112718
       .9578264130275329 .2873474595447295
       .9569403357322088 .2902846772544624
       .9560452513499964 .29321916269425863
       .9551411683057707 .29615088824362384
       .9542280951091057 .2990798263080405
       .9533060403541939 .3020059493192281
       .9523750127197659 .30492922973540243
       .9514350209690083 .30784964004153487
       .9504860739494817 .3107671527496115
       .9495281805930367 .31368174039889146
       .9485613499157303 .31659337555616585
       .9475855910177411 .3195020308160157
       .9466009130832835 .32240767880106985
       .9456073253805213 .3253102921622629
       .9446048372614803 .32820984357909255
       .9435934581619604 .33110630575987643
       .9425731976014469 .3339996514420094
       .9415440651830208 .33688985339222005
       .9405060705932683 .33977688440682685
       .9394592236021899 .3426607173119944
       .9384035340631081 .34554132496398904
       .937339011912575 .34841868024943456
       .9362656671702783 .35129275608556715
       .9351835099389476 .3541635254204904
       .9340925504042589 .35703096123343003
       .9329927988347388 .35989503653498817
       .9318842655816681 .3627557243673972
       .9307669610789837 .36561299780477385
       .9296408958431812 .3684668299533723
       .9285060804732156 .37131719395183754
       .9273625256504011 .374164062971458
       .9262102421383114 .37700741021641826
       .9250492407826776 .37984720892405116
       .9238795325112867 .3826834323650898
       .9227011283338785 .38551605384391885
       .9215140393420419 .3883450466988263
       .9203182767091106 .39117038430225387
       .9191138516900578 .3939920400610481
       .9179007756213905 .3968099874167103
       .9166790599210427 .39962419984564684
       .9154487160882678 .40243465085941843
       .9142097557035307 .40524131400498986
       .9129621904283982 .4080441628649787
       .9117060320054299 .41084317105790397
       .9104412922580672 .41363831223843456
       .9091679830905224 .4164295600976372
       .9078861164876663 .41921688836322396
       .9065957045149153 .4220002707997997
       .9052967593181188 .4247796812091088
       .9039892931234433 .4275550934302821
       .9026733182372588 .4303264813400826
       .901348847046022 .43309381885315196
       .9000158920161603 .4358570799222555
       .8986744656939538 .43861623853852766
       .8973245807054183 .44137126873171667
       .8959662497561851 .44412214457042926
       .8945994856313827 .4468688401623742
       .8932243011955153 .4496113296546066
       .8918407093923427 .4523495872337709
       .8904487232447579 .45508358712634384
       .8890483558546646 .45781330359887723
       .8876396204028539 .46053871095824
       .8862225301488806 .4632597835518602
       .8847970984309378 .4659764957679662
       .8833633386657316 .46868882203582796
       .881921264348355 .47139673682599764
       .8804708890521608 .47410021465055
       .8790122264286335 .47679923006332214
       .8775452902072612 .479493757660153
       .8760700941954066 .4821837720791228
       .8745866522781761 .4848692480007911
       .8730949784182901 .48755016014843594
       .8715950866559511 .49022648328829116
       .8700869911087115 .49289819222978404
       .8685707059713409 .49556526182577254
       .8670462455156926 .49822766697278187
       .8655136240905691 .5008853826112408
       .8639728561215867 .5035383837257176
       .8624239561110405 .5061866453451553
       .8608669386377673 .508830142543107
       .8593018183570084 .5114688504379704
       .8577286100002721 .5141027441932218
       .8561473283751945 .5167317990176499
       .8545579883654005 .5193559901655896
       .8529606049303636 .5219752929371544
       .8513551931052652 .524589682678469
       .8497417680008524 .5271991347819014
       .8481203448032972 .5298036246862947
       .8464909387740521 .532403127877198
       .8448535652497071 .5349976198870973
       .8432082396418454 .5375870762956455
       .8415549774368984 .5401714727298929
       .8398937941959995 .5427507848645159
       .8382247055548381 .5453249884220465
       .836547727223512 .5478940591731002
       .83486287498638 .5504579729366048
       .8331701647019132 .5530167055800276
       .8314696123025452 .5555702330196022
       .829761233794523 .5581185312205561
       .8280450452577558 .560661576197336
       .8263210628456635 .5631993440138341
       .8245893027850253 .5657318107836132
       .8228497813758263 .5682589526701316
       .8211025149911046 .5707807458869673
       .819347520076797 .5732971666980422
       .8175848131515837 .5758081914178453
       .8158144108067338 .5783137964116556
       .8140363297059484 .5808139580957645
       .8122505865852039 .5833086529376983
       .8104571982525948 .5857978574564389
       .808656181588175 .5882815482226453
       .8068475535437992 .5907597018588743
       .8050313311429635 .5932322950397998
       .8032075314806449 .5956993044924334
       .8013761717231402 .5981607069963423
       .799537269107905 .600616479383869
       .7976908409433912 .6030665985403482
       .7958369046088836 .6055110414043255
       .7939754775543372 .6079497849677736
       .7921065773002124 .6103828062763095
       .79023022143731 .6128100824294097
       .7883464276266062 .6152315905806268
       .7864552135990858 .617647307937804
       .7845565971555752 .6200572117632892
       .7826505961665757 .62246127937415
       .7807372285720945 .6248594881423863
       .778816512381476 .6272518154951441
       .7768884656732324 .629638238914927
       .7749531065948739 .6320187359398091
       .773010453362737 .6343932841636455
       .7710605242618138 .6367618612362842
       .7691033376455796 .6391244448637757
       .7671389119358204 .6414810128085832
       .765167265622459 .6438315428897915
       .7631884172633813 .6461760129833164
       .7612023854842618 .6485144010221124
       .7592091889783881 .6508466849963809
       .7572088465064846 .6531728429537768
       .7552013768965365 .6554928529996153
       .7531867990436125 .6578066932970786
       .7511651319096864 .6601143420674205
       .7491363945234594 .6624157775901718
       .7471006059801801 .6647109782033449
       .745057785441466 .6669999223036375
       .7430079521351217 .6692825883466361
       .7409511253549591 .6715589548470184
       .7388873244606151 .673829000378756
       .7368165688773699 .6760927035753159
       .7347388780959635 .6783500431298615
       .7326542716724128 .680600997795453
       .7305627692278276 .6828455463852481
       .7284643904482252 .6850836677727004
       .726359155084346 .6873153408917592
       .7242470829514669 .6895405447370669
       .7221281939292153 .6917592583641577
       .7200025079613817 .693971460889654
       .7178700450557317 .696177131491463
       .7157308252838187 .6983762494089728
       .7135848687807936 .7005687939432483
       .7114321957452164 .7027547444572253
       .7092728264388657 .7049340803759049
       ))

    (define (make-w log-n)
      (let* ((n (##expt 2 log-n))  ;; number of complexes
             (result (##make-f64vector (##fixnum.* 2 n))))

        (define (copy-low-lut)
          (##declare (not interrupts-enabled))
          (do ((i 0 (##fixnum.+ i 1)))
              ((##fixnum.= i lut-table-size))
            (let ((index (##fixnum.* i 2)))
              (##f64vector-set!
               result
               index
               (##f64vector-ref low-lut index))
              (##f64vector-set!
               result
               (##fixnum.+ index 1)
               (##f64vector-ref low-lut (##fixnum.+ index 1))))))

        (define (extend-lut multiplier-lut bit-reverse-size bit-reverse-multiplier start end)

          (define (bit-reverse x n)
            (declare (not interrupts-enabled))
            (do ((i 0 (##fixnum.+ i 1))
                 (x x (##fixnum.arithmetic-shift-right x 1))
                 (result 0 (##fixnum.+ (##fixnum.* result 2)
                                       (##fixnum.bitwise-and x 1))))
                ((##fixnum.= i n) result)))

          (let loop ((i start)
                     (j 1))
            (if (##fixnum.< i end)
                (let* ((multiplier-index
                        (##fixnum.* 2
                                    (bit-reverse j bit-reverse-size)
                                    bit-reverse-multiplier))
                       (multiplier-real
                        (##f64vector-ref multiplier-lut multiplier-index))
                       (multiplier-imag
                        (##f64vector-ref multiplier-lut (##fixnum.+ multiplier-index 1))))
                  (let inner ((i i)
                              (k 0))
                    (declare (not interrupts-enabled))
                    ;; we copy complex multiples of all entries below
                    ;; start to entries starting at start
                    (if (##fixnum.< k start)
                        (let* ((index
                                (##fixnum.* k 2))
                               (real
                                (##f64vector-ref result index))
                               (imag
                                (##f64vector-ref result (##fixnum.+ index 1)))
                               (result-real
                                (##flonum.- (##flonum.* multiplier-real real)
                                            (##flonum.* multiplier-imag imag)))
                               (result-imag
                                (##flonum.+ (##flonum.* multiplier-real imag)
                                            (##flonum.* multiplier-imag real)))
                               (result-index (##fixnum.* i 2)))
                          (##f64vector-set! result result-index result-real)
                          (##f64vector-set! result (##fixnum.+ result-index 1) result-imag)
                          (inner (##fixnum.+ i 1)
                                 (##fixnum.+ k 1)))
                        (loop i
                              (##fixnum.+ j 1)))))
                result)))

        (cond ((##fixnum.<= n lut-table-size)
               low-lut)
              ((##fixnum.<= n lut-table-size^2)
               (copy-low-lut)
               (extend-lut med-lut
                           (##fixnum.- log-n log-lut-table-size)
                           (##fixnum.arithmetic-shift-left 1 (##fixnum.- (##fixnum.* 2 log-lut-table-size) log-n))
                           lut-table-size
                           n))
              ((##fixnum.<= n lut-table-size^3)
               (copy-low-lut)
               (extend-lut med-lut
                           log-lut-table-size
                           1
                           lut-table-size
                           lut-table-size^2)
               (extend-lut high-lut
                           (##fixnum.- log-n (##fixnum.* 2 log-lut-table-size))
                           (##fixnum.arithmetic-shift-left 1 (##fixnum.- (##fixnum.* 3 log-lut-table-size) log-n))
                           lut-table-size^2
                           n))
              (else
               (error "asking for too large a table")))))

    (define (two^p>=m m)
      ;; returns smallest p, assumes fixnum m >= 0
      (##fxlength (##fixnum.- m)))

    ;; The next two routines are so-called radix-4 ffts, which seems
    ;; to mean that they combine two passes, each of which works on
    ;; pairs of complex numbers (hence radix-2?), so if you combine
    ;; two passes in one, you work on two pairs of complex numbers at
    ;; a time and make half as many passes through the f64vector a.

    (define (direct-fft-recursive-4 a W-table)

      ;; This is a direcct complex fft, using a decimation-in-time
      ;; algorithm with inputs in natural order and outputs in
      ;; bit-reversed order.  The table of "twiddle" factors is in
      ;; bit-reversed order.

      ;; this is from page 66 of Chu and George, except that we have
      ;; combined passes in pairs to cut the number of passes through
      ;; the vector a

      (let ((W (##f64vector (macro-inexact-+0)
                            (macro-inexact-+0)
                            (macro-inexact-+0)
                            (macro-inexact-+0))))

        (define (main-loop M N K SizeOfGroup)

          (##declare (not interrupts-enabled))

          (let inner-loop ((K K)
                           (JFirst M))

            (if (##fixnum.< JFirst N)

                (let* ((JLast  (##fixnum.+ JFirst SizeOfGroup)))

                  (if (##fixnum.even? K)
                      (begin
                        (##f64vector-set! W 0 (##f64vector-ref W-table K))
                        (##f64vector-set! W 1 (##f64vector-ref W-table (##fixnum.+ K 1))))
                      (begin
                        (##f64vector-set! W 0 (##flonum.- (##f64vector-ref W-table K)))
                        (##f64vector-set! W 1 (##f64vector-ref W-table (##fixnum.- K 1)))))

                  ;; we know the that the next two complex roots of
                  ;; unity have index 2K and 2K+1 so that the 2K+1
                  ;; index root can be gotten from the 2K index root
                  ;; in the same way that we get W_0 and W_1 from the
                  ;; table depending on whether K is even or not

                  (##f64vector-set! W 2 (##f64vector-ref W-table (##fixnum.* K 2)))
                  (##f64vector-set! W 3 (##f64vector-ref W-table (##fixnum.+ (##fixnum.* K 2) 1)))

                  (let J-loop ((J0 JFirst))
                    (if (##fixnum.< J0 JLast)

                        (let* ((J0 J0)
                               (J1 (##fixnum.+ J0 1))
                               (J2 (##fixnum.+ J0 SizeOfGroup))
                               (J3 (##fixnum.+ J2 1))
                               (J4 (##fixnum.+ J2 SizeOfGroup))
                               (J5 (##fixnum.+ J4 1))
                               (J6 (##fixnum.+ J4 SizeOfGroup))
                               (J7 (##fixnum.+ J6 1)))

                          (let ((W_0  (##f64vector-ref W 0))
                                (W_1  (##f64vector-ref W 1))
                                (W_2  (##f64vector-ref W 2))
                                (W_3  (##f64vector-ref W 3))
                                (a_J0 (##f64vector-ref a J0))
                                (a_J1 (##f64vector-ref a J1))
                                (a_J2 (##f64vector-ref a J2))
                                (a_J3 (##f64vector-ref a J3))
                                (a_J4 (##f64vector-ref a J4))
                                (a_J5 (##f64vector-ref a J5))
                                (a_J6 (##f64vector-ref a J6))
                                (a_J7 (##f64vector-ref a J7)))

                            ;; first we do the (overlapping) pairs of
                            ;; butterflies with entries 2*SizeOfGroup
                            ;; apart.

                            (let ((Temp_0 (##flonum.- (##flonum.* W_0 a_J4)
                                                      (##flonum.* W_1 a_J5)))
                                  (Temp_1 (##flonum.+ (##flonum.* W_0 a_J5)
                                                      (##flonum.* W_1 a_J4)))
                                  (Temp_2 (##flonum.- (##flonum.* W_0 a_J6)
                                                      (##flonum.* W_1 a_J7)))
                                  (Temp_3 (##flonum.+ (##flonum.* W_0 a_J7)
                                                      (##flonum.* W_1 a_J6))))

                              (let ((a_J0 (##flonum.+ a_J0 Temp_0))
                                    (a_J1 (##flonum.+ a_J1 Temp_1))
                                    (a_J2 (##flonum.+ a_J2 Temp_2))
                                    (a_J3 (##flonum.+ a_J3 Temp_3))
                                    (a_J4 (##flonum.- a_J0 Temp_0))
                                    (a_J5 (##flonum.- a_J1 Temp_1))
                                    (a_J6 (##flonum.- a_J2 Temp_2))
                                    (a_J7 (##flonum.- a_J3 Temp_3)))

                                ;; now we do the two (disjoint) pairs
                                ;; of butterflies distance SizeOfGroup
                                ;; apart, the first pair with W2+W3i,
                                ;; the second with -W3+W2i

                                ;; we rewrite the multipliers so I
                                ;; don't hurt my head too much when
                                ;; thinking about them.

                                (let ((W_0 W_2)
                                      (W_1 W_3)
                                      (W_2 (##flonum.- W_3))
                                      (W_3 W_2))

                                  (let ((Temp_0
                                         (##flonum.- (##flonum.* W_0 a_J2)
                                                     (##flonum.* W_1 a_J3)))
                                        (Temp_1
                                         (##flonum.+ (##flonum.* W_0 a_J3)
                                                     (##flonum.* W_1 a_J2)))
                                        (Temp_2
                                         (##flonum.- (##flonum.* W_2 a_J6)
                                                     (##flonum.* W_3 a_J7)))
                                        (Temp_3
                                         (##flonum.+ (##flonum.* W_2 a_J7)
                                                     (##flonum.* W_3 a_J6))))

                                    (let ((a_J0 (##flonum.+ a_J0 Temp_0))
                                          (a_J1 (##flonum.+ a_J1 Temp_1))
                                          (a_J2 (##flonum.- a_J0 Temp_0))
                                          (a_J3 (##flonum.- a_J1 Temp_1))
                                          (a_J4 (##flonum.+ a_J4 Temp_2))
                                          (a_J5 (##flonum.+ a_J5 Temp_3))
                                          (a_J6 (##flonum.- a_J4 Temp_2))
                                          (a_J7 (##flonum.- a_J5 Temp_3)))

                                      (##f64vector-set! a J0 a_J0)
                                      (##f64vector-set! a J1 a_J1)
                                      (##f64vector-set! a J2 a_J2)
                                      (##f64vector-set! a J3 a_J3)
                                      (##f64vector-set! a J4 a_J4)
                                      (##f64vector-set! a J5 a_J5)
                                      (##f64vector-set! a J6 a_J6)
                                      (##f64vector-set! a J7 a_J7)

                                      (J-loop (##fixnum.+ J0 2)))))))))
                        (inner-loop (##fixnum.+ K 1)
                                    (##fixnum.+ JFirst (##fixnum.* SizeOfGroup 4)))))))))

        (define (recursive-bit M N K SizeOfGroup)
          (if (##fixnum.<= 2 SizeOfGroup)
              (begin
                (main-loop M N K SizeOfGroup)
                (if (##fixnum.< 2048 (##fixnum.- N M))
                    (let ((new-size (##fixnum.arithmetic-shift-right (##fixnum.- N M) 2)))
                      (recursive-bit M
                                     (##fixnum.+ M new-size)
                                     (##fixnum.* K 4)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2))
                      (recursive-bit (##fixnum.+ M new-size)
                                     (##fixnum.+ M (##fixnum.* new-size 2))
                                     (##fixnum.+ (##fixnum.* K 4) 1)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2))
                      (recursive-bit (##fixnum.+ M (##fixnum.* new-size 2))
                                     (##fixnum.+ M (##fixnum.* new-size 3))
                                     (##fixnum.+ (##fixnum.* K 4) 2)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2))
                      (recursive-bit (##fixnum.+ M (##fixnum.* new-size 3))
                                     N
                                     (##fixnum.+ (##fixnum.* K 4) 3)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2)))
                    (recursive-bit M
                                   N
                                   (##fixnum.* K 4)
                                   (##fixnum.arithmetic-shift-right SizeOfGroup 2))))))

        (define (radix-2-pass a)

          ;; If we're here, the size of our (conceptually complex)
          ;; array is not a power of 4, so we need to do a basic radix
          ;; two pass with w=1 (so W[0]=1.0 and W[1] = 0.)  and then
          ;; call recursive-bit appropriately on the two half arrays.

          (declare (not interrupts-enabled))

          (let ((SizeOfGroup
                 (##fixnum.arithmetic-shift-right (##f64vector-length a) 1)))
            (let loop ((J0 0))
              (if (##fixnum.< J0 SizeOfGroup)
                  (let ((J0 J0)
                        (J2 (##fixnum.+ J0 SizeOfGroup)))
                    (let ((J1 (##fixnum.+ J0 1))
                          (J3 (##fixnum.+ J2 1)))
                      (let ((a_J0 (##f64vector-ref a J0))
                            (a_J1 (##f64vector-ref a J1))
                            (a_J2 (##f64vector-ref a J2))
                            (a_J3 (##f64vector-ref a J3)))
                        (let ((a_J0 (##flonum.+ a_J0 a_J2))
                              (a_J1 (##flonum.+ a_J1 a_J3))
                              (a_J2 (##flonum.- a_J0 a_J2))
                              (a_J3 (##flonum.- a_J1 a_J3)))
                          (##f64vector-set! a J0 a_J0)
                          (##f64vector-set! a J1 a_J1)
                          (##f64vector-set! a J2 a_J2)
                          (##f64vector-set! a J3 a_J3)
                          (loop (##fixnum.+ J0 2))))))))))

        (let* ((n (##f64vector-length a))
               (log_n (two^p>=m n)))

          ;; there are n/2 complex entries in a; if n/2 is not a power
          ;; of 4, then do a single radix-2 pass and do the rest of
          ;; the passes as radix-4 passes

          (if (##fixnum.odd? log_n)
              (recursive-bit 0 n 0 (##fixnum.arithmetic-shift-right n 2))
              (let ((n/2 (##fixnum.arithmetic-shift-right n 1))
                    (n/8 (##fixnum.arithmetic-shift-right n 3)))
                (radix-2-pass a)
                (recursive-bit 0 n/2 0 n/8)
                (recursive-bit n/2 n 1 n/8))))))

    ;; The following routine simply reverses the operations of the
    ;; previous routine.

    (define (inverse-fft-recursive-4 a W-table)

      ;; This is an complex fft, using a decimation-in-frequency algorithm
      ;; with inputs in bit-reversed order and outputs in natural order.

      ;; The organization of the algorithm has little to do with the the
      ;; associated algorithm on page 41 of Chu and George,
      ;; I just reversed the operations of the direct algorithm given
      ;; above (without dividing by 2 each time, so that this has to
      ;; be "normalized" by dividing by N/2 at the end.

      ;; The table of "twiddle" factors is in bit-reversed order.

      (let ((W (##f64vector (macro-inexact-+0)
                            (macro-inexact-+0)
                            (macro-inexact-+0)
                            (macro-inexact-+0))))

        (define (main-loop M N K SizeOfGroup)
          (##declare (not interrupts-enabled))
          (let inner-loop ((K K)
                           (JFirst M))
            (if (##fixnum.< JFirst N)
                (let* ((JLast  (##fixnum.+ JFirst SizeOfGroup)))
                  (if (##fixnum.even? K)
                      (begin
                        (##f64vector-set! W 0 (##f64vector-ref W-table K))
                        (##f64vector-set! W 1 (##f64vector-ref W-table (##fixnum.+ K 1))))
                      (begin
                        (##f64vector-set! W 0 (##flonum.- (##f64vector-ref W-table K)))
                        (##f64vector-set! W 1 (##f64vector-ref W-table (##fixnum.- K 1)))))
                  (##f64vector-set! W 2 (##f64vector-ref W-table (##fixnum.* K 2)))
                  (##f64vector-set! W 3 (##f64vector-ref W-table (##fixnum.+ (##fixnum.* K 2) 1)))
                  (let J-loop ((J0 JFirst))
                    (if (##fixnum.< J0 JLast)
                        (let* ((J0 J0)
                               (J1 (##fixnum.+ J0 1))
                               (J2 (##fixnum.+ J0 SizeOfGroup))
                               (J3 (##fixnum.+ J2 1))
                               (J4 (##fixnum.+ J2 SizeOfGroup))
                               (J5 (##fixnum.+ J4 1))
                               (J6 (##fixnum.+ J4 SizeOfGroup))
                               (J7 (##fixnum.+ J6 1)))
                          (let ((W_0  (##f64vector-ref W 0))
                                (W_1  (##f64vector-ref W 1))
                                (W_2  (##f64vector-ref W 2))
                                (W_3  (##f64vector-ref W 3))
                                (a_J0 (##f64vector-ref a J0))
                                (a_J1 (##f64vector-ref a J1))
                                (a_J2 (##f64vector-ref a J2))
                                (a_J3 (##f64vector-ref a J3))
                                (a_J4 (##f64vector-ref a J4))
                                (a_J5 (##f64vector-ref a J5))
                                (a_J6 (##f64vector-ref a J6))
                                (a_J7 (##f64vector-ref a J7)))
                            (let ((W_00 W_2)
                                  (W_01 W_3)
                                  (W_02 (##flonum.- W_3))
                                  (W_03 W_2))
                              (let ((Temp_0 (##flonum.- a_J0 a_J2))
                                    (Temp_1 (##flonum.- a_J1 a_J3))
                                    (Temp_2 (##flonum.- a_J4 a_J6))
                                    (Temp_3 (##flonum.- a_J5 a_J7)))
                                (let ((a_J0 (##flonum.+ a_J0 a_J2))
                                      (a_J1 (##flonum.+ a_J1 a_J3))
                                      (a_J4 (##flonum.+ a_J4 a_J6))
                                      (a_J5 (##flonum.+ a_J5 a_J7))
                                      (a_J2 (##flonum.+ (##flonum.* W_00 Temp_0)
                                                        (##flonum.* W_01 Temp_1)))
                                      (a_J3 (##flonum.- (##flonum.* W_00 Temp_1)
                                                        (##flonum.* W_01 Temp_0)))
                                      (a_J6 (##flonum.+ (##flonum.* W_02 Temp_2)
                                                        (##flonum.* W_03 Temp_3)))
                                      (a_J7 (##flonum.- (##flonum.* W_02 Temp_3)
                                                        (##flonum.* W_03 Temp_2))))
                                  (let ((Temp_0 (##flonum.- a_J0 a_J4))
                                        (Temp_1 (##flonum.- a_J1 a_J5))
                                        (Temp_2 (##flonum.- a_J2 a_J6))
                                        (Temp_3 (##flonum.- a_J3 a_J7)))
                                    (let ((a_J0 (##flonum.+ a_J0 a_J4))
                                          (a_J1 (##flonum.+ a_J1 a_J5))
                                          (a_J2 (##flonum.+ a_J2 a_J6))
                                          (a_J3 (##flonum.+ a_J3 a_J7))
                                          (a_J4 (##flonum.+ (##flonum.* W_0 Temp_0)
                                                            (##flonum.* W_1 Temp_1)))
                                          (a_J5 (##flonum.- (##flonum.* W_0 Temp_1)
                                                            (##flonum.* W_1 Temp_0)))
                                          (a_J6 (##flonum.+ (##flonum.* W_0 Temp_2)
                                                            (##flonum.* W_1 Temp_3)))
                                          (a_J7 (##flonum.- (##flonum.* W_0 Temp_3)
                                                            (##flonum.* W_1 Temp_2))))
                                      (##f64vector-set! a J0 a_J0)
                                      (##f64vector-set! a J1 a_J1)
                                      (##f64vector-set! a J2 a_J2)
                                      (##f64vector-set! a J3 a_J3)
                                      (##f64vector-set! a J4 a_J4)
                                      (##f64vector-set! a J5 a_J5)
                                      (##f64vector-set! a J6 a_J6)
                                      (##f64vector-set! a J7 a_J7)
                                      (J-loop (##fixnum.+ J0 2)))))))))
                        (inner-loop (##fixnum.+ K 1)
                                    (##fixnum.+ JFirst (##fixnum.* SizeOfGroup 4)))))))))

        (define (recursive-bit M N K SizeOfGroup)
          (if (##fixnum.<= 2 SizeOfGroup)
              (begin
                (if (##fixnum.< 2048 (##fixnum.- N M))
                    (let ((new-size (##fixnum.arithmetic-shift-right (##fixnum.- N M) 2)))
                      (recursive-bit M
                                     (##fixnum.+ M new-size)
                                     (##fixnum.* K 4)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2))
                      (recursive-bit (##fixnum.+ M new-size)
                                     (##fixnum.+ M (##fixnum.* new-size 2))
                                     (##fixnum.+ (##fixnum.* K 4) 1)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2))
                      (recursive-bit (##fixnum.+ M (##fixnum.* new-size 2))
                                     (##fixnum.+ M (##fixnum.* new-size 3))
                                     (##fixnum.+ (##fixnum.* K 4) 2)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2))
                      (recursive-bit (##fixnum.+ M (##fixnum.* new-size 3))
                                     N
                                     (##fixnum.+ (##fixnum.* K 4) 3)
                                     (##fixnum.arithmetic-shift-right SizeOfGroup 2)))
                    (recursive-bit M
                                   N
                                   (##fixnum.* K 4)
                                   (##fixnum.arithmetic-shift-right SizeOfGroup 2)))
                (main-loop M N K SizeOfGroup))))

        (define (radix-2-pass a)
          (declare (not interrupts-enabled))
          (let ((SizeOfGroup
                 (##fixnum.arithmetic-shift-right (##f64vector-length a) 1)))
            (let loop ((J0 0))
              (if (##fixnum.< J0 SizeOfGroup)
                  (let ((J0 J0)
                        (J2 (##fixnum.+ J0 SizeOfGroup)))
                    (let ((J1 (##fixnum.+ J0 1))
                          (J3 (##fixnum.+ J2 1)))
                      (let ((a_J0 (##f64vector-ref a J0))
                            (a_J1 (##f64vector-ref a J1))
                            (a_J2 (##f64vector-ref a J2))
                            (a_J3 (##f64vector-ref a J3)))
                        (let ((a_J0 (##flonum.+ a_J0 a_J2))
                              (a_J1 (##flonum.+ a_J1 a_J3))
                              (a_J2 (##flonum.- a_J0 a_J2))
                              (a_J3 (##flonum.- a_J1 a_J3)))
                          (##f64vector-set! a J0 a_J0)
                          (##f64vector-set! a J1 a_J1)
                          (##f64vector-set! a J2 a_J2)
                          (##f64vector-set! a J3 a_J3)
                          (loop (##fixnum.+ J0 2))))))))))

        (let* ((n (##f64vector-length a))
               (log_n (two^p>=m n)))
          (if (##fixnum.odd? log_n)
              (recursive-bit 0 n 0 (##fixnum.arithmetic-shift-right n 2))
              (let ((n/2 (##fixnum.arithmetic-shift-right n 1))
                    (n/8 (##fixnum.arithmetic-shift-right n 3)))
                (recursive-bit 0 n/2 0 n/8)
                (recursive-bit n/2 n 1 n/8)
                (radix-2-pass a))))))

    #|

    See the wonderful paper
    Rapid multiplication modulo the sum and difference of highly
    composite numbers, by Colin Percival, electronically published
    by Mathematics of Computation, number S 0025-5718(02)01419-9, URL
    http://www.ams.org/journal-getitem?pii=S0025-5718-02-01419-9
    that gives these very nice error bounds.  This should be published
    in the paper journal sometime after March 2002.

    What we're going to do is:

    Take x and y, each with <= 2^n 8-bit fdigits.
    Put the fdigits of x and y into the real parts of the
    first 2^n complex entries of a vector of length 2^{n+1}.
    Do ffts of length 2^{n+1}.
    Multiply the complex fft coefficients of x and y.
    do an inverse fft of length 2^{n+1}.
    Extract the digits of x*y from the real parts of the inverse fft.

    From theorem 5.1 we get the following error bound:

    (define epsilon (expt 2. -53))
    (define bigepsilon (* epsilon (sqrt 5)))
    (define n 26)
    (define beta 4.158491068379826e-16)      ;; accuracy of trigonometric inputs (check) error in product of three entries from the tables
    (define norm-x (sqrt (* (expt 2 n) (* 255 255))))
    (define norm-y norm-x)
    (define error (* norm-x
                     norm-y
                     ;; the following three lines use the slight overestimate that
                     ;; ln(1+epsilon) = epsilon, etc.
                     ;; there are more accurate ways to calculate this, but we
                     ;; don't really need them.
                     (- (exp (+ (* 3 (+ n 1) epsilon)
                                (* (+ (* 3 (+ n 1)) 1) bigepsilon)
                                (* 3 (+ n 1) beta)))
                        1)))
    (pp error)

    Error bound is .27518123388290405  < 1/2

    So if x and y have fewer than 2^{26}\times 8=536,870,912 bits, this computes the product exactly.

    It appears that we need tables only of size 2^9 complex entries rather than 2^10 if we do this.  That would
    cut down on memory.

    Let's look at what happens when you have 4-bit fft words:

    (define epsilon (expt 2. -53))
    (define bigepsilon (* epsilon (sqrt 5)))
    (define n 34)
    (define beta 4.158491068379826e-16)      ;; accuracy of trigonometric inputs
    (define l 4)
    (define norm-x (sqrt (* (expt 2 n) (* 15 15))))
    (define norm-y norm-x)
    (define error (* norm-x
                     norm-y
                     (- (exp (+ (* 3 (+ n 1) epsilon)
                                (* (+ (* 3 (+ n 1)) 1) bigepsilon)
                                (* 3 (+ n 1) beta)))
                        1)))
    (pp error)

    Error bound is .31585693359375 < 1/2

    So if x and y have fewer than 2^{34}\times 4=68,719,476,736 bits, this
    computes the product exactly.

    But then I would have to increase the size of the tables to 2^{11}
    complex entries each, so we'd have tables of 4 times the size.

    I think I won't add a four-bit fft word option for now.

    Because the fft algorithm as written requires temporary storage at least
    sixteen times the size of the final result, people working with large
    integers but barely enough memory on 64-bit machines may wish to
    set! ##bignum.fft-mul-max-width to a slightly smaller value so that
    karatsuba will kick in earlier for the largest integers.

    COMMENTS FOR THE RAC (Right-Angle Convolution) VERSION

    What we're going to do is:

    Take x and y, which together have a total of  <= 2^{n+1} 8-bit fdigits.
    We take the fdigits of f and put them into the real parts of a complex
    vector of length 2^n; if there are any left over, place the rest in the
    imaginary parts of the complex vector, starting over at the 0 entry.
    We do the same for y.
    We componentwise multiply x_j by e^{\pi/2 i j/2^n}; similarly for y_j.
    (This is the "right-angle" part of the right-angle transform.)
    The maximum possible product of |x|_2 and |y|_2 are when they both
    have 2^n eight-bit digits.
    Do ffts of length 2^n.
    Multiply the complex fft coefficients of x and y.
    do an inverse fft of length 2^n.
    We componentwise multiply the result by e^{-\pi/2 i j/2^n}, i.e.,
    the inverse of the entries of the weights applied to x and y

    Extract the digits of x*y from the real parts and then the imaginary
    parts of the weighted inverse fft.

    From Theorem 6.1 and the following displayed equation we have

    (define epsilon (expt 2. -53))
    (define bigepsilon (* epsilon (sqrt 5)))
    (define n 26)
    (define beta 4.164343159519809e-16)      ;; accuracy of trigonometric inputs (check) error in product of three entries from the tables
    (define norm-x (sqrt (* (expt 2 n) (* 255 255))))
    (define norm-y norm-x)
    (define error (* norm-x
                     norm-y
                     ;; the following three lines use the slight overestimate that
                     ;; ln(1+epsilon) = epsilon, etc.
                     ;; there are more accurate ways to calculate this, but we
                     ;; don't really need them.
                     (- (exp (+ (* 3 n epsilon)
                                (* (+ (* 3 n) 4) bigepsilon)
                                (* (+ (* 3 n) 3) beta)))
                        1)))
    (pp error)

    The error bound is .2742122858762741, so we're cool.

    |#

    #|

    Let n = 2^{\log n}; the following routine calculates

    e^{\pi/2 i (j/n)} j=0,\ldots, n/2-1

    It uses the tables med-lut and high-lut (both described above) and
    low-lut-rac, which contains in fftluts-9.scm

    e^{\pi/2 i (j/2^9)}, j=0,\ldots, 2^8-1

    It uses the same general strategy as make-w, except, because the
    final result is in normal order rather than bit-reversed order, we
    start with the highest table and work our way to the lowest.  As
    noted above, this should result in slightly smaller error than from make-w.

    Instead of always building a new table, one could reuse a bigger one with
    a stride (do the math).  I don't want to do this, however; I'd rather build
    a new, compact table and hope that this will result in fewer cache/TLB/page
    misses.

    |#

    (define (make-w-rac log-n)
      (let* ((n (##expt 2 log-n))
             (result (##make-f64vector n)))   ;; contains n/2 complexes

        (define (copy-lut lut stride)

          ;; copies the (conceptually complex) entries
          ;; lut[0], lut[(stride/2)], lut[2*(stride/2)], ...
          ;; to the first entries of result.  We stop when we hit
          ;; the end of lut.

          (##declare (not interrupts-enabled))
          (let ((lut-size (##f64vector-length lut)))
            (do ((i 0 (##fixnum.+ i 2))
                 (j 0 (##fixnum.+ j stride)))
                ((##fixnum.= j lut-size) result)
              (##f64vector-set! result             i    (##f64vector-ref lut             j   ))
              (##f64vector-set! result (##fixnum.+ i 1) (##f64vector-ref lut (##fixnum.+ j 1))))))

        (define (extend-lut multiplier-lut start)

          ;; we multiply the table from 0 to start-1 (in pairs of reals
          ;; as complexes) by all the multipliers in multiplier-lut
          ;; starting at 2 (again in pairs of reals)

          (let ((end (##f64vector-length multiplier-lut)))
            (let loop ((i start)
                       (j 2))
              (if (##fixnum.< j end)
                  (let* ((multiplier-real (##f64vector-ref multiplier-lut j))
                         (multiplier-imag (##f64vector-ref multiplier-lut (##fixnum.+ j 1))))
                    (let inner ((i i)
                                (k 0))
                      (declare (not interrupts-enabled))
                      (if (##fixnum.< k start)
                          (let* ((real  (##f64vector-ref result k))
                                 (imag  (##f64vector-ref result (##fixnum.+ k 1)))
                                 (result-real (##flonum.- (##flonum.* multiplier-real real)
                                                          (##flonum.* multiplier-imag imag)))
                                 (result-imag (##flonum.+ (##flonum.* multiplier-real imag)
                                                          (##flonum.* multiplier-imag real))))
                            (##f64vector-set! result i result-real)
                            (##f64vector-set! result (##fixnum.+ i 1) result-imag)
                            (inner (##fixnum.+ i 2)
                                   (##fixnum.+ k 2)))
                          (loop i
                                (##fixnum.+ j 2)))))
                  result))))

        (cond ((##fixnum.= n lut-table-size)
               low-lut-rac)

              ((##fixnum.< n lut-table-size)
               (let ((stride (##fixnum.quotient (##fixnum.* lut-table-size 2) n))) ;; = 2 when n = lut-table-size, etc.
                 (copy-lut low-lut-rac stride)))

              ((##fixnum.<= n lut-table-size^2)
               (let* ((stride (##fixnum.quotient (##fixnum.* lut-table-size^2 2) n))
                      (start  (##fixnum.quotient (##fixnum.* lut-table-size 4) stride))) ;; = 2 lut-table-size when n=lut-table-size^2
                 (copy-lut med-lut stride)
                 (extend-lut low-lut-rac (##fixnum.arithmetic-shift-right n (##fixnum.- log-lut-table-size 1)))))

              ((##fixnum.<= n lut-table-size^3)
               (let* ((stride (##fixnum.quotient (##fixnum.* lut-table-size^3 2) n))
                      (start  (##fixnum.quotient (##fixnum.* lut-table-size 4) stride)))
                 (copy-lut high-lut stride)
                 (extend-lut med-lut start)
                 (extend-lut low-lut-rac (##fixnum.* start lut-table-size))))
              (else
               (error "asking for too large a table")))))

    (define (bignum->f64vector-rac x a)

      ;; Copies the first (##f64vector-length a)/2 fdigits of x into the
      ;; even components of a, which represent the real parts of complex
      ;; elements, and then the rest of the fdigits of x into the odd
      ;; components of a, starting over at 1.

      (let ((two^n (##f64vector-length a))
            (x-length (##bignum.fdigit-length x)))

        (if (##fixnum.<= (##fixnum.* x-length 2)
                         two^n)
            ;; all imaginary parts are 0.
            (let loop1 ((i 0)
                        (j 0))
              (##declare (not interrupts-enabled))
              (if (##fixnum.< i x-length)
                  (let ((digit-real   (##flonum.<-fixnum (##bignum.fdigit-ref x i))))
                    (##f64vector-set! a             j    digit-real)
                    (##f64vector-set! a (##fixnum.+ j 1) (macro-inexact-+0))
                    (loop1 (##fixnum.+ i 1)
                           (##fixnum.+ j 2)))
                                        ;; all parts are zero
                  (let loop2 ((j j))
                    (if (##fixnum.< j two^n)
                        (begin
                          (##f64vector-set! a j (macro-inexact-+0))
                          (##f64vector-set! a (##fixnum.+ j 1) (macro-inexact-+0))
                          (loop2 (##fixnum.+ j 2)))))))

            (let ((offset (##fixnum.arithmetic-shift-right two^n 1)))
              (let loop1 ((i 0)
                          (j 0))
                (##declare (not interrupts-enabled))
                (if (##fixnum.< (##fixnum.+ i offset) x-length)
                    (let ((digit-real (##flonum.<-fixnum (##bignum.fdigit-ref x             i        )))
                          (digit-imag (##flonum.<-fixnum (##bignum.fdigit-ref x (##fixnum.+ i offset)))))
                      (##f64vector-set! a             j    digit-real)
                      (##f64vector-set! a (##fixnum.+ j 1) digit-imag)
                      (loop1 (##fixnum.+ i 1)
                             (##fixnum.+ j 2)))
                    ;; all imaginary parts are 0.
                    (let loop2 ((i i)
                                (j j))
                      (if (##fixnum.< j two^n)
                          (let ((digit-real   (##flonum.<-fixnum (##bignum.fdigit-ref x i))))
                            (##f64vector-set! a             j    digit-real)
                            (##f64vector-set! a (##fixnum.+ j 1) (macro-inexact-+0))
                            (loop2 (##fixnum.+ i 1)
                                   (##fixnum.+ j 2)))))))))))

    (define (componentwise-rac-multiply a table)

      ;; the (conceptually complex) entries of table are
      ;; e^{\pi/2 i (j/2^n)}, j=0,...,2^{n-1}-1.
      ;; We multiply a_i componentwise by table_i, using symmetry when i\geq 2^{n-1}

      (let ((table-size (##f64vector-length table))
            (a-size (##f64vector-length a)))
        (declare (not interrupts-enabled))   ;; note that this means we have to be careful not to cons.
        (let loop ((i 2)
                   (j 2))
          (if (##fixnum.< i table-size)
              (let ((multiplier-real (##f64vector-ref table i))
                    (multiplier-imag (##f64vector-ref table (##fixnum.+ i 1))))
                (let ((a_j-real   (##f64vector-ref a             j   ))
                      (a_j-imag   (##f64vector-ref a (##fixnum.+ j 1)))
                      (a_N-j-real (##f64vector-ref a (##fixnum.- a-size j   )))
                      (a_N-j-imag (##f64vector-ref a (##fixnum.- a-size j -1))))
                  (let ((result_j-real (##flonum.- (##flonum.* a_j-real multiplier-real)
                                                   (##flonum.* a_j-imag multiplier-imag)))
                        (result_j-imag (##flonum.+ (##flonum.* a_j-imag multiplier-real)
                                                   (##flonum.* a_j-real multiplier-imag)))
                        ;; if multipler_j=(make-rectangular r i) then multiplier_{N-j}=(make-rectangular i r)
                        (result_N-j-real (##flonum.- (##flonum.* a_N-j-real multiplier-imag)
                                                     (##flonum.* a_N-j-imag multiplier-real)))
                        (result_N-j-imag (##flonum.+ (##flonum.* a_N-j-imag multiplier-imag)
                                                     (##flonum.* a_N-j-real multiplier-real))))
                    (##f64vector-set! a             j    result_j-real)
                    (##f64vector-set! a (##fixnum.+ j 1) result_j-imag)
                    (##f64vector-set! a (##fixnum.- a-size j   ) result_N-j-real)
                    (##f64vector-set! a (##fixnum.- a-size j -1) result_N-j-imag)
                    (loop (##fixnum.+ i 2)
                          (##fixnum.+ j 2)))))
              (let ((multiplier-real .7071067811865476)  ;; here the multiplier is always (sqrt i)
                    (multiplier-imag .7071067811865476)
                    (a_j-real (##f64vector-ref a j))
                    (a_j-imag (##f64vector-ref a (##fixnum.+ j 1))))
                (let ((result_j-real (##flonum.- (##flonum.* a_j-real multiplier-real)
                                                 (##flonum.* a_j-imag multiplier-imag)))
                      (result_j-imag (##flonum.+ (##flonum.* a_j-imag multiplier-real)
                                                 (##flonum.* a_j-real multiplier-imag))))
                  (##f64vector-set! a             j    result_j-real)
                  (##f64vector-set! a (##fixnum.+ j 1) result_j-imag)))))))

    (define (componentwise-rac-multiply-conjugate a table)
      ;; the (conceptually complex) entries of table are
      ;; e^{\pi/2 i (j/2^n)}, j=0,...,2^{n-1}-1.
      ;; We multiply a_i componentwise by the conjugate/inverse of table_i, using symmetry when i\geq 2^{n-1}

      (let ((table-size (##f64vector-length table))
            (a-size (##f64vector-length a)))
        (declare (not interrupts-enabled))   ;; note that this means we have to be careful not to cons.
        (let loop ((i 2)
                   (j 2))
          (if (##fixnum.< i table-size)
              (let ((multiplier-real (##f64vector-ref table i))
                    (multiplier-imag (##f64vector-ref table (##fixnum.+ i 1))))
                (let ((a_j-real   (##f64vector-ref a             j   ))
                      (a_j-imag   (##f64vector-ref a (##fixnum.+ j 1)))
                      (a_N-j-real (##f64vector-ref a (##fixnum.- a-size j   )))
                      (a_N-j-imag (##f64vector-ref a (##fixnum.- a-size j -1))))

                  (let ((result_j-real (##flonum.+ (##flonum.* a_j-real multiplier-real)
                                                   (##flonum.* a_j-imag multiplier-imag)))
                        (result_j-imag (##flonum.- (##flonum.* a_j-imag multiplier-real)
                                                   (##flonum.* a_j-real multiplier-imag)))
                        ;; if multipler_j=(make-rectangular r i) then multiplier_{N-j}=(make-rectangular i r)
                        (result_N-j-real (##flonum.+ (##flonum.* a_N-j-real multiplier-imag)
                                                     (##flonum.* a_N-j-imag multiplier-real)))
                        (result_N-j-imag (##flonum.- (##flonum.* a_N-j-imag multiplier-imag)
                                                     (##flonum.* a_N-j-real multiplier-real))))
                    (##f64vector-set! a             j    result_j-real)
                    (##f64vector-set! a (##fixnum.+ j 1) result_j-imag)
                    (##f64vector-set! a (##fixnum.- a-size j   ) result_N-j-real)
                    (##f64vector-set! a (##fixnum.- a-size j -1) result_N-j-imag)
                    (loop (##fixnum.+ i 2)
                          (##fixnum.+ j 2)))))
              (let ((multiplier-real .7071067811865476)  ;; here the multiplier is always (sqrt i)
                    (multiplier-imag .7071067811865476)
                    (a_j-real (##f64vector-ref a j))
                    (a_j-imag (##f64vector-ref a (##fixnum.+ j 1))))
                (let ((result_j-real (##flonum.+ (##flonum.* a_j-real multiplier-real)
                                                 (##flonum.* a_j-imag multiplier-imag)))
                      (result_j-imag (##flonum.- (##flonum.* a_j-imag multiplier-real)
                                                 (##flonum.* a_j-real multiplier-imag))))
                  (##f64vector-set! a             j    result_j-real)
                  (##f64vector-set! a (##fixnum.+ j 1) result_j-imag)))))))

    (define (componentwise-complex-multiply a b)
      (let ((two^n (##f64vector-length a)))
        (let loop ((j 0))
          (##declare (not interrupts-enabled))
          (if (##fixnum.< j two^n)
              (let ((aj (##f64vector-ref a j))
                    (aj+1 (##f64vector-ref a (##fixnum.+ j 1)))
                    (bj (##f64vector-ref b j))
                    (bj+1 (##f64vector-ref b (##fixnum.+ j 1))))
                (##f64vector-set! a j
                                  (##flonum.- (##flonum.* bj aj)   (##flonum.* aj+1 bj+1)))
                (##f64vector-set! a (##fixnum.+ j 1)
                                  (##flonum.+ (##flonum.* bj aj+1) (##flonum.* aj   bj+1)))
                (loop (##fixnum.+ j 2)))))))

    (define (bignum<-f64vector-rac a result result-length)

      ;; result-length is > the number of complex entries in a, because
      ;; otherwise the length of a would be cut in half.

      (let* ((normalizer (##flonum./ (##flonum.<-fixnum (##fixnum.arithmetic-shift-right (##f64vector-length a) 1))))
             (fbase (##flonum.<-fixnum ##bignum.fdigit-base))
             (fbase-inverse (##flonum./ fbase)))
        (let ((loop-carry (##f64vector (macro-inexact-+0))))
          (let loop ((i 0)
                     (j 0)
                     (limit (##fixnum.arithmetic-shift-right (##f64vector-length a) 1)))  ;; here we assume that there are always at least this many fdigits
            (##declare (not interrupts-enabled))
            (if (##fixnum.< i limit)
                (let* ((t
                        (##flonum.+ (##flonum.+ (##f64vector-ref loop-carry 0)
                                                (macro-inexact-+1/2))
                                    (##flonum.* (##f64vector-ref a j)
                                                normalizer)))
                       (carry
                        (##flonum.floor (##flonum.* t fbase-inverse)))
                       (digit
                        (##flonum.- t (##flonum.* carry fbase))))
                  (##bignum.fdigit-set! result i (##flonum->fixnum digit))
                  (##f64vector-set! loop-carry 0 carry)
                  (loop (##fixnum.+ i 1)
                        (##fixnum.+ j 2)
                        limit))
                (if (##fixnum.even? j)
                    (loop i
                          1
                          result-length)))))))

    ;; this is the right-angle convolution method of section 6 in Percival's paper

    (let* ((x-length (##bignum.fdigit-length x))
           (y-length (##bignum.fdigit-length y))
           (result-length (##fixnum.+ x-length y-length))
           (result (##bignum.make
                    (##fixnum.quotient
                     result-length
                     (##fixnum.quotient ##bignum.adigit-width
                                        ##bignum.fdigit-width))
                    #f
                    #f))
           ;; minimum power of 2 >= x-length + y-length, half # of complex elements in fft vectors
           (log-two^n (##fixnum.- (two^p>=m (##fixnum.+ x-length y-length)) 1))
           (two^n (##fixnum.arithmetic-shift-left 1 log-two^n)))

      (let ((a         (##make-f64vector (##fixnum.* two^n 2)))
            (table     (make-w     (##fixnum.- log-two^n 1)))
            (rac-table (make-w-rac log-two^n)))

        (bignum->f64vector-rac x a)
        (componentwise-rac-multiply a rac-table)
        (direct-fft-recursive-4 a table)
        (if (##eq? x y)
            (componentwise-complex-multiply a a)
            (let ((b (##make-f64vector (##fixnum.* two^n 2))))
              (bignum->f64vector-rac y b)
              (componentwise-rac-multiply b rac-table)
              (direct-fft-recursive-4 b table)
              (componentwise-complex-multiply a b)))
        (inverse-fft-recursive-4 a table)
        (componentwise-rac-multiply-conjugate a rac-table)
        (bignum<-f64vector-rac a result result-length)
        (cleanup x y result))))


  (define (naive-mul x x-length y y-length)  ;; multiplies x by each digit of y
    (let ((result
           (##bignum.make
            (##fixnum.+ (##bignum.adigit-length x) (##bignum.adigit-length y))
            #f
            #f)))
      (##declare (not interrupts-enabled))
      (if (##eq? x y)

        (let loop1 ((k 1))   ;; multiply off-diagonals
          (if (##fixnum.< k x-length)
            (let ((multiplier (##bignum.mdigit-ref x k)))
              (if (##eq? multiplier 0)
                (loop1 (##fixnum.+ k 1))
                (let loop2 ((i 0)
                            (j k)
                            (carry 0))
                  (if (##fixnum.< i k)
                    (loop2 (##fixnum.+ i 1)
                           (##fixnum.+ j 1)
                           (##bignum.mdigit-mul! result
                                                 j
                                                 x
                                                 i
                                                 multiplier
                                                 carry))
                    (begin
                      (##bignum.mdigit-set! result j carry)
                      (loop1 (##fixnum.+ k 1)))))))
            (let ((result-length (##bignum.adigit-length result)))
              (let loop3 ((k 0)       ;; double the off-diagonal terms
                          (carry 0))
                (if (##fixnum.< k result-length)
                  (loop3 (##fixnum.+ k 1)
                         (##bignum.adigit-add! result
                                               k
                                               result
                                               k
                                               carry))
                  (let ((shift ##bignum.mdigit-width)
                        (mask ##bignum.mdigit-base-minus-1))
                    (let loop4 ((k 0)              ;; add squares of diagonals
                                (two-k 0)
                                (carry 0))
                      (if (##fixnum.< k x-length)
                        (let ((next-digit
                               (##fixnum.+ (##bignum.mdigit-mul!
                                            result
                                            two-k
                                            x
                                            k
                                            (##bignum.mdigit-ref x k)
                                            carry)
                                           (##bignum.mdigit-ref
                                            result
                                            (##fixnum.+ two-k 1)))))
                          (##bignum.mdigit-set!
                           result
                           (##fixnum.+ two-k 1)
                           (##fixnum.bitwise-and next-digit mask))
                          (loop4 (##fixnum.+ k 1)
                                 (##fixnum.+ two-k 2)
                                 (##fixnum.arithmetic-shift-right
                                  next-digit
                                  shift)))
                        (cleanup x y result)))))))))

        (let loop1 ((k 0))
          (##declare (not interrupts-enabled))
          (if (##fixnum.< k y-length)
            (let ((multiplier (##bignum.mdigit-ref y k)))
              (if (##eq? multiplier 0)
                (loop1 (##fixnum.+ k 1))
                (let loop2 ((i 0)
                            (j k)
                            (carry 0))
                  (if (##fixnum.< i x-length)
                    (loop2 (##fixnum.+ i 2)
                           (##fixnum.+ j 2)
                           (##bignum.mdigit-mul!
                            result
                            (##fixnum.+ j 1)
                            x
                            (##fixnum.+ i 1)
                            multiplier
                            (##bignum.mdigit-mul! result
                                                  j
                                                  x
                                                  i
                                                  multiplier
                                                  carry)))
                    (begin
                      (##bignum.mdigit-set! result j carry)
                      (loop1 (##fixnum.+ k 1)))))))
            (cleanup x y result))))))

  (define (cleanup x y result)

    ;; Both naive-mul and fft-mul do unsigned multiplies, fix that here.

    (define (fix x y result)

      (##declare (not interrupts-enabled))

      (if (##bignum.negative? y)
        (let ((x-length (##bignum.adigit-length x)))
          (let loop ((i 0)
                     (j (##bignum.adigit-length y))
                     (borrow 0))
            (if (##fixnum.< i x-length)
              (loop (##fixnum.+ i 1)
                    (##fixnum.+ j 1)
                    (##bignum.adigit-sub! result j x i borrow)))))))

    (fix x y result)
    (fix y x result)
    (##bignum.normalize! result))

  (define (karatsuba-mul x y)
    (let* ((x-length
            (##bignum.adigit-length x))
           (y-length
            (##bignum.adigit-length y))
           (shift-digits
            (##fixnum.arithmetic-shift-right y-length 1))
           (shift-bits
            (##fixnum.* shift-digits ##bignum.adigit-width))
           (y-high
            (##bignum.arithmetic-shift y (##fixnum.- shift-bits)))
           (y-low
            (##extract-bit-field shift-bits 0 y)))
      (if (##eq? x y)
          (let ((high-term
                 (##* y-high y-high))
                (low-term
                 (##* y-low y-low))
                (mid-term
                 (let ((arg (##- y-high y-low)))
                   (##* arg arg))))
            (##+ (##arithmetic-shift high-term (##fixnum.* shift-bits 2))
                 (##+ (##arithmetic-shift
                       (##+ high-term
                            (##- low-term mid-term))
                       shift-bits)
                      low-term)))
          (let ((x-high
                 (##bignum.arithmetic-shift x (##fixnum.- shift-bits)))
                (x-low
                 (##extract-bit-field shift-bits 0 x)))
            (let ((high-term
                   (##* x-high y-high))
                  (low-term
                   (##* x-low y-low))
                  (mid-term
                   (##* (##- x-high x-low)
                        (##- y-high y-low))))
              (##+ (##arithmetic-shift high-term (##fixnum.* shift-bits 2))
                   (##+ (##arithmetic-shift
                         (##+ high-term
                              (##- low-term mid-term))
                         shift-bits)
                        low-term)))))))

  (define (mul x x-length y y-length) ;; x-length <= y-length
    (let ((x-width (##fixnum.* x-length ##bignum.mdigit-width)))
      (cond ((##fixnum.< x-width ##bignum.naive-mul-max-width)
             (naive-mul y y-length x x-length))
            ((or (##fixnum.< x-width ##bignum.fft-mul-min-width)
                 (##fixnum.< ##bignum.fft-mul-max-width
                             (##fixnum.* y-length ##bignum.mdigit-width)))
             (karatsuba-mul x y))
            (else
             (fft-mul x y)))))

  ;; Certain decisions must be made for multiplication.
  ;; First, if both bignums are small, just do naive mul to avoid
  ;; further overhead.
  ;; This is done in the main body of ##bignum.*.
  ;; Second, if it would help to shift out low-order zeros of an
  ;; argument, do so.  That's done in the main body of ##bignum.*.
  ;; Finally, one must decide whether one is using naive mul, karatsuba, or fft.
  ;; This is done in mul.

  (define (low-bits-to-shift x)
    (let ((size (##integer-length x))
          (low-bits (##first-bit-set x)))
      (if (##fixnum.< size (##fixnum.+ low-bits low-bits))
          low-bits
          0)))

  (define (possibly-unnormalized-bignum-arithmetic-shift x bits)
    (if (##eq? bits 0)
        (if (##fixnum.= (##bignum.adigit-length x) 1)
            (##bignum.normalize! x)
            x)
        (##arithmetic-shift x bits)))

  (let ((x-length (##bignum.mdigit-length x))
        (y-length (##bignum.mdigit-length y)))
    (cond ((or (##not (use-fast-bignum-algorithms))
               (and (##fixnum.< x-length 50)
                    (##fixnum.< y-length 50)))
           (if (##fixnum.< x-length y-length)
               (naive-mul y y-length x x-length)
               (naive-mul x x-length y y-length)))
          ((##eq? x y)
           (let ((low-bits (low-bits-to-shift x)))
             (if (##eq? low-bits 0)
                 (mul x x-length x x-length)
                 (##arithmetic-shift
                  (##exact-int.square (##arithmetic-shift x (##fixnum.- low-bits)))
                  (##fixnum.+ low-bits low-bits)))))
          (else
           (let ((x-low-bits (low-bits-to-shift x))
                 (y-low-bits (low-bits-to-shift y)))
             (if (##eq? (##fixnum.+ x-low-bits y-low-bits) 0)
                 (if (##fixnum.< x-length y-length)
                     (mul x x-length y y-length)
                     (mul y y-length x x-length))
                 (##arithmetic-shift
                  (##* (possibly-unnormalized-bignum-arithmetic-shift x (##fixnum.- x-low-bits))
                       (possibly-unnormalized-bignum-arithmetic-shift y (##fixnum.- y-low-bits)))
                  (##fixnum.+ x-low-bits y-low-bits))))))))

(define-prim (##bignum.arithmetic-shift x shift)
  (let* ((digit-shift
          (if (##fixnum.< shift 0)
              (##fixnum.- (##fixnum.quotient (##fixnum.+ shift 1)
                                             ##bignum.adigit-width)
                          1)
              (##fixnum.quotient shift ##bignum.adigit-width)))
         (bit-shift
          (##fixnum.modulo shift ##bignum.adigit-width))
         (x-length
          (##bignum.adigit-length x))
         (result-length
          (##fixnum.+ (##fixnum.+ x-length digit-shift)
                      (if (##fixnum.zero? bit-shift) 0 1))))
    (if (##fixnum.< 0 result-length)

        (let ((result (##bignum.make result-length #f #f)))

          (##declare (not interrupts-enabled))

          (if (##fixnum.zero? bit-shift)
              (let ((smallest-i (##fixnum.max 0 digit-shift)))
                (let loop1 ((i (##fixnum.- result-length 1))
                            (j (##fixnum.- x-length 1)))
                  (if (##fixnum.< i smallest-i)
                      (##bignum.normalize! result)
                      (begin
                        (##bignum.adigit-copy! result i x j)
                        (loop1 (##fixnum.- i 1)
                               (##fixnum.- j 1))))))
              (let ((left-fill (if (##bignum.negative? x)
                                   ##bignum.adigit-ones
                                   ##bignum.adigit-zeros))
                    (i (##fixnum.- result-length 1))
                    (j (##fixnum.- x-length 1))
                    (divider bit-shift)
                    (smallest-i (##fixnum.max 0 (##fixnum.+ digit-shift 1))))
                (##bignum.adigit-cat! result i left-fill 0 x j divider)
                (let loop2 ((i (##fixnum.- i 1))
                            (j (##fixnum.- j 1)))
                  (if (##fixnum.< i smallest-i)
                      (begin
                        (if (##not (##fixnum.< i 0))
                            (##bignum.adigit-cat! result
                                                  i
                                                  x
                                                  (##fixnum.+ j 1)
                                                  ##bignum.adigit-zeros
                                                  0
                                                  divider))
                        (##bignum.normalize! result))
                      (begin
                        (##bignum.adigit-cat! result
                                              i
                                              x
                                              (##fixnum.+ j 1)
                                              x
                                              j
                                              divider)
                        (loop2 (##fixnum.- i 1)
                               (##fixnum.- j 1))))))))

        (if (##bignum.negative? x)
            -1
            0))))

;;; Bignum division.

(define ##reciprocal-cache (##make-table 0 #f #t #f ##eq?))

(define ##bignum.mdigit-width/2
  (##fixnum.quotient ##bignum.mdigit-width 2))

(define ##bignum.mdigit-base*16
  (##fixnum.* ##bignum.mdigit-base 16))

(define-prim (##bignum.div u v)

  ;; u is an unnormalized bignum, v is a normalized exact-int
  ;; 0 < v <= u

  (define (##exact-int.reciprocal v bits)

    ;; returns an approximation to the reciprocal of
    ;; .v1 v2 v3 ...
    ;; where v1 is the highest set bit of v; result is of the form
    ;; xx . xxxxxxxxxxxxxxxxxxx where there are bits + 1 bits to the
    ;; right of the binary point. The result is always <= 2; see Knuth, volume 2.

    (let ((cached-value (##table-ref ##reciprocal-cache v #f)))
      (if (and cached-value
               (##not (##fixnum.< (##cdr cached-value) bits)))
          cached-value
          (let ((v-length (##integer-length v)))

            (define (recip v bits)
              (cond ((and cached-value
                          (##not (##fixnum.< (##cdr cached-value) bits)))
                     cached-value)
                    ((##fixnum.<= bits ##bignum.mdigit-width/2)
                     (##cons (##fixnum.quotient
                              ##bignum.mdigit-base*16
                              (##arithmetic-shift
                               v
                               (##fixnum.- ##bignum.mdigit-width/2 -3 v-length)))
                             ##bignum.mdigit-width/2))
                    (else
                     (let* ((high-bits
                             (##fixnum.arithmetic-shift-right
                              (##fixnum.+ bits 1)
                              1))
                            (z-bits      ;; >= high-bits + 1 to right of point
                             (recip v high-bits))
                            (z           ;; high-bits + 1 to right of point
                             (##arithmetic-shift
                              (##car z-bits)
                              (##fixnum.- high-bits (##cdr z-bits))))
                            (v-bits      ;; bits + 3 to right of point
                             (##arithmetic-shift
                              v
                              (##fixnum.- (##fixnum.+ bits 3)
                                          v-length)))
                            (v*z*z       ;; 2 * high-bits + bits + 5 to right
                             (##* v-bits (##exact-int.square z)))
                            (two-z       ;; 2 * high-bits + bits + 5 to right
                             (##arithmetic-shift
                              z
                              (##fixnum.+ high-bits (##fixnum.+ bits 5))))
                            (temp
                             (##- two-z v*z*z))
                            (bits-to-shift
                             (##fixnum.+ 4 (##fixnum.+ high-bits high-bits)))
                            (shifted-temp
                             (##arithmetic-shift
                              temp
                              (##fixnum.- bits-to-shift))))
                       (if (##fixnum.< (##first-bit-set temp) bits-to-shift)
                           (##cons (##+ shifted-temp 1) bits)
                           (##cons shifted-temp bits))))))

            (let ((result (recip v bits)))
              (##table-set! ##reciprocal-cache v result)
              result)))))

  (define (naive-div u v)

    ;; u is a normalized bignum, v is an unnormalized bignum
    ;; v >= ##bignum.mdigit-base

    (let ((n
           (let loop1 ((i (##fixnum.- (##bignum.mdigit-length v) 1)))
             (if (##fixnum.< 0 (##bignum.mdigit-ref v i))
                 (##fixnum.+ i 1)
                 (loop1 (##fixnum.- i 1))))))
      (let ((normalizing-bit-shift
             (##fixnum.- ##bignum.mdigit-width
                         (##integer-length
                          (##bignum.mdigit-ref v (##fixnum.- n 1))))))
        (let ((u (##bignum.arithmetic-shift u normalizing-bit-shift))
              (v (##bignum.arithmetic-shift v normalizing-bit-shift)))
          (let ((q
                 (##bignum.make
                  (##fixnum.+ (##fixnum.- (##bignum.adigit-length u)
                                          (##bignum.adigit-length v))
                              2) ;; 1 is not always sufficient...
                  #f
                  #f))
                (v_n-1
                 (##bignum.mdigit-ref v (##fixnum.- n 1)))
                (v_n-2 (##bignum.mdigit-ref v (##fixnum.- n 2))))
            (let ((m
                   (let loop2 ((i (##fixnum.- (##bignum.mdigit-length u) 1)))
                     (let ((u_i (##bignum.mdigit-ref u i)))
                       (if (##fixnum.< 0 u_i)
                           (if (##not (##fixnum.< u_i v_n-1))
                               (##fixnum.- (##fixnum.+ i 1) n)
                               (##fixnum.- i n))
                           (loop2 (##fixnum.- i 1)))))))
              (let loop3 ((j m))
                (if (##not (##fixnum.< j 0))
                    (let ((q-hat
                           (let ((q-hat
                                  (##bignum.mdigit-quotient
                                   u
                                   (##fixnum.+ j n)
                                   v_n-1))
                                 (u_n+j-2
                                  (##bignum.mdigit-ref
                                   u
                                   (##fixnum.+ (##fixnum.- j 2) n)
                                   )))
                             (let ((r-hat
                                    (##bignum.mdigit-remainder
                                     u
                                     (##fixnum.+ j n)
                                     v_n-1
                                     q-hat)))
                               (if (or (##fixnum.= q-hat ##bignum.mdigit-base)
                                       (##bignum.mdigit-test?
                                        q-hat
                                        v_n-2
                                        r-hat
                                        u_n+j-2))
                                   (let ((q-hat (##fixnum.- q-hat 1))
                                         (r-hat (##fixnum.+ r-hat v_n-1)))
                                     (if (and (##fixnum.< r-hat
                                                          ##bignum.mdigit-base)
                                              (or (##fixnum.= q-hat
                                                              ##bignum.mdigit-base)
                                                  (##bignum.mdigit-test?
                                                   q-hat
                                                   v_n-2
                                                   r-hat
                                                   u_n+j-2)))
                                         (##fixnum.- q-hat 1)
                                         q-hat))
                                   q-hat)))))

                      (##declare (not interrupts-enabled))

                      (let loop4 ((i j)
                                  (k 0)
                                  (borrow 0))
                        (if (##fixnum.< k n)
                            (loop4 (##fixnum.+ i 2)
                                   (##fixnum.+ k 2)
                                   (##bignum.mdigit-div!
                                    u
                                    (##fixnum.+ i 1)
                                    v
                                    (##fixnum.+ k 1)
                                    q-hat
                                    (##bignum.mdigit-div!
                                     u
                                     i
                                     v
                                     k
                                     q-hat
                                     borrow)))
                            (let ((borrow
                                   (if (##fixnum.< n k)
                                       borrow
                                       (##bignum.mdigit-div!
                                        u
                                        i
                                        v
                                        k
                                        q-hat
                                        borrow))))
                              (if (##fixnum.< borrow 0)
                                  (let loop5 ((i j)
                                              (l 0)
                                              (carry 0))
                                    (if (##fixnum.< n l)
                                        (begin
                                          (##bignum.mdigit-set!
                                           q
                                           j
                                           (##fixnum.- q-hat 1))
                                          (loop3 (##fixnum.- j 1)))
                                        (loop5 (##fixnum.+ i 1)
                                               (##fixnum.+ l 1)
                                               (##bignum.mdigit-mul!
                                                u
                                                i
                                                v
                                                l
                                                1
                                                carry))))
                                  (begin
                                    (##bignum.mdigit-set! q j q-hat)
                                    (loop3 (##fixnum.- j 1))))))))
                    (##cons (##bignum.normalize! q)
                            (##arithmetic-shift
                             (##bignum.normalize! u)
                             (##fixnum.- normalizing-bit-shift)))))))))))

  (define (div-one u v)
    (let ((m
           (let loop6 ((i (##fixnum.- (##bignum.mdigit-length u) 1)))
             (if (##fixnum.< 0 (##bignum.mdigit-ref u i))
                 (##fixnum.+ i 1)
                 (loop6 (##fixnum.- i 1))))))
      (let ((work-u (##bignum.make 1 #f #f))
            (q (##bignum.make (##bignum.adigit-length u) #f #f)))

        (##declare (not interrupts-enabled))

        (let loop7 ((i m)
                    (r-hat 0))
          (##bignum.mdigit-set!
           work-u
           1
           r-hat)
          (##bignum.mdigit-set!
           work-u
           0
           (##bignum.mdigit-ref u (##fixnum.- i 1)))
          (let ((q-hat (##bignum.mdigit-quotient work-u 1 v)))
            (let ((r-hat (##bignum.mdigit-remainder work-u 1 v q-hat)))
              (##bignum.mdigit-set! q (##fixnum.- i 1) q-hat)
              (if (##fixnum.< 1 i)
                  (loop7 (##fixnum.- i 1)
                         r-hat)
                  (let ()
                    (##declare (interrupts-enabled))
                    (##cons (##bignum.normalize! q)
                            r-hat)))))))))

  (define (small-quotient-or-divisor-divide u v)
    ;; Here we do a quick check to catch most cases where the quotient will
    ;; be 1 and do a subtraction.  This comes up a lot in gcd calculations.
    ;; Otherwise, we just call naive-div.
    (let ((u-mlength (##bignum.mdigit-length u))
          (v-mlength (##bignum.mdigit-length v)))
      (if (and (##fixnum.= u-mlength v-mlength)
               (let loop ((i (##fixnum.- u-mlength 1)))
                 (let ((udigit (##bignum.mdigit-ref u i)))
                   (if (##eq? udigit 0)
                       (loop (##fixnum.- i 1))
                       (##fixnum.< udigit
                                   (##fixnum.arithmetic-shift-left
                                    (##bignum.mdigit-ref v i)
                                    1))))))
          (##cons 1 (##- u v))
          (naive-div u v))))

  (define (big-divide u v)

    ;; u and v are positive bignums

    (let ((v-length (##integer-length v))
          (v-first-bit-set (##first-bit-set v)))
      ;; first we check whether it may be beneficial to shift out
      ;; low-order zero bits of v
      (if (##fixnum.>= v-first-bit-set
                       (##fixnum.arithmetic-shift-right v-length 1))
          (let ((reduced-quotient
                 (##exact-int.div
                  (##bignum.arithmetic-shift u (##fixnum.- v-first-bit-set))
                  (##bignum.arithmetic-shift v (##fixnum.- v-first-bit-set))))
                (extra-remainder
                 (##extract-bit-field v-first-bit-set 0 u)))
            (##cons (##car reduced-quotient)
                    (##+ (##arithmetic-shift (##cdr reduced-quotient)
                                             v-first-bit-set)
                         extra-remainder)))
          (if (##fixnum.< v-length ##bignum.fft-mul-min-width)
              (small-quotient-or-divisor-divide u v)
              (let* ((u-length (##integer-length u))
                     (length-difference (##fixnum.- u-length v-length)))
                (if (##fixnum.< length-difference ##bignum.fft-mul-min-width)
                    (small-quotient-or-divisor-divide u v)
                    (let* ((z-bits (##exact-int.reciprocal v length-difference))
                           (z (##car z-bits))
                           (bits (##cdr z-bits)))
                      (let ((test-quotient
                             (##bignum.arithmetic-shift
                              (##* (##bignum.arithmetic-shift
                                    u
                                    (##fixnum.- length-difference
                                                (##fixnum.- u-length 2)))
                                   (##bignum.arithmetic-shift
                                    z
                                    (##fixnum.- length-difference bits)))
                              (##fixnum.- -3 length-difference))))
                        (let ((rem (##- u (##* test-quotient v))))
                          ;; I believe, and I haven't found any counterexamples in my tests
                          ;; to disprove it, that test-quotient can be off by at most +-1.
                          ;; I can't prove this, however, so we put in the following loops.

                          ;; Especially note that our reciprocal does not satisfy the
                          ;; error bounds in Knuth's volume 2 in perhaps a vain effort to
                          ;; save some computations. perhaps this should be fixed.  blah.

                          (cond ((##negative? rem)
                                 (let loop ((test-quotient test-quotient)
                                            (rem rem))
                                   (let ((test-quotient (##- test-quotient 1))
                                         (rem (##+ rem v)))
                                     (if (##negative? rem)
                                         (loop test-quotient rem)
                                         (##cons test-quotient rem)))))
                                ((##< rem v)
                                 (##cons test-quotient
                                         rem))
                                (else
                                 (let loop ((test-quotient test-quotient)
                                            (rem rem))
                                   (let ((test-quotient (##+ test-quotient 1))
                                         (rem (##- rem v)))
                                     (if (##< rem v)
                                         (##cons test-quotient rem)
                                         (loop test-quotient rem)))))))))))))))

  (if (##fixnum? v)
      (if (##fixnum.< v ##bignum.mdigit-base)
          (div-one u v)
          (begin
            ;; here it's probably not worth the extra cycles to check whether
            ;; a subtraction would be sufficient, i.e., we don't call
            ;; short-divisor-or-quotient-divide
            (naive-div u (##bignum.<-fixnum v))))
      (if (use-fast-bignum-algorithms)
          (big-divide u v)
          (naive-div u v))))

;;;----------------------------------------------------------------------------

;;; Exact integer operations
;;; ------------------------

(define-prim (##exact-int.*-expt2 x y)
  (if (##fixnum.negative? y)
      (##ratnum.normalize x (##arithmetic-shift 1 (##fixnum.- y)))
      (##arithmetic-shift x y)))

(define-prim (##exact-int.div x y)

  (define (big-quotient x y)
    (let* ((x-negative? (##negative? x))
           (abs-x (if x-negative? (##negate x) x))
           (y-negative? (##negative? y))
           (abs-y (if y-negative? (##negate y) y)))
      (if (##< abs-x abs-y)
          (##cons 0 x)

          ;; at least one of x and y is a bignum, so
          ;; here abs-x must be a bignum

          (let ((result (##bignum.div abs-x abs-y)))

            (if (##not (##eq? x-negative? y-negative?))
                (##set-car! result (##negate (##car result))))

            (if x-negative?
                (##set-cdr! result (##negate (##cdr result))))

            result))))

  (cond ((##eq? y 1)
         (##cons x 0))
        ((##eq? y -1)
         (##cons (##negate x) 0))
        ((##eq? x y)              ;; can come up in rational arithmetic
         (##cons 1 0))
        ((##fixnum? x)
         (if (##fixnum? y)
             (##cons (##fixnum.quotient x y) ;; note: y can't be -1
                     (##fixnum.remainder x y))
             ;; y is a bignum, x is a fixnum
             (if (##fixnum.< 1 (##bignum.adigit-length y))
                 ;; y has at least two adigits, so
                 ;; (abs y) > (abs x)
                 (##cons 0 x)
                 (big-quotient x y))))
        ((and (##bignum? y)
              (##fixnum.< 1 (##fixnum.- (##bignum.adigit-length y)
                                        (##bignum.adigit-length x))))
         ;; x and y are bignums, and y has at least two more adigits
         ;; than x, so (abs y) > (abs x)
         (##cons 0 x))
        (else
         (big-quotient x y))))

(define-prim (##exact-int.nth-root x y)
  (cond ((##eq? x 0)
         0)
        ((##eq? x 1)
         1)
        ((##eq? y 1)
         x)
        ((##eq? y 2)
         (##car (##exact-int.sqrt x)))
        ((##not (##fixnum? y))
         1)
        (else
         (let ((length (##integer-length x)))
           ;; (expt 2 (- length l 1)) <= x < (expt 2 length)
           (cond ((##fixnum.<= length y)
                  1)
                 ;; result is >= 2
                 ((##fixnum.<= length (##fixnum.* 2 y))
                  ;; result is < 4
                  (if (##< x (##expt 3 y))
                      2
                      3))
                 ((##fixnum.even? y)
                  (##exact-int.nth-root
                   (##car (##exact-int.sqrt x))
                   (##fixnum.arithmetic-shift-right y 1)))
                 (else
                  (let* ((length/y/2 ;; length/y/2 >= 1 because (< (* 2 y) length)
                          (##fixnum.arithmetic-shift-right
                           (##fixnum.quotient
                            (##fixnum.- length 1)
                            y)
                           1)))
                    (let ((init-g
                           (let* ((top-bits
                                   (##arithmetic-shift
                                    x
                                    (##fixnum.- (##fixnum.* length/y/2 y))))
                                  (nth-root-top-bits
                                   (##exact-int.nth-root top-bits y)))
                             (##arithmetic-shift
                              (##+ nth-root-top-bits 1)
                              length/y/2))))
                      (let loop ((g init-g))
                        (let* ((a (##expt g (##fixnum.- y 1)))
                               (b (##* a y))
                               (c (##* a (##fixnum.- y 1)))
                               (d (##quotient (##+ x (##* g c)) b)))
                          (let ((diff (##- d g)))
                            (cond ((##not (##negative? diff))
                                   g)
                                  ((##< diff -1)
                                   (loop d))
                                  (else
                                   ;; once the difference is one, it's more
                                   ;; efficient to just decrement until g^y <= x
                                   (let loop ((g d))
                                     (if (##not (##< x (##expt g y)))
                                         g
                                         (loop (##- g 1)))))))))))))))))

(define-prim (##integer-nth-root x y)

  (define (type-error-on-x)
    (##fail-check-exact-integer 1 integer-nth-root x y))

  (define (type-error-on-y)
    (##fail-check-exact-integer 2 integer-nth-root x y))

  (define (range-error-on-x)
    (##raise-range-exception 1 integer-nth-root x y))

  (define (range-error-on-y)
    (##raise-range-exception 2 integer-nth-root x y))

  (if (macro-exact-int? x)
      (if (macro-exact-int? y)
          (cond ((##negative? x)
                 (range-error-on-x))
                ((##positive? y)
                 (##exact-int.nth-root x y))
                (else
                 (range-error-on-y)))
          (type-error-on-y))
      (type-error-on-x)))

(define-prim (integer-nth-root x y)
  (macro-force-vars (x y)
    (##integer-nth-root x y)))

(define-prim (##exact-int.sqrt x)

  ;; Derived from the paper "Karatsuba Square Root" by Paul Zimmermann,
  ;; INRIA technical report RR-3805, 1999.  (Used in gmp 4.*)

  ;; Note that the statement of the theorem requires that
  ;; b/4 <= high-order digit of x < b which can be impossible when b is a
  ;; power of 2; the paper later notes that it is the lower bound that is
  ;; necessary, which we preserve.

  (if (and (##fixnum? x)
           ;; we require that
           ;; (##< (##flonum.sqrt (- (* y y) 1)) y) => #t
           ;; whenever x=y^2 is in this range.  Here we assume that we
           ;; have at least as much precision as IEEE double precision and
           ;; we round to nearest.
           (or (##not (##fixnum? 4294967296))          ;; 32-bit fixnums
               (##fixnum.<= x 4503599627370496)))      ;; 2^52
      (let* ((s (##flonum->fixnum (##flonum.sqrt (##flonum.<-fixnum x))))
             (r (##fixnum.- x (##fixnum.* s s))))
        (##cons s r))
      (let ((length/4
             (##fixnum.arithmetic-shift-right
              (##fixnum.+ (##integer-length x) 1)
              2)))
        (let* ((s-prime&r-prime
                (##exact-int.sqrt
                 (##arithmetic-shift
                  x
                  (##fixnum.- (##fixnum.arithmetic-shift-left length/4 1)))))
               (s-prime
                (##car s-prime&r-prime))
               (r-prime
                (##cdr s-prime&r-prime)))
          (let* ((qu
                  (##exact-int.div
                   (##+ (##arithmetic-shift r-prime length/4)
                        (##extract-bit-field length/4 length/4 x))
                   (##arithmetic-shift s-prime 1)))
                 (q
                  (##car qu))
                 (u
                  (##cdr qu)))
            (let ((s
                   (##+ (##arithmetic-shift s-prime length/4) q))
                  (r
                   (##- (##+ (##arithmetic-shift u length/4)
                             (##extract-bit-field length/4 0 x))
                        (##* q q))))
              (if (##negative? r)
                  (##cons (##- s 1)
                          (##+ r
                               (##- (##arithmetic-shift s 1) 1)))
                  (##cons s
                          r))))))))

(define-prim (##integer-sqrt x)

  (define (type-error)
    (##fail-check-exact-integer 1 integer-sqrt x))

  (define (range-error)
    (##raise-range-exception 1 integer-sqrt x))

  (if (macro-exact-int? x)
      (if (##negative? x)
          (range-error)
          (##car (##exact-int.sqrt x)))
      (type-error)))

(define-prim (integer-sqrt x)
  (macro-force-vars (x)
    (##integer-sqrt x)))

(define-prim (##exact-int.square n)
  (##* n n))

;;;----------------------------------------------------------------------------

;;; Ratnum operations
;;; -----------------

(define-prim (##ratnum.= x y)
  (and (##= (macro-ratnum-numerator x)
            (macro-ratnum-numerator y))
       (##= (macro-ratnum-denominator x)
            (macro-ratnum-denominator y))))

(define-prim (##ratnum.< x y)
  (##< (##* (macro-ratnum-numerator x)
            (macro-ratnum-denominator y))
       (##* (macro-ratnum-denominator x)
            (macro-ratnum-numerator y))))

(define-prim (##ratnum.+ x y)
  (let ((p (macro-ratnum-numerator x))
        (q (macro-ratnum-denominator x))
        (r (macro-ratnum-numerator y))
        (s (macro-ratnum-denominator y)))
    (let ((d1 (##gcd q s)))
      (if (##eq? d1 1)
          (macro-ratnum-make (##+ (##* p s)
                                  (##* r q))
                             (##* q s))
          (let* ((s-prime (##quotient s d1))
                 (t (##+ (##* p s-prime)
                         (##* r (##quotient q d1))))
                 (d2 (##gcd d1 t))
                 (num (##quotient t d2))
                 (den (##* (##quotient q d2)
                           s-prime)))
            (if (##eq? den 1)
                num
                (macro-ratnum-make num den)))))))

(define-prim (##ratnum.- x y)
  (let ((p (macro-ratnum-numerator x))
        (q (macro-ratnum-denominator x))
        (r (macro-ratnum-numerator y))
        (s (macro-ratnum-denominator y)))
    (let ((d1 (##gcd q s)))
      (if (##eq? d1 1)
          (macro-ratnum-make (##- (##* p s)
                                  (##* r q))
                             (##* q s))
          (let* ((s-prime (##quotient s d1))
                 (t (##- (##* p s-prime)
                         (##* r (##quotient q d1))))
                 (d2 (##gcd d1 t))
                 (num (##quotient t d2))
                 (den (##* (##quotient q d2)
                           s-prime)))
            (if (##eq? den 1)
                num
                (macro-ratnum-make num den)))))))

(define-prim (##ratnum.* x y)
  (let ((p (macro-ratnum-numerator x))
        (q (macro-ratnum-denominator x))
        (r (macro-ratnum-numerator y))
        (s (macro-ratnum-denominator y)))
    (if (##eq? x y)
        (macro-ratnum-make (##* p p) (##* q q))     ;; already in lowest form
        (let* ((gcd-ps (##gcd p s))
               (gcd-rq (##gcd r q))
               (num (##* (##quotient p gcd-ps) (##quotient r gcd-rq)))
               (den (##* (##quotient q gcd-rq) (##quotient s gcd-ps))))
          (if (##eq? den 1)
              num
              (macro-ratnum-make num den))))))

(define-prim (##ratnum./ x y)
  (let ((p (macro-ratnum-numerator x))
        (q (macro-ratnum-denominator x))
        (r (macro-ratnum-denominator y))
        (s (macro-ratnum-numerator y)))
    (if (##eq? x y)
        1
        (let* ((gcd-ps (##gcd p s))
               (gcd-rq (##gcd r q))
               (num (##* (##quotient p gcd-ps) (##quotient r gcd-rq)))
               (den (##* (##quotient q gcd-rq) (##quotient s gcd-ps))))
          (if (##negative? den)
              (if (##eq? den -1)
                  (##negate num)
                  (macro-ratnum-make (##negate num) (##negate den)))
              (if (##eq? den 1)
                  num
                  (macro-ratnum-make num den)))))))

(define-prim (##ratnum.normalize num den)
  (let* ((x (##gcd num den))
         (y (if (##negative? den) (##negate x) x))
         (num (##quotient num y))
         (den (##quotient den y)))
    (if (##eq? den 1)
        num
        (macro-ratnum-make num den))))

(define-prim (##ratnum.<-exact-int x)
  (macro-ratnum-make x 1))

(define-prim (##ratnum.round x #!optional (round-half-away-from-zero? #f))
  (let ((num (macro-ratnum-numerator x))
        (den (macro-ratnum-denominator x)))
    (if (##eq? den 2)
        (if round-half-away-from-zero?
            (##arithmetic-shift (##+ num (if (##positive? num) 1 -1)) -1)
            (##arithmetic-shift (##arithmetic-shift (##+ num 1) -2) 1))
        ;; here the ratnum cannot have fractional part = 1/2
        (##floor
         (##ratnum.normalize
          (##+ (##arithmetic-shift num 1) den)
          (##arithmetic-shift den 1))))))

;;;----------------------------------------------------------------------------

;;; Flonum operations
;;; -----------------

(##define-macro (define-prim-flonum form . special-body)
  (let ((body (if (null? special-body) form `(begin ,@special-body))))
    (cond ((= 1 (length (cdr form)))
           (let* ((name-fn (car form))
                  (name-param1 (cadr form)))
             `(define-prim ,form
                (macro-force-vars (,name-param1)
                  (macro-check-flonum
                    ,name-param1
                    1
                    ,form
                    ,body)))))
          ((= 2 (length (cdr form)))
           (let* ((name-fn (car form))
                  (name-param1 (cadr form))
                  (name-param2 (caddr form)))
             `(define-prim ,form
                (macro-force-vars (,name-param1 ,name-param2)
                  (macro-check-flonum
                    ,name-param1
                    1
                    ,form
                    (macro-check-flonum
                      ,name-param2
                      2
                      ,form
                      ,body))))))
          (else
           (error "define-prim-flonum supports only 1 or 2 parameter procedures")))))

(define-prim (flonum? obj)
  (##flonum? obj))

(define-prim-nary-bool (##fl= x y)
  #t
  #t
  (##fl= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fl= x y)
  #t
  #t
  (##fl= x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary-bool (##fl< x y)
  #t
  #t
  (##fl< x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fl< x y)
  #t
  #t
  (##fl< x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary-bool (##fl> x y)
  #t
  #t
  (##fl> x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fl> x y)
  #t
  #t
  (##fl> x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary-bool (##fl<= x y)
  #t
  #t
  (##fl<= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fl<= x y)
  #t
  #t
  (##fl<= x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary-bool (##fl>= x y)
  #t
  #t
  (##fl>= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (fl>= x y)
  #t
  #t
  (##fl>= x y)
  macro-force-vars
  macro-check-flonum)

(define-prim (##flinteger? x))

(define-prim-flonum (flinteger? x)
  (##flinteger? x))

(define-prim (##flzero? x))

(define-prim-flonum (flzero? x)
  (##flzero? x))

(define-prim (##flpositive? x))

(define-prim-flonum (flpositive? x)
  (##flpositive? x))

(define-prim (##flnegative? x))

(define-prim-flonum (flnegative? x)
  (##flnegative? x))

(define-prim (##flodd? x))

(define-prim-flonum (flodd? x)
  (##flodd? x))

(define-prim (##fleven? x))

(define-prim-flonum (fleven? x)
  (##fleven? x))

(define-prim (##flfinite? x))

(define-prim-flonum (flfinite? x)
  (##flfinite? x))

(define-prim (##flinfinite? x))

(define-prim-flonum (flinfinite? x)
  (##flinfinite? x))

(define-prim (##flnan? x))

(define-prim-flonum (flnan? x)
  (##flnan? x))

(define-prim-nary (##flmax x y)
  ()
  x
  (##flmax x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (flmax x y)
  ()
  x
  (##flmax x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary (##flmin x y)
  ()
  x
  (##flmin x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (flmin x y)
  ()
  x
  (##flmin x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary (##fl+ x y)
  (macro-inexact-+0)
  x
  (##fl+ x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fl+ x y)
  (macro-inexact-+0)
  x
  (##fl+ x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary (##fl* x y)
  (macro-inexact-+1)
  x
  (##fl* x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fl* x y)
  (macro-inexact-+1)
  x
  (##fl* x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary (##fl- x y)
  ()
  (##fl- x)
  (##fl- x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fl- x y)
  ()
  (##fl- x)
  (##fl- x y)
  macro-force-vars
  macro-check-flonum)

(define-prim-nary (##fl/ x y)
  ()
  (##fl/ x)
  (##fl/ x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (fl/ x y)
  ()
  (##fl/ x)
  (##fl/ x y)
  macro-force-vars
  macro-check-flonum)

(define-prim (##flabs x))

(define-prim-flonum (flabs x)
  (##flabs x))

(define-prim-flonum (flnumerator x)
  (cond ((##flzero? x)
         x)
        ((macro-flonum-rational? x)
         (##exact->inexact (##numerator (##flonum.inexact->exact x))))
        (else
         (##fail-check-rational 1 flnumerator x))))

(define-prim-flonum (fldenominator x)
  (if (macro-flonum-rational? x)
      (##exact->inexact (##denominator (##flonum.inexact->exact x)))
      (##fail-check-rational 1 fldenominator x)))

(define-prim (##flfloor x))

(define-prim-flonum (flfloor x)
  (if (##flfinite? x)
      (##flfloor x)
      (##fail-check-finite-real 1 flfloor x)))

(define-prim (##flceiling x))

(define-prim-flonum (flceiling x)
  (if (##flfinite? x)
      (##flceiling x)
      (##fail-check-finite-real 1 flceiling x)))

(define-prim (##fltruncate x))

(define-prim-flonum (fltruncate x)
  (if (##flfinite? x)
      (##fltruncate x)
      (##fail-check-finite-real 1 fltruncate x)))

(define-prim (##flround x))

(define-prim-flonum (flround x)
  (if (##flfinite? x)
      (##flround x)
      (##fail-check-finite-real 1 flround x)))

(define-prim (##flexp x))

(define-prim-flonum (flexp x)
  (##flexp x))

(define-prim (##fllog x))

(define-prim-flonum (fllog x)
  (if (or (##flnan? x)
          (##not (##flnegative?
                  (##flcopysign (macro-inexact-+1) x))))
      (##fllog x)
      (##raise-range-exception 1 fllog x)))

(define-prim (##flsin x))

(define-prim-flonum (flsin x)
  (##flsin x))

(define-prim (##flcos x))

(define-prim-flonum (flcos x)
  (##flcos x))

(define-prim (##fltan x))

(define-prim-flonum (fltan x)
  (##fltan x))

(define-prim (##flasin x))

(define-prim-flonum (flasin x)
  (if (and (##not (##fl< (macro-inexact-+1) x))
           (##not (##fl< x (macro-inexact--1))))
      (##flasin x)
      (##raise-range-exception 1 flasin x)))

(define-prim (##flacos x))

(define-prim-flonum (flacos x)
  (if (and (##not (##fl< (macro-inexact-+1) x))
           (##not (##fl< x (macro-inexact--1))))
      (##flacos x)
      (##raise-range-exception 1 flacos x)))

(define-prim (##flatan x #!optional (y (macro-absent-obj)))
  (if (##eq? y (macro-absent-obj))
      (##flatan x)
      (macro-check-flonum y 2 (##flatan x y)
        (##flatan x y))))

(define-prim (flatan x #!optional (y (macro-absent-obj)))
  (macro-force-vars (x y)
    (macro-check-flonum x 1 (flatan x y)
      (if (##eq? y (macro-absent-obj))
          (##flatan x)
          (macro-check-flonum y 2 (flatan x y)
            (##flatan x y))))))

(define-prim (##flexpt x y))

(define-prim-flonum (flexpt x y)
  (if (or (##not (##flnegative? x))
          (macro-flonum-int? y))
      (##flexpt x y)
      (##raise-range-exception 2 flexpt x y)))

(define-prim (##flsqrt x))

(define-prim-flonum (flsqrt x)
  (if (##not (##flnegative? x))
      (##flsqrt x)
      (##raise-range-exception 1 flsqrt x)))

(define-prim-fixnum (fixnum->flonum x)
  (##fixnum->flonum x))

(define-prim (##fl<-fx x))
(define-prim (##fl->fx x))
(define-prim (##fl<-fx-exact? x))

(define-prim (##flcopysign x y))


(define-prim (##flonum->fixnum x))
(define-prim (##fixnum->flonum x))
(define-prim (##fixnum->flonum-exact? x))



;;;;;;;;;;;;;;;;;;;;;;;;;; old procedures

(define-prim-nary-bool (##flonum.= x y)
  #t
  #t
  (##flonum.= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##flonum.< x y)
  #t
  #t
  (##flonum.< x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##flonum.> x y)
  #t
  #t
  (##flonum.> x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##flonum.<= x y)
  #t
  #t
  (##flonum.<= x y)
  macro-no-force
  macro-no-check)

(define-prim-nary-bool (##flonum.>= x y)
  #t
  #t
  (##flonum.>= x y)
  macro-no-force
  macro-no-check)

(define-prim (##flonum.integer? x))

(define-prim (##flonum.zero? x))

(define-prim (##flonum.positive? x))

(define-prim (##flonum.negative? x))

(define-prim (##flonum.odd? x))

(define-prim (##flonum.even? x))

(define-prim (##flonum.finite? x))

(define-prim (##flonum.infinite? x))

(define-prim (##flonum.nan? x))

(define-prim-nary (##flonum.max x y)
  ()
  x
  (##flonum.max x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##flonum.min x y)
  ()
  x
  (##flonum.min x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##flonum.+ x y)
  (macro-inexact-+0)
  x
  (##flonum.+ x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##flonum.* x y)
  (macro-inexact-+1)
  x
  (##flonum.* x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##flonum.- x y)
  ()
  (##flonum.- x)
  (##flonum.- x y)
  macro-no-force
  macro-no-check)

(define-prim-nary (##flonum./ x y)
  ()
  (##flonum./ x)
  (##flonum./ x y)
  macro-no-force
  macro-no-check)

(define-prim (##flonum.abs x))

(define-prim (##flonum.floor x))

(define-prim (##flonum.ceiling x))

(define-prim (##flonum.truncate x))

(define-prim (##flonum.round x))

(define-prim (##flonum.exp x))

(define-prim (##flonum.log x))

(define-prim (##flonum.sin x))

(define-prim (##flonum.cos x))

(define-prim (##flonum.tan x))

(define-prim (##flonum.asin x))

(define-prim (##flonum.acos x))

(define-prim (##flonum.atan x #!optional (y (macro-absent-obj)))
  (if (##eq? y (macro-absent-obj))
      (##flonum.atan x)
      (macro-check-flonum y 2 (##flonum.atan x y)
        (##flonum.atan x y))))

(define-prim (##flonum.expt x y))

(define-prim (##flonum.sqrt x))

(define-prim (##flonum.<-fixnum x))
(define-prim (##flonum.->fixnum x))
(define-prim (##flonum.<-fixnum-exact? x))

(define-prim (##flonum.copysign x y))

(define-prim (##flonum.<-ratnum x #!optional (nonzero-fractional-part? #f))
  (let* ((num (macro-ratnum-numerator x))
         (n (##abs num))
         (d (macro-ratnum-denominator x))
         (wn (##integer-length n)) ;; 2^(wn-1) <= n < 2^wn
         (wd (##integer-length d)) ;; 2^(wd-1) <= d < 2^wd
         (p (##fixnum.- wn wd)))

    (define (f1 sn sd)
      (if (##< sn sd) ;; n/(d*2^p) < 1 ?
          (f2 (##arithmetic-shift sn 1) sd (##fixnum.- p 1))
          (f2 sn sd p)))

    (define (f2 a b p)
      ;; 1 <= a/b < 2  and  n/d = (2^p*a)/b  and  n/d < 2^(p+1)
      (let* ((shift
              (##fixnum.min (macro-flonum-m-bits)
                            (##fixnum.- p (macro-flonum-e-min))))
             (normalized-result
              (##ratnum.normalize
                  (##arithmetic-shift a shift)
                  b))
             (abs-result
              (##flonum.*
               (##flonum.<-exact-int
                (if (##ratnum? normalized-result)
                    (##ratnum.round
                     normalized-result
                     nonzero-fractional-part?)
                    normalized-result))
               (##flonum.expt2 (##fixnum.- p shift)))))
        (if (##negative? num)
            (##flonum.copysign abs-result (macro-inexact--1))
            abs-result)))

    ;; 2^(p-1) <= n/d < 2^(p+1)
    ;; 1/2 <= n/(d*2^p) < 2  or equivalently  1/2 <= (n*2^-p)/d < 2

    (if (##fixnum.negative? p)
        (f1 (##arithmetic-shift n (##fixnum.- p)) d)
        (f1 n (##arithmetic-shift d p)))))

(define-prim (##flonum.<-exact-int x #!optional (nonzero-fractional-part? #f))

  (define (f1 x)
    (let* ((w ;; 2^(w-1) <= x < 2^w
            (##integer-length x))
           (p ;; 2^52 <= x/2^p < 2^53
            (##fixnum.- w (macro-flonum-m-bits-plus-1))))
      (if (##fixnum.< p 1)
          ;; it really should be an error here if
          ;; positive-fractional-part? is true because we can't
          ;; determine the value of the first discarded bit
          (f2 x)
          (let* ((q (##arithmetic-shift x (##fixnum.- p)))
                 (next-bit-index (##fixnum.- p 1)))
            (##flonum.*
             (##flonum.expt2 p)
             (f2 (if (and (##bit-set? next-bit-index x)
                          (or nonzero-fractional-part?
                              (##odd? q)
                              (##fixnum.< (##first-bit-set x)
                                          next-bit-index)))
                     (##+ q 1)
                     q)))))))

  (define (f2 x) ;; 0 <= x < 2^53
    (if (##fixnum? x)
        (##flonum.<-fixnum x)
        (let* ((x (if (##fixnum? x) (##bignum.<-fixnum x) x))
               (n (##bignum.mdigit-length x)))
          (let loop ((i (##fixnum.- n 1))
                     (result (macro-inexact-+0)))
            (if (##fixnum.< i 0)
                result
                (let ((mdigit (##bignum.mdigit-ref x i)))
                  (loop (##fixnum.- i 1)
                        (##flonum.+ (##flonum.* result
                                                ##bignum.inexact-mdigit-base)
                                    (##flonum.<-fixnum mdigit)))))))))

  (if (##fixnum? x)
      (##flonum.<-fixnum x)
      (if (##negative? x)
          (##flonum.copysign (f1 (##negate x)) (macro-inexact--1))
          (f1 x))))

(define-prim (##flonum.expt2 n)
  (cond ((##fixnum.zero? n)
         (macro-inexact-+1))
        ((##fixnum.negative? n)
         (##expt (macro-inexact-+1/2) (##fixnum.- n)))
        (else
         (##expt (macro-inexact-+2) n))))

(define-prim (##flonum.->exact-int x)
  (let loop1 ((z (##flonum.abs x))
              (n 1))
    (if (##flonum.< ##bignum.inexact-mdigit-base z)
        (loop1 (##flonum./ z ##bignum.inexact-mdigit-base)
               (##fixnum.+ n 1))
        (let loop2 ((result 0)
                    (z z)
                    (i n))
          (if (##fixnum.< 0 i)
              (let* ((inexact-floor-z
                      (##flonum.floor z))
                     (floor-z
                      (##flonum->fixnum inexact-floor-z))
                     (new-z
                      (##flonum.* (##flonum.- z inexact-floor-z)
                                  ##bignum.inexact-mdigit-base)))
                (loop2 (##+ floor-z
                            (##arithmetic-shift result ##bignum.mdigit-width))
                       new-z
                       (##fixnum.- i 1)))
              (if (##flonum.negative? x)
                  (##negate result)
                  result))))))

(define-prim (##flonum.->inexact-exponential-format x)

  (define (exp-form-pos x y i)
    (let ((i*2 (##fixnum.+ i i)))
      (let ((z (if (and (##not (##fixnum.< (macro-flonum-e-bias) i*2))
                        (##not (##flonum.< x y)))
                   (exp-form-pos x (##flonum.* y y) i*2)
                   (##vector x 0 1))))
        (let ((a (##vector-ref z 0)) (b (##vector-ref z 1)))
          (let ((i+b (##fixnum.+ i b)))
            (if (and (##not (##fixnum.< (macro-flonum-e-bias) i+b))
                     (##not (##flonum.< a y)))
                (begin
                  (##vector-set! z 0 (##flonum./ a y))
                  (##vector-set! z 1 i+b)))
            z)))))

  (define (exp-form-neg x y i)
    (let ((i*2 (##fixnum.+ i i)))
      (let ((z (if (and (##fixnum.< i*2 (macro-flonum-e-bias-minus-1))
                        (##flonum.< x y))
                   (exp-form-neg x (##flonum.* y y) i*2)
                   (##vector x 0 1))))
        (let ((a (##vector-ref z 0)) (b (##vector-ref z 1)))
          (let ((i+b (##fixnum.+ i b)))
            (if (and (##fixnum.< i+b (macro-flonum-e-bias-minus-1))
                     (##flonum.< a y))
                (begin
                  (##vector-set! z 0 (##flonum./ a y))
                  (##vector-set! z 1 i+b)))
            z)))))

  (define (exp-form x)
    (if (##flonum.< x (macro-inexact-+1))
        (let ((z (exp-form-neg x (macro-inexact-+1/2) 1)))
          (##vector-set! z 0 (##flonum.* (macro-inexact-+2) (##vector-ref z 0)))
          (##vector-set! z 1 (##fixnum.- -1 (##vector-ref z 1)))
          z)
        (exp-form-pos x (macro-inexact-+2) 1)))

  (if (##flonum.negative? (##flonum.copysign (macro-inexact-+1) x))
      (let ((z (exp-form (##flonum.copysign x (macro-inexact-+1)))))
        (##vector-set! z 2 -1)
        z)
      (exp-form x)))

(define-prim (##flonum.->exact-exponential-format x)
  (let ((z (##flonum.->inexact-exponential-format x)))
    (let ((y (##vector-ref z 0)))
      (if (##not (##flonum.< y (macro-inexact-+2))) ;; +inf.0 or +nan.0?
          (begin
            (if (##flonum.< (macro-inexact-+0) y)
                (##vector-set! z 0 (macro-flonum-+m-min))  ;; +inf.0
                (##vector-set! z 0 (macro-flonum-+m-max))) ;; +nan.0
            (##vector-set! z 1 (macro-flonum-e-bias-plus-1)))
          (##vector-set! z 0
                         (##flonum.->exact-int
                          (##flonum.* (##vector-ref z 0) (macro-flonum-m-min)))))
      (##vector-set! z 1 (##fixnum.- (##vector-ref z 1) (macro-flonum-m-bits)))
      z)))

(define-prim (##flonum.inexact->exact x)
  (let ((y (##flonum.->exact-exponential-format x)))
    (##exact-int.*-expt2
     (if (##fixnum.negative? (##vector-ref y 2))
         (##negate (##vector-ref y 0))
         (##vector-ref y 0))
     (##vector-ref y 1))))

(define-prim (##flonum.->ratnum x)
  (let ((y (##flonum.inexact->exact x)))
    (if (macro-exact-int? y)
        (##ratnum.<-exact-int y)
        y)))

(define-prim (##flonum.->ieee754-32 x)
  (##u32vector-ref (##f32vector x) 0))

(define-prim (##flonum.<-ieee754-32 n)
  (let ((x (##u32vector n)))
    (##f32vector-ref x 0)))

(define-prim (##flonum.->ieee754-64 x)
  (##u64vector-ref x 0))

(define-prim (##flonum.<-ieee754-64 n)
  (let ((x (##u64vector n)))
    (##subtype-set! x (macro-subtype-flonum))
    x))

;;;----------------------------------------------------------------------------

;;; Cpxnum operations
;;; -----------------

(define-prim (##cpxnum.= x y)
  (and (##= (macro-cpxnum-real x) (macro-cpxnum-real y))
       (##= (macro-cpxnum-imag x) (macro-cpxnum-imag y))))

(define-prim (##cpxnum.+ x y)
  (let ((a (macro-cpxnum-real x)) (b (macro-cpxnum-imag x))
        (c (macro-cpxnum-real y)) (d (macro-cpxnum-imag y)))
    (##make-rectangular (##+ a c) (##+ b d))))

(define-prim (##cpxnum.* x y)
  (let ((a (macro-cpxnum-real x)) (b (macro-cpxnum-imag x))
        (c (macro-cpxnum-real y)) (d (macro-cpxnum-imag y)))
    (##make-rectangular (##- (##* a c) (##* b d)) (##+ (##* a d) (##* b c)))))

(define-prim (##cpxnum.- x y)
  (let ((a (macro-cpxnum-real x)) (b (macro-cpxnum-imag x))
        (c (macro-cpxnum-real y)) (d (macro-cpxnum-imag y)))
    (##make-rectangular (##- a c) (##- b d))))

(define-prim (##cpxnum./ x y)

  (define (basic/ a b c d q)
    (##make-rectangular (##/ (##+ (##* a c) (##* b d)) q)
                        (##/ (##- (##* b c) (##* a d)) q)))

  (let ((a (macro-cpxnum-real x)) (b (macro-cpxnum-imag x))
        (c (macro-cpxnum-real y)) (d (macro-cpxnum-imag y)))
    (cond ((##eq? d 0)
           ;; A normalized cpxnum can't have an imaginary part that is
           ;; exact 0 but it is possible that ##cpxnum./ receives a
           ;; nonnormalized cpxnum as x or y when it is called from ##/.
           (##make-rectangular (##/ a c)
                               (##/ b c)))
          ((##eq? c 0)
           (##make-rectangular (##/ b d)
                               (##negate (##/ a d))))
          ((and (##exact? c) (##exact? d))
           (basic/ a b c d (##+ (##* c c) (##* d d))))
          (else
           ;; just coerce everything to inexact and move on
           (let ((inexact-c (##exact->inexact c))
                 (inexact-d (##exact->inexact d)))
             (if (and (##flonum.finite? inexact-c)
                      (##flonum.finite? inexact-d))
                 (let ((q
                        (##flonum.+ (##flonum.* inexact-c inexact-c)
                                    (##flonum.* inexact-d inexact-d))))
                   (cond ((##not (##flonum.finite? q))
                          (let ((a
                                 (if (##flonum? a)
                                     (##flonum.* a (macro-inexact-scale-down))
                                     (##* a (macro-scale-down))))
                                (b
                                 (if (##flonum? b)
                                     (##flonum.* b (macro-inexact-scale-down))
                                     (##* b (macro-scale-down))))
                                (inexact-c
                                 (##flonum.* inexact-c
                                             (macro-inexact-scale-down)))
                                (inexact-d
                                 (##flonum.* inexact-d
                                             (macro-inexact-scale-down))))
                            (basic/ a
                                    b
                                    inexact-c
                                    inexact-d
                                    (##flonum.+
                                     (##flonum.* inexact-c inexact-c)
                                     (##flonum.* inexact-d inexact-d)))))
                         ((##flonum.< q (macro-flonum-min-normal))
                          (let ((a
                                 (if (##flonum? a)
                                     (##flonum.* a (macro-inexact-scale-up))
                                     (##* a (macro-scale-up))))
                                (b
                                 (if (##flonum? b)
                                     (##flonum.* b (macro-inexact-scale-up))
                                     (##* b (macro-scale-up))))
                                (inexact-c
                                 (##flonum.* inexact-c
                                             (macro-inexact-scale-up)))
                                (inexact-d
                                 (##flonum.* inexact-d
                                             (macro-inexact-scale-up))))
                            (basic/ a
                                    b
                                    inexact-c
                                    inexact-d
                                    (##flonum.+
                                     (##flonum.* inexact-c inexact-c)
                                     (##flonum.* inexact-d inexact-d)))))
                         (else
                          (basic/ a b inexact-c inexact-d q))))
                 (cond ((##flonum.= inexact-c (macro-inexact-+inf))
                        (basic/ a
                                b
                                (macro-inexact-+0)
                                (if (##flonum.nan? inexact-d)
                                    inexact-d
                                    (##flonum.copysign (macro-inexact-+0)
                                                       inexact-d))
                                (macro-inexact-+1)))
                       ((##flonum.= inexact-c (macro-inexact--inf))
                        (basic/ a
                                b
                                (macro-inexact--0)
                                (if (##flonum.nan? inexact-d)
                                    inexact-d
                                    (##flonum.copysign (macro-inexact-+0)
                                                       inexact-d))
                                (macro-inexact-+1)))
                       ((##flonum.nan? inexact-c)
                        (cond ((##flonum.= inexact-d (macro-inexact-+inf))
                               (basic/ a
                                       b
                                       inexact-c
                                       (macro-inexact-+0)
                                       (macro-inexact-+1)))
                              ((##flonum.= inexact-d (macro-inexact--inf))
                               (basic/ a
                                       b
                                       inexact-c
                                       (macro-inexact--0)
                                       (macro-inexact-+1)))
                              ((##flonum.nan? inexact-d)
                               (basic/ a
                                       b
                                       inexact-c
                                       inexact-d
                                       (macro-inexact-+1)))
                              (else
                               (basic/ a
                                       b
                                       inexact-c
                                       (macro-inexact-+nan)
                                       (macro-inexact-+1)))))
                       (else
                        ;; finite inexact-c
                        (cond ((##flonum.nan? inexact-d)
                               (basic/ a
                                       b
                                       (macro-inexact-+nan)
                                       inexact-d
                                       (macro-inexact-+1)))
                              (else
                               ;; inexact-d is +inf.0 or -inf.0
                               (basic/ a
                                       b
                                       (##flonum.copysign (macro-inexact-+0)
                                                          inexact-c)
                                       (##flonum.copysign (macro-inexact-+0)
                                                          inexact-d)
                                       (macro-inexact-+1))))))))))))

(define-prim (##cpxnum.<-noncpxnum x)
  (macro-cpxnum-make x 0))

;;;----------------------------------------------------------------------------

;;; Pseudo-random number generation, compatible with srfi-27.

;;; This code is based on Pierre Lecuyer's MRG32K3A generator.

(define-type random-source
  id: 1b002758-f900-4e96-be5e-fa407e331fc0
  implementer: implement-type-random-source
  constructor: macro-make-random-source
  type-exhibitor: macro-type-random-source
  macros:
  prefix: macro-
  opaque:

  (state-ref         unprintable: read-only:)
  (state-set!        unprintable: read-only:)
  (randomize!        unprintable: read-only:)
  (pseudo-randomize! unprintable: read-only:)
  (make-integers     unprintable: read-only:)
  (make-reals        unprintable: read-only:)
  (make-u8vectors    unprintable: read-only:)
  (make-f64vectors   unprintable: read-only:)
  )

(define-check-type random-source
  (macro-type-random-source)
  macro-random-source?)

(implement-type-random-source)
(implement-check-type-random-source)

(define-prim (##make-random-source-mrg32k3a)

  (##define-macro (macro-w)
    65536)

  (##define-macro (macro-w^2-mod-m1)
    209)

  (##define-macro (macro-w^2-mod-m2)
    22853)

  (##define-macro (macro-m1)
    4294967087) ;; (- (expt (macro-w) 2) (macro-w^2-mod-m1))

  (##define-macro (macro-m1-inexact)
    4294967087.0) ;; (exact->inexact (macro-m1))

  (##define-macro (macro-m1-plus-1-inexact)
    4294967088.0) ;; (exact->inexact (+ (macro-m1) 1))

  (##define-macro (macro-inv-m1-plus-1-inexact)
    2.328306549295728e-10) ;; (exact->inexact (/ (+ (macro-m1) 1)))

  (##define-macro (macro-m1-minus-1)
    4294967086) ;; (- (macro-m1) 1)

  (##define-macro (macro-k)
    28)

  (##define-macro (macro-2^k)
    268435456) ;; (expt 2 (macro-k))

  (##define-macro (macro-2^k-inexact)
    268435456.0) ;; (exact->inexact (expt 2 (macro-k)))

  (##define-macro (macro-inv-2^k-inexact)
    3.725290298461914e-9) ;; (exact->inexact (/ (expt 2 (macro-k))))

  (##define-macro (macro-2^53-k-inexact)
    33554432.0) ;; (exact->inexact (expt 2 (- 53 (macro-k))))

  (##define-macro (macro-m1-div-2^k-inexact)
    15.0) ;; (exact->inexact (quotient (macro-m1) (expt 2 (macro-k))))

  (##define-macro (macro-m1-div-2^k-times-2^k-inexact)
    4026531840.0) ;; (exact->inexact (* (quotient (macro-m1) (expt 2 (macro-k))) (expt 2 (macro-k))))

  (##define-macro (macro-m2)
    4294944443) ;; (- (expt (macro-w) 2) (macro-w^2-mod-m2))

  (##define-macro (macro-m2-inexact)
    4294944443.0) ;; (exact->inexact (macro-m2))

  (##define-macro (macro-m2-minus-1)
    4294944442) ;; (- (macro-m2) 1)

  (define (pack-state a b c d e f)
    (f64vector
     (##flonum.<-exact-int a)
     (##flonum.<-exact-int b)
     (##flonum.<-exact-int c)
     (##flonum.<-exact-int d)
     (##flonum.<-exact-int e)
     (##flonum.<-exact-int f)
     (macro-inexact-+0) ;; where the result of advance-state! is put
     (macro-inexact-+0) ;; q in rand-fixnum32
     (macro-inexact-+0) ;; qn in rand-fixnum32
     ))

  (define (unpack-state state)
    (vector
     (##flonum.->exact-int (f64vector-ref state 0))
     (##flonum.->exact-int (f64vector-ref state 1))
     (##flonum.->exact-int (f64vector-ref state 2))
     (##flonum.->exact-int (f64vector-ref state 3))
     (##flonum.->exact-int (f64vector-ref state 4))
     (##flonum.->exact-int (f64vector-ref state 5))))

  (let ((state ;; initial state is 0 3 6 9 12 15 of A^(2^4), see below
         (pack-state
          1062452522
          2961816100
          342112271
          2854655037
          3321940838
          3542344109)))

    (define (state-ref)
      (unpack-state state))

    (define (state-set! rs new-state)

      (define (integer-in-range? x m)
        (and (macro-exact-int? x)
             (not (negative? x))
             (< x m)))

      (or (and (vector? new-state)
               (fx= (vector-length new-state) 6)
               (let ((a (vector-ref new-state 0))
                     (b (vector-ref new-state 1))
                     (c (vector-ref new-state 2))
                     (d (vector-ref new-state 3))
                     (e (vector-ref new-state 4))
                     (f (vector-ref new-state 5)))
                 (and (integer-in-range? a (macro-m1))
                      (integer-in-range? b (macro-m1))
                      (integer-in-range? c (macro-m1))
                      (integer-in-range? d (macro-m2))
                      (integer-in-range? e (macro-m2))
                      (integer-in-range? f (macro-m2))
                      (not (and (eqv? a 0) (eqv? b 0) (eqv? c 0)))
                      (not (and (eqv? d 0) (eqv? e 0) (eqv? f 0)))
                      (begin
                        (set! state
                              (pack-state a b c d e f))
                        (void)))))
          (##raise-type-exception
           2
           'random-source-state
           random-source-state-set!
           (list rs new-state))))

    (define (randomize!)

      (define (random-fixnum-from-time)
        (let ((v (f64vector (macro-inexact-+0))))
          (##get-current-time! v)
          (let ((x (f64vector-ref v 0)))
            (##flonum->fixnum
             (fl* 536870912.0 ;; (expt 2.0 29)
                  (fl- x (flfloor x)))))))

      (define seed16
        (random-fixnum-from-time))

      (define (simple-random16)
        (let ((r (bitwise-and seed16 65535)))
          (set! seed16
                (+ (* 30903 r)
                   (arithmetic-shift seed16 -16)))
          r))

      (define (simple-random32)
        (+ (arithmetic-shift (simple-random16) 16)
           (simple-random16)))

      ;; perturb the state randomly

      (let ((s (unpack-state state)))
        (set! state
              (pack-state
               (+ 1
                  (modulo (+ (vector-ref s 0)
                             (simple-random32))
                          (macro-m1-minus-1)))
               (modulo (+ (vector-ref s 1)
                          (simple-random32))
                       (macro-m1))
               (modulo (+ (vector-ref s 2)
                          (simple-random32))
                       (macro-m1))
               (+ 1
                  (modulo (+ (vector-ref s 3)
                             (simple-random32))
                          (macro-m2-minus-1)))
               (modulo (+ (vector-ref s 4)
                          (simple-random32))
                       (macro-m2))
               (modulo (+ (vector-ref s 5)
                          (simple-random32))
                       (macro-m2))))
        (void)))

    (define (pseudo-randomize! i j)

      (define (mult A B) ;; A*B

        (define (lc i0 i1 i2 j0 j1 j2 m)
          (modulo (+ (* (vector-ref A i0)
                        (vector-ref B j0))
                     (+ (* (vector-ref A i1)
                           (vector-ref B j1))
                        (* (vector-ref A i2)
                           (vector-ref B j2))))
                  m))

        (vector
         (lc  0  1  2   0  3  6  (macro-m1))
         (lc  0  1  2   1  4  7  (macro-m1))
         (lc  0  1  2   2  5  8  (macro-m1))
         (lc  3  4  5   0  3  6  (macro-m1))
         (lc  3  4  5   1  4  7  (macro-m1))
         (lc  3  4  5   2  5  8  (macro-m1))
         (lc  6  7  8   0  3  6  (macro-m1))
         (lc  6  7  8   1  4  7  (macro-m1))
         (lc  6  7  8   2  5  8  (macro-m1))
         (lc  9 10 11   9 12 15  (macro-m2))
         (lc  9 10 11  10 13 16  (macro-m2))
         (lc  9 10 11  11 14 17  (macro-m2))
         (lc 12 13 14   9 12 15  (macro-m2))
         (lc 12 13 14  10 13 16  (macro-m2))
         (lc 12 13 14  11 14 17  (macro-m2))
         (lc 15 16 17   9 12 15  (macro-m2))
         (lc 15 16 17  10 13 16  (macro-m2))
         (lc 15 16 17  11 14 17  (macro-m2))))

      (define (power A e) ;; A^e
        (cond ((eq? e 0)
               identity)
              ((eq? e 1)
               A)
              ((even? e)
               (power (mult A A) (arithmetic-shift e -1)))
              (else
               (mult (power A (- e 1)) A))))

      (define identity
        '#(         1           0           0
                                0           1           0
                                0           0           1
                                1           0           0
                                0           1           0
                                0           0           1))

      (define A ;; primary MRG32k3a equations
        '#(         0     1403580  4294156359
                          1           0           0
                          0           1           0
                          527612           0  4293573854
                          1           0           0
                          0           1           0))

      (define A^2^127 ;; A^(2^127)
        '#(1230515664   986791581  1988835001
                        3580155704  1230515664   226153695
                        949770784  3580155704  2427906178
                        2093834863    32183930  2824425944
                        1022607788  1464411153    32183930
                        1610723613   277697599  1464411153))

      (define A^2^76 ;; A^(2^76)
        '#(  69195019  3528743235  3672091415
                       1871391091    69195019  3672831523
                       4127413238  1871391091    82758667
                       3708466080  4292754251  3859662829
                       3889917532  1511326704  4292754251
                       1610795712  3759209742  1511326704))

      (define A^2^4 ;; A^(2^4)
        '#(1062452522   340793741  2955879160
                        2961816100  1062452522   387300998
                        342112271  2961816100   736416029
                        2854655037  1817134745  3493477402
                        3321940838   818368950  1817134745
                        3542344109  3790774567   818368950))

      (let ((M ;; M = A^(2^4 + i*2^127 + j*2^76)
             (mult A^2^4
                   (mult (power A^2^127 i)
                         (power A^2^76 j)))))
        (set! state
              (pack-state
               (vector-ref M 0)
               (vector-ref M 3)
               (vector-ref M 6)
               (vector-ref M 9)
               (vector-ref M 12)
               (vector-ref M 15)))
        (void)))

    (define (advance-state!)
      (##declare (not interrupts-enabled))
      (let* ((state state)
             (x10
              (fl- (fl* 1403580.0 (f64vector-ref state 1))
                   (fl* 810728.0 (f64vector-ref state 2))))
             (y10
              (fl- x10
                   (fl* (flfloor (fl/ x10 (macro-m1-inexact)))
                        (macro-m1-inexact))))
             (x20
              (fl- (fl* 527612.0 (f64vector-ref state 3))
                   (fl* 1370589.0 (f64vector-ref state 5))))
             (y20
              (fl- x20
                   (fl* (flfloor (fl/ x20 (macro-m2-inexact)))
                        (macro-m2-inexact)))))
        (f64vector-set! state 5 (f64vector-ref state 4))
        (f64vector-set! state 4 (f64vector-ref state 3))
        (f64vector-set! state 3 y20)
        (f64vector-set! state 2 (f64vector-ref state 1))
        (f64vector-set! state 1 (f64vector-ref state 0))
        (f64vector-set! state 0 y10)
        (if (fl< y10 y20)
            (f64vector-set! state 6 (fl+ (macro-m1-inexact)
                                         (fl- (f64vector-ref state 0)
                                              (f64vector-ref state 3))))
            (f64vector-set! state 6 (fl- (f64vector-ref state 0)
                                         (f64vector-ref state 3))))))

    (define (make-integers)

      (define (random-integer range)

        (define (type-error)
          (##fail-check-exact-integer 1 random-integer range))

        (define (range-error)
          (##raise-range-exception 1 random-integer range))

        (macro-force-vars (range)
          (cond ((fixnum? range)
                 (if (fxpositive? range)
                     (if (fx< (macro-max-fixnum32) range)
                         (rand-integer range)
                         (rand-fixnum32 range))
                     (range-error)))
                ((##bignum? range)
                 (if (##bignum.negative? range)
                     (range-error)
                     (rand-integer range)))
                (else
                 (type-error)))))

      random-integer)

    (define (rand-integer range)

      ;; constants for computing fixnum approximation of inverse of range

      (define size 14)
      (define 2^2*size 268435456)

      (let ((len (integer-length range)))
        (if (fx= (fx- len 1) ;; check if range is a power of 2
                 (first-bit-set range))
            (rand-integer-2^ (fx- len 1))
            (let* ((inv
                    (fxquotient
                     2^2*size
                     (fx+ 1
                          (extract-bit-field size (fx- len size) range))))
                   (range2
                    (* range inv)))
              (let loop ()
                (let ((r (rand-integer-2^ (fx+ len size))))
                  (if (< r range2)
                      (quotient r inv)
                      (loop))))))))

    (define (rand-integer-2^ w)

      (define (rand w s)
        (cond ((fx< w (macro-k))
               (fxand (rand-fixnum32-2^k)
                      (fx- (fxarithmetic-shift-left 1 w) 1)))
              ((fx= w (macro-k))
               (rand-fixnum32-2^k))
              (else
               (let ((s/2 (fxarithmetic-shift-right s 1)))
                 (if (fx< s w)
                     (+ (rand s s/2)
                        (arithmetic-shift (rand (fx- w s) s/2) s))
                     (rand w s/2))))))

      (define (split w s)
        (let ((s*2 (fx* 2 s)))
          (if (fx< s*2 w)
              (split w s*2)
              s)))

      (rand w (split w (macro-k))))

    (define (rand-fixnum32-2^k)
      (##declare (not interrupts-enabled))
      (let loop ()
        (advance-state!)
        (if (fl< (f64vector-ref state 6)
                 (macro-m1-div-2^k-times-2^k-inexact))
            (##flonum->fixnum
             (fl/ (f64vector-ref state 6)
                  (macro-m1-div-2^k-inexact)))
            (loop))))

    (define (rand-fixnum32 range) ;; range is a fixnum32
      (##declare (not interrupts-enabled))
      (let* ((a (fixnum->flonum range))
             (b (flfloor (fl/ (macro-m1-inexact) a))))
        (f64vector-set! state 7 b)
        (f64vector-set! state 8 (fl* a b)))
      (let loop ()
        (advance-state!)
        (if (fl< (f64vector-ref state 6)
                 (f64vector-ref state 8))
            (##flonum->fixnum
             (fl/ (f64vector-ref state 6)
                  (f64vector-ref state 7)))
            (loop))))

    (define (make-reals precision)
      (if (fl< precision (macro-inv-m1-plus-1-inexact))
          (lambda ()
            (let loop ((r (fixnum->flonum (rand-fixnum32-2^k)))
                       (d (macro-inv-2^k-inexact)))
              (if (fl< r (macro-flonum-+m-max-plus-1-inexact))
                  (loop (fl+ (fl* r (macro-2^k-inexact))
                             (fixnum->flonum (rand-fixnum32-2^k)))
                        (fl* d (macro-inv-2^k-inexact)))
                  (fl* r d))))
          (lambda ()
            (##declare (not interrupts-enabled))
            (advance-state!)
            (fl* (fl+ (macro-inexact-+1) (f64vector-ref state 6))
                 (macro-inv-m1-plus-1-inexact)))))

    (define (make-u8vectors)

      (define (random-u8vector len)
        (macro-force-vars (len)
          (macro-check-index len 1 (random-u8vector len)
            (let ((u8vect (##make-u8vector len 0)))
              (let loop ((i (fx- len 1)))
                (if (fx< i 0)
                    u8vect
                    (begin
                      (##u8vector-set! u8vect i (rand-fixnum32 256))
                      (loop (fx- i 1)))))))))

      random-u8vector)

    (define (make-f64vectors precision)
      (if (fl< precision (macro-inv-m1-plus-1-inexact))
          (let ((make-real (make-reals precision)))
            (lambda (len)
              (macro-force-vars (len)
                (macro-check-index len 1 (random-f64vector len)
                  (let ((f64vect (##make-f64vector len 0.)))
                    (let loop ((i (fx- len 1)))
                      (if (fx< i 0)
                          f64vect
                          (begin
                            (##f64vector-set! f64vect i (make-real))
                            (loop (fx- i 1))))))))))
          (lambda (len)
            (macro-force-vars (len)
              (macro-check-index len 1 (random-f64vector len)
                (let ((f64vect (##make-f64vector len 0.)))
                  (let loop ((i (fx- len 1)))
                    (if (fx< i 0)
                        f64vect
                        (let ()
                          (##declare (not interrupts-enabled))
                          (advance-state!)
                          (##f64vector-set! f64vect i (fl* (fl+ (macro-inexact-+1)
                                                                (f64vector-ref state 6))
                                                           (macro-inv-m1-plus-1-inexact)))
                          (loop (fx- i 1)))))))))))

    (macro-make-random-source
     state-ref
     state-set!
     randomize!
     pseudo-randomize!
     make-integers
     make-reals
     make-u8vectors
     make-f64vectors)))

(define-prim (make-random-source)
  (##make-random-source-mrg32k3a))

(define-prim (random-source? obj)
  (macro-force-vars (obj)
    (macro-random-source? obj)))

(define-prim (##random-source-state-ref rs)
  ((macro-random-source-state-ref rs)))

(define-prim (random-source-state-ref rs)
  (macro-force-vars (rs)
    (macro-check-random-source rs 1 (random-source-state-ref rs)
      (##random-source-state-ref rs))))

(define-prim (##random-source-state-set! rs new-state)
  ((macro-random-source-state-set! rs) rs new-state))

(define-prim (random-source-state-set! rs new-state)
  (macro-force-vars (rs new-state)
    (macro-check-random-source rs 1 (random-source-state-set! rs new-state)
      (##random-source-state-set! rs new-state))))

(define-prim (##random-source-randomize! rs)
  ((macro-random-source-randomize! rs)))

(define-prim (random-source-randomize! rs)
  (macro-force-vars (rs)
    (macro-check-random-source rs 1 (random-source-randomize! rs)
      (##random-source-randomize! rs))))

(define-prim (##random-source-pseudo-randomize! rs i j)
  ((macro-random-source-pseudo-randomize! rs) i j))

(define-prim (random-source-pseudo-randomize! rs i j)
  (macro-force-vars (rs i j)
    (macro-check-random-source rs 1 (random-source-pseudo-randomize! rs i j)
      (if (not (macro-exact-int? i))
          (##fail-check-exact-integer 2 random-source-pseudo-randomize! rs i j)
          (if (not (macro-exact-int? j))
              (##fail-check-exact-integer 3 random-source-pseudo-randomize! rs i j)
              (if (negative? i)
                  (##raise-range-exception 2 random-source-pseudo-randomize! rs i j)
                  (if (negative? j)
                      (##raise-range-exception 3 random-source-pseudo-randomize! rs i j)
                      (##random-source-pseudo-randomize! rs i j))))))))

(define-prim (##random-source-make-integers rs)
  ((macro-random-source-make-integers rs)))

(define-prim (random-source-make-integers rs)
  (macro-force-vars (rs)
    (macro-check-random-source rs 1 (random-source-make-integers rs)
      (##random-source-make-integers rs))))

(define-prim (##random-source-make-reals rs #!optional (p (macro-absent-obj)))
  ((macro-random-source-make-reals rs)
   (if (eq? p (macro-absent-obj))
       (macro-inexact-+1)
       p)))

(define-prim (random-source-make-reals rs #!optional (p (macro-absent-obj)))
  (macro-force-vars (rs p)
    (macro-check-random-source rs 1 (random-source-make-reals rs p)
      (if (eq? p (macro-absent-obj))
          (##random-source-make-reals rs)
          (if (rational? p)
              (let ((precision (macro-real->inexact p)))
                (if (and (fl< (macro-inexact-+0) precision)
                         (fl< precision (macro-inexact-+1)))
                    (##random-source-make-reals rs precision)
                    (##raise-range-exception 2 random-source-make-reals rs p)))
              (##fail-check-finite-real 2 random-source-make-reals rs p))))))

(define-prim (##random-source-make-f64vectors rs #!optional (p (macro-absent-obj)))
  ((macro-random-source-make-f64vectors rs)
   (if (eq? p (macro-absent-obj))
       (macro-inexact-+1)
       p)))

(define-prim (random-source-make-f64vectors rs #!optional (p (macro-absent-obj)))
  (macro-force-vars (rs p)
    (macro-check-random-source rs 1 (random-source-make-f64vectors rs p)
      (if (eq? p (macro-absent-obj))
          (##random-source-make-f64vectors rs)
          (if (rational? p)
              (let ((precision (macro-real->inexact p)))
                (if (and (fl< (macro-inexact-+0) precision)
                         (fl< precision (macro-inexact-+1)))
                    (##random-source-make-f64vectors rs precision)
                    (##raise-range-exception 2 random-source-make-f64vectors rs p)))
              (##fail-check-finite-real 2 random-source-make-f64vectors rs p))))))

(define-prim (##random-source-make-u8vectors rs)
  ((macro-random-source-make-u8vectors rs)))

(define-prim (random-source-make-u8vectors rs)
  (macro-force-vars (rs)
    (macro-check-random-source rs 1 (random-source-make-u8vectors rs)
      (##random-source-make-u8vectors rs))))

(define default-random-source #f)
(set! default-random-source (##make-random-source-mrg32k3a))

(define random-integer
  (##random-source-make-integers default-random-source))

(define random-real
  (##random-source-make-reals default-random-source))

(define random-u8vector
  (##random-source-make-u8vectors default-random-source))

(define random-f64vector
  (##random-source-make-f64vectors default-random-source))

;;;============================================================================
