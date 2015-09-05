#lang s-exp rosette
(require "zune.rkt")

(define/debug (getcurrentyear days)
  (define year 1980)
  (while (> days 365)
   (define old_days days)
   (if (IsLeapYear year)
       (if (> days 366)
           (begin
             (-= days 366)
             (+= year 1))
           (when (= days 366)
             (-= days 366)))
       (begin
         (-= days 365)
         (+= year 1)))
   (assert (< days old_days)))
  year)

(define-symbolic days number?)
(verify? (getcurrentyear days))
;(debug-function (getcurrentyear 366))