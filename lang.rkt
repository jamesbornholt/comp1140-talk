#lang s-exp rosette

; boring language crap
(require (rename-in (only-in rosette/base/num @>=)))
(require rosette/query/debug rosette/lib/tools/render)
(provide (all-defined-out) define/debug)

(current-bitwidth 32)

(define (^ x y)
  (bitwise-xor x y))

(define (& x y)
  (bitwise-and x y))

(define (>= x y)
  (if (@>= x y) 1 0))

(define (verify? expr)
  (define S
   (with-handlers ([exn:fail? (const (unsat))])
     (verify (assert expr))))
  (cond [(sat? S) S]
        [else     #t]))

(define-syntax-rule (debug-expr expr)
  (render (debug [number?] (assert expr))))

(define-syntax-rule (debug-function expr)
  (render (debug [boolean? number?] expr)))

(define unroll (make-parameter 1))

(define (IsLeapYear year)
  (and (= (remainder year 4) 0)
       (not (= (remainder year 100) 0))
       (not (= (remainder year 400) 0))))

(define-syntax-rule (while test body ...)
  (local [(define (loop bound)
            (define condition test)
            (if (protect (and (<= bound 0) (or (not condition) (union? condition) (term? condition))))
                (assert (not condition))
                (when condition
                  body ...
                  (loop (protect (- bound 1))))))]
    (loop (protect (unroll)))))