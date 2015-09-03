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

## Testing `max`

Let's look at a kinda boring function, that returns the max of two numbers.
First in Java, so you can see what we're going to do.

```java
int max1(int x, int y) {
  if (x > y) {
    return x;
  } else {
    return y;
  }
}
```
```racket
(define (max1 x y)
  (if (> x y) x y))
```

This is a pretty simple function, so I'm fairly confident it's right. But to be sure, let's think about what we expect `max` to do.
What are some rules for the output of this function?

1. Its output should be either `x` or `y`
2. Its output should be greater than or equal to both `x` and `y`

We might test that these rules hold by just trying them for lots of values of x and y:

```java
void test_max1(int N) {
  for (int x = 0; x < N; x++) {
    for (int y = 0; y < N; y++) {
      int m = max1(x, y);
      if ( (m != x && m != y)
           || !(m >= x) || !(m >= y) ) {
        System.out.println(x + "," + y);
      }
    }
  }
}
```
```racket
(define (test-max1 N)
  (for ([x N])
    (for ([y N])
      (define m (max1 x y))
      (when (or (and (not (= m x)) (not (= m y)))
                (not (>= m x))
                (not (>= m y)))
        (print x)(print y)))))
```

and we can run this test:

```racket
(test-max1 10)
```

Let's check if those rules hold:

```racket
(define-symbolic x number?)
(define-symbolic y number?)

(verify? (and (or (= (max1 x y) x) (= (max1 x y) y))
              (>= (max1 x y) x)
              (>= (max1 x y) y)))
; > #t
```

Great! And just to be sure, we could change, for example, `(= (max1 x y) y)` to something incorrect, and see a counterexample.

So I lied: this is kind of a boring function. But I'm going to write another version of max, first in Java, then in Racket.

```racket
; int max(int x, int y) {
;   return y ^ -(x >= y ? 1 : 0) & (x ^ (x >= y ? 1 : 0));
; }
(define (max2 x y)
  (^ y (& (- (>= x y)) (^ x (>= x y)))))
```

This one's a little crazier. But hopefully it still does the same thing! We'll talk in a second about why we might want this version. But first, is it correct? Any guesses? Let's find out.

We're going to verify this one a little bit differently. We're pretty confident that `max1` is correct, so we're going to verify a new rule: that `max1` and `max2` do the same thing:

```racket
(verify? (= (max1 x y) (max2 x y)))
; > (model
;    [x -1]
;    [y -2])
```

Uh-oh! This rule isn't true, and we have a concrete example on which it fails. Let's check it out:

```racket
> (max1 -1 -2)
-1
> (max2 -1 -2)
0
```

That's bad!

One of the cool things about verification is that it's also extremely useful for debugging: it teases out all the corner cases. We're going to use our verifier to help us debug `max2` and figure out what went wrong.

To do so, we first need to tell the verifier that we want to debug `max2`:

```racket
(define/debug (max2 x y)
  (^ y (& (- (>= x y)) (^ x (>= x y)))))
```

Then we're going to debug the case we just found:

```racket
(debug-expr (= (max1 -1 -2) (max2 -1 -2)))
```

What this says is: "Here is a case where this rule does *not* hold. Figure out why."

When we run it, it highlights some code. What the verifier is telling us is that the bug is somewhere in the highlighted code. Changing any of the faded out code won't fix the bug.

I don't expect you to be able to spot the bug, since it's pretty subtle, so I'm just going to fix it for you:

```racket
(define (max3 x y)
  (^ y (& (- (>= x y)) (^ x y))))
```

Let's try verifying this one against `max1`, which we're pretty sure is correct:

```racket
(verify? (= (max1 x y) (max3 x y)))
; #t
```

Great!

Now, I promised I would show you why this version of `max` might be better than the original one. Does anyone want to guess why?

Let's take a look. I wrote them both in C, and I'm going to run them now:

```bash
cd max/
make
./max
# N: 100000000
# with `if`: 0.426s
#   no `if`: 0.213s
```

So it turns out the version without an if statement---the crazy version we wrote---is about twice as fast as the version with an if statement. This is because it doesn't use a branch. Kind of cool.

## Fixing the Zune bug

Now let's go back to the Zune bug from earlier. First the Java version:

```java
int GetCurrentYear(int days) {
    int year = 1980;
    while (days > 365) {
        if (IsLeapYear(year)) {
            if (days > 366) {
                days -= 366;
                year += 1;
            }
        }
        else {
            days -= 365;
            year += 1;
        }
    }
    return year;
}
```

Now let's write it in Racket:

```racket
(define (getcurrentyear days)
  (define year 1980)
  (while (> days 365)
   (if (IsLeapYear year)
       (when (> days 366)
         (set! days (- days 366))
         (set! year (add1 year)))
       (begin
         (set! days (- days 365))
         (set! year (add1 year)))))
  year)
```

We'd like to check that this code doesn't go into an infinite loop. Notice that so long as `days` decreases on every loop iteration, it will eventually break the loop, because eventually `days` will be less than or equal to `365`.

So we'd like to verify that days decreases on every loop iteration. Let's write a rule stating that.

```racket
(define (getcurrentyear days)
  (define year 1980)
  (while (> days 365)
   (define old-days days)
   (if (IsLeapYear year)
       (when (> days 366)
         (set! days (- days 366))
         (set! year (add1 year)))
       (begin
         (set! days (- days 365))
         (set! year (add1 year))))
   (assert (< days old-days)))
  year)
```

We are saying that we expect days to get smaller on every loop iteration.
Let's verify if this rule holds:

```racket
(define-symbolic days number?)
(verify (getcurrentyear days))
; (model
;  [days 366])
```

And surprise, if we delete that rule we just inserted, we'll see that this goes into an infinite loop:

```racket
(getcurrentyear 366)
```

So there's definitely a problem, and we found it without writing any tests. But how can we fix it? We'll do the same thing we did before: ask the verifier to tell us where to look.

First we need to swap `define` to `define/debug`:

```racket
(define/debug (getcurrentyear days)
  ...)
```

And now we'll ask the verifier where to look:

```racket
(debug-function (getcurrentyear 366))
```

Remember to save the file before running.
We'll see some highlighted code. Now does anyone want to tell me which of these expressions I should change?

It actually turns out to be pretty complicated. The problem here is that the algorithm is wrong. To fix it we need to add another case to the conditional:

```racket
       (if (> days 366)
           (begin
             (set! days (- days 366))
             (set! year (add1 year)))
           (when (= days 366)
             (set! days (- days 366))))
```

or in Java terms:

```java
            if (days > 366) {
                days -= 366;
                year += 1;
            }
            else if (days == 366) {
              days -= 366;
            }
```

Now we can run the verifier again:

```racket
(verify (getcurrentyear days))
; (model
;  [days 1711276148])
```

Uh-oh! It's still broken. This bug is a different one that I don't have time to explain, but it only happens about 400,000 years from now, so we're probably fine.


