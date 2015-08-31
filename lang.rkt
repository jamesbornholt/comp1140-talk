#lang s-exp rosette

; boring language crap
(require (rename-in (only-in rosette/base/num @>=)))
(provide (all-defined-out))

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
