## Zune

* Released in 2006
* Interesting thing happened on 31 Dec 2008: every Zune froze
* The solution: wait for the battery to discharge, then wait until tomorrow
* Why 2008? Why 31 Dec 2008?
* The cause: this function, that given the number of days since 1980, returns the year
    - On the last day of a leap year, it goes into an infinite loop
    - We're going to try to verify this function, and discover this bug

## Intro to Racket

* Racket is a programming language
    - Descends from Scheme, which descends from Lisp, which was one of the first programming languages, invented by John McCarthy
    - Interesting link to Java: Scheme was invented at MIT by Gerry Sussman and his then-PhD student Guy Steele, who later went on to be a major contributor to Java
* Racket has some similarities to Haskell, but is also very different to both Haskell and Java
    - The most obvious difference: its syntax is very different
    - Also: unlike Java and Haskell, Racket is *dynamically typed*: you won't see any types like you have to write in those languages
* These features make it a very easy language to *extend* with new features
    - Unlike in Haskell or Java where you'd have to hack the compiler
    - We'll be writing in a language called Rosette, which extends Racket with features for verification and synthesis
    - But it looks exactly like regular Racket

### Basic syntax

Start a new Racket file, `code.rkt`.

```racket
; > 5
; 5
; > "hello world"
; "hello world"

; int x = 5;
(define x 5)
; System.out.println(x);
(print x)
; > 5

; String y = "hello world";
(define y "hello world")
; System.out.println(y);
(print y)

; clear everything

; int x = 5;
(define x 5)
; int y = x + 2;
(define y (+ x 2))
; > x
; 5
; > y
; 7

(define z (> y 6))
; > z
; #t

(define a (if z 
              "yes"
              "no"))

; clear everything

; public int foo(int x) {
;   if (x > 5) {
;     return 10;
;   } else {
;     return 2;
;   }    
; }
(define (foo x)
  (if (> x 5)
      10
      2))

(foo 5)
(foo 12)
(foo -5)

; everything we've done so far is just a function
(> x 5)  ; a function called >
(print x)  ; a function called print
(define x 5)  ; a function called define

```

## max C

make
./max 100000000
