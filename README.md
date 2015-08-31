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

(print 5)
(print "hello world")

; int x = 5;
(define x 5)
; System.out.println(x);
(print x)
; > 5

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

## Verifying a trivial function

```racket
; clear everything

#lang s-exp rosette
(require "lang.rkt")

(define (foo x)
  (if (> x 5)
      10
      2))
```

What is this function allowed to return? Only `10` or `2`. But how would we check that that's actually true? The easy way is to just try it on every input.

```racket
; void test_foo(int N) {
;   for (int x = -N; x < N; x++) {
;     if ( !(foo(x) == 10 || foo(x) == 2) ) {
;       System.out.println(x);
;     }
;   }
; }
(define (test-foo N)
  (for ([x (in-range (- N) N)])
    (when (not (or (= (foo x) 10) (= (foo x) 2)))
      (print x)(newline))))

(time (test-foo 10))
```

This is good. We can see that it does check the right thing -- let's change the function to return `1` instead:

```racket
(define (foo x)
  (if (> x 5)
      10
      1))
```

And as expected, we see the numbers on which foo returns neither `10` nor `2`. Let's change `foo` back, so the test passes.

We can also keep incrementing `N` to get more confidence.

But there's a problem with this testing strategy: no matter how large I make `N`, we can always write a broken version of `foo` that still passes the test. All I have to do it make the conditional larger than `N`:

```racket
(define (foo x)
  (if (> x 10000)
      10
      1))
```

Now `(test-foo 10000)` still passes, but `(foo 10001)` returns `1`, which shouldn't be allowed. What we really want is to avoid having to choose `N`.

There's another problem: this test is very expensive. What if we write this function instead:

```racket
(define (foo2 x y z)
  (if (and (> x 5) (> y 5) (> z 5))
      10
      2))
```

Again, it can only return 10 or 2. Let's test it:

```racket
(define (test-foo2 N)
  (for ([x (in-range (- N) N)])
    (for ([y (in-range (- N) N)])
      (for ([z (in-range (- N) N)])
        (when (not (or (= (foo2 x y z) 10) (= (foo2 x y z) 2)))
          (print x y z)(newline))))))

(time (test-foo2 10))
```

So far, so good, but let's make `N` a little bigger: `(time (test-foo2 40))`. It takes about 7 seconds. Uh-oh. What about `50`? 14 seconds. This doesn't look like it's going to scale.

So let's go back to `foo`.
The goal of this loop is to find an `x` that breaks the rule we have about `foo`, that it can only return `10` or `2`.
What we can do instead is pose this as a question: *is there some `x` which breaks the rule?*.

To do this, we'll introduce what's called a *symbolic variable*, and tell Racket we want this variable to be a number:

```racket
(define-symbolic x number?)
```

Why do we have to tell Racket it's a number? Because we haven't given it a value.

Now we're going to ask to "verify" our rule: that `(foo x)` is either `10` or `2`. Because `x` is "symbolic", what this means is that it stands for *every possible number*.

```racket
(verify? (or (= (foo x) 10) (= (foo x) 2)))
```

When we run this, Racket is going to check whether this rule is true for *every* value of `x`. So, before I run it -- is it true? Is there any value of `x` that breaks the rule? Nope! So let's give it a shot.

```racket
> (verify? (or (= (foo x) 10) (= (foo x) 2)))
#t
```

It returned true, which means this rule is true. Great! But let's check to make sure it actually does what we wanted: what if we make the rule wrong?

```racket
> (verify? (or (= (foo x) 10) (= (foo x) 1)))
(model
 [x 4])
```

What this output says is, here is a value of `x` for which the rule *does not hold*. And indeed:

```racket
> (foo 4)
2
```

`2` is neither `10` or `1`. And we can see that regardless of how big we make the conditional, it will still figure it out, without us changing the test:

```racket
(define (foo x)
  (if (> x 10000000)
      10
      2))
```

Cool! Finally, let's do the same thing to foo2:

```racket
(define-symbolic x number?)
(define-symbolic y number?)
(define-symbolic z number?)

(verify? (or (= (foo2 x y z) 10) (= (foo2 x y z) 2)))
```

Notice how no matter how large I make the numbers in `foo2`, it still answers quickly. Remember that we couldn't make get much past `50` when we were testing by hand. So this is pretty cool.

## Testing `max`

blah




## max C

make
./max 100000000
