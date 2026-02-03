/-
  Test library for mutation testing
  Contains functions with test coverage that should catch mutations
-/

-- Arithmetic functions
def double (n : Nat) : Nat := n + n
def triple (n : Nat) : Nat := n + n + n
def square (n : Nat) : Nat := n * n
def isPositive (n : Nat) : Bool := n > 0
def isZero (n : Nat) : Bool := n == 0

-- Comparison functions
def maximum (a b : Nat) : Nat := if a > b then a else b
def minimum (a b : Nat) : Nat := if a < b then a else b
def clamp (val lo hi : Nat) : Nat :=
  if val < lo then lo
  else if val > hi then hi
  else val

-- Boolean logic
def implies (a b : Bool) : Bool := !a || b
def exclusiveOr (a b : Bool) : Bool := (a || b) && !(a && b)
def nand (a b : Bool) : Bool := !(a && b)

-- List operations
def sumList (xs : List Nat) : Nat := xs.foldl (· + ·) 0
def productList (xs : List Nat) : Nat := xs.foldl (· * ·) 1
def allPositive (xs : List Nat) : Bool := xs.all (· > 0)
def anyZero (xs : List Nat) : Bool := xs.any (· == 0)

-- Factorial
def factorial : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

-- Fibonacci
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib n + fib (n + 1)

-- Abs for integers
def absInt (n : Int) : Int := if n < 0 then -n else n

-- Sign function
def sign (n : Int) : Int :=
  if n < 0 then -1
  else if n > 0 then 1
  else 0

-- Even/Odd
def isEven (n : Nat) : Bool := n % 2 == 0
def isOdd (n : Nat) : Bool := n % 2 != 0

-- Divisibility
def divides (d n : Nat) : Bool := d != 0 && n % d == 0

/-
  ## Tests - these should catch mutations
-/

-- Arithmetic tests
#guard double 0 == 0
#guard double 1 == 2
#guard double 5 == 10
#guard triple 0 == 0
#guard triple 1 == 3
#guard triple 4 == 12
#guard square 0 == 0
#guard square 1 == 1
#guard square 5 == 25
#guard isPositive 0 == false
#guard isPositive 1 == true
#guard isPositive 100 == true
#guard isZero 0 == true
#guard isZero 1 == false

-- Comparison tests
#guard maximum 3 5 == 5
#guard maximum 5 3 == 5
#guard maximum 4 4 == 4
#guard minimum 3 5 == 3
#guard minimum 5 3 == 3
#guard minimum 4 4 == 4
#guard clamp 5 0 10 == 5
#guard clamp 0 5 10 == 5
#guard clamp 15 0 10 == 10

-- Boolean logic tests
#guard implies false false == true
#guard implies false true == true
#guard implies true false == false
#guard implies true true == true
#guard exclusiveOr false false == false
#guard exclusiveOr false true == true
#guard exclusiveOr true false == true
#guard exclusiveOr true true == false
#guard nand false false == true
#guard nand false true == true
#guard nand true false == true
#guard nand true true == false

-- List tests
#guard sumList [] == 0
#guard sumList [1] == 1
#guard sumList [1, 2, 3] == 6
#guard productList [] == 1
#guard productList [2] == 2
#guard productList [2, 3, 4] == 24
#guard allPositive [] == true
#guard allPositive [1, 2, 3] == true
#guard allPositive [1, 0, 3] == false
#guard anyZero [] == false
#guard anyZero [1, 2, 3] == false
#guard anyZero [1, 0, 3] == true

-- Factorial tests
#guard factorial 0 == 1
#guard factorial 1 == 1
#guard factorial 2 == 2
#guard factorial 3 == 6
#guard factorial 5 == 120

-- Fibonacci tests
#guard fib 0 == 0
#guard fib 1 == 1
#guard fib 2 == 1
#guard fib 3 == 2
#guard fib 4 == 3
#guard fib 5 == 5
#guard fib 10 == 55

-- Abs tests
#guard absInt 5 == 5
#guard absInt (-5) == 5
#guard absInt 0 == 0

-- Sign tests
#guard sign 5 == 1
#guard sign (-5) == (-1)
#guard sign 0 == 0

-- Even/Odd tests
#guard isEven 0 == true
#guard isEven 1 == false
#guard isEven 2 == true
#guard isEven 7 == false
#guard isOdd 0 == false
#guard isOdd 1 == true
#guard isOdd 2 == false
#guard isOdd 7 == true

-- Divisibility tests
#guard divides 2 4 == true
#guard divides 2 5 == false
#guard divides 3 9 == true
#guard divides 0 5 == false
#guard divides 5 0 == true
