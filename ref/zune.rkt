#lang s-exp rosette

(require rosette/query/debug rosette/lib/tools/render rosette/lib/meta/meta)

(current-bitwidth 32)

(define unroll (make-parameter 3))

(define (leap-year? year)
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
  
(define/debug (zune-safety days)
  (define year 1980)
  (while (> days 365)
   (define old-days days)
   (if (leap-year? year)
       (when (> days 366)
         (set! days (- days 366))
         (set! year (add1 year)))
       (begin
         (set! days (- days 365))
         (set! year (add1 year))))
   (assert (< old-days days)))
  year)

(define (find-bug)
  (define-symbolic days number?)
  (parameterize ([unroll 1])
    (verify (zune-safety days))))


(define (localize-bug [days 366])
  (parameterize ([unroll 1])
    (render
     (debug [boolean? number?]
            (zune-safety days)))))
        
