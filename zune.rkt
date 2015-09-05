#lang s-exp rosette

(require rosette/query/debug rosette/lib/tools/render)
(provide (all-defined-out) define/debug)

(current-bitwidth 32)

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

(define-syntax-rule (verify? expr)
  (verify expr))

(define-syntax-rule (+= lhs rhs)
  (set! lhs (+ lhs rhs)))
(define-syntax-rule (-= lhs rhs)
  (set! lhs (- lhs rhs)))