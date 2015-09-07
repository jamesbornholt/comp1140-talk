# Program Verification

These are notes for a lecture I gave about program verification using [Rosette](http://homes.cs.washington.edu/~emina/rosette/) to a class of freshman CS students.

You probably want to [watch the video](http://homes.cs.washington.edu/~emina/rosette/) instead of reading these.

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

(define z (>= y 6))
; > z
; #t

(define a (if z 
              "yes"
              "no"))

; clear everything

; public int foo(int x) {
;   if (x >= 5) {
;     return 10;
;   } else {
;     return 2;
;   }    
; }
(define (foo x)
  (if (>= x 5)
      10
      2))

(foo 5)
(foo 12)
(foo -5)

```

## Testing `max`

Let's look at a kinda boring function, that returns the max of two numbers.
First in Java, so you can see what we're going to do.

```java
int max1(int x, int y) {
  if (x >= y) {
    return x;
  } else {
    return y;
  }
}
```
```racket
(define (max1 x y)
  (if (>= x y) x y))
```

This is a pretty simple function, so I'm fairly confident it's right. But to be sure, let's think about what we expect `max` to do.
What are some rules for the output of this function?

1. Its output should be either `x` or `y`
2. Its output should be greater than or equal to both `x` and `y`

Let's formalise these rules by writing them down:

```racket
; output should be either x or y
(or (= (max1 x y) x) (= (max1 x y) y))
; output should be >= x
(>= (max1 x y) x)
; output should be >= y
(>= (max1 x y) y)
```

We want all of these rules to hold, so we'll `and` them together.

But we have a problem: what are the values of `x` and `y`? We didn't define them.

One thing we could do is to wrap this whole thing inside a `test`:

```racket
(define (test-max1 x y)
  ...)
```

This returns `#t` if `max1` follows the rules on a particular `x` and `y`. But to be sure the function is correct, we'd have to test all possible `x` and `y`. There are a lot of them!

Instead, we're going to do this by verification. So let's go back to the rule:

```racket
; output should be either x or y
(or (= (max1 x y) x) (= (max1 x y) y))
; output should be >= x
(>= (max1 x y) x)
; output should be >= y
(>= (max1 x y) y)
```

The idea of verification is to pose the problem as a question: *do there exist values for `x` and `y` that break these rules?*.

To pose this question, we're going to introduce something called a "symbolic variable" for `x` and `y`:

```racket
(define-symbolic x number?)
(define-symbolic y number?)
```

What this definition does is says "there are variables `x` and `y`, but I don't know their value yet -- we're going to figure it out later on".
Notice that this time we had to tell Racket the type of `x` and `y`, because we didn't give them values.

Now what we're going to do is ask Rosette to "verify" our rule:

```racket
(verify?
  (and
  ; output should be either x or y
  (or (= (max1 x y) x) (= (max1 x y) y))
  ; output should be >= x
  (>= (max1 x y) x)
  ; output should be >= y
  (>= (max1 x y) y)
  ))
```

When we run this, Rosette is going to check whether this rule is true for *every* value of `x` and `y`. So, before I run it: is it true? Is there any value of `x` and `y` that breaks the rule? Nope! Let's give it a shot:

```racket
#t
```

The verify function returned true, which means this rule is true. There are *no* values of `x` and `y` that break the rule. Rosette tried *every possible value*.

Just to be sure, let's try breaking *max*:

```racket
(define (max1 x y)
  (if (>= x y) x x))
```

Now it always returns `x`. If we run `verify?` again, it's going to return something different:

```racket
(model
 [x 0]
 [y 2])
```

Instead of returning `true`, it's returned something called a "model". What this output means is: here is a value for `x` and `y` for which the rule *does not hold*.
And indeed:

```racket
> (max1 0 2)
0
```

which is clearly wrong.

### A more interesting `max`

So I lied: this is kind of a boring function. But I'm going to write another version of max, first in Java, then in Racket.

```racket
; int max(int x, int y) {
;   return y ^ -(y <= x ? 1 : 0) & (x ^ (y <= x ? 1 : 0));
; }
(define (max2 x y)
  (^ y (& (- (<= y x)) (^ x (<= y x)))))
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
  (^ y (& (- (<= y x)) (^ x (<= y x)))))
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
  (^ y (& (- (<= y x)) (^ x y))))
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


