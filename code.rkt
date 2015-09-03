#lang s-exp rosette
(require "lang.rkt")

(define (max1 x y)
  (if (> x y) x y))

(define (test-max1 N)
  (for ([x N])
    (for ([y N])
      (define m (max1 x y))
      (when (or (and (not (= m x)) (not (= m y)))
                (not (>= m x))
                (not (>= m y)))
        (print x)(print y)))))

(test-max1 10)