#lang s-exp rosette

(require "lang.rkt")

(define (max1 x y)
  (if (> x y) x y))

(define (max2 x y)
  (^ y (& (- (>= x y)) (^ x (>= x y)))))

(define (max3 x y)
  (^ y (& (- (>= x y)) (^ x y))))




(define-symbolic x y number?)
(verify? (= (max2 x y) (max1 x y)))
(verify? (= (max3 x y) (max1 x y)))




(define (foo x)
  (if (= x 5) x 0))

(verify? (or (= (foo x) 5) (= (foo x) 0)))
(verify? (or (= (foo x) 6) (= (foo x) 0)))