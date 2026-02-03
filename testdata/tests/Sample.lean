/-
  Sample file for testing LeanMutator

  This file contains various constructs that should be detected by mutation operators.
-/

-- Boolean literals (should be mutated by boolean-flip)
def alwaysTrue : Bool := true
def alwaysFalse : Bool := false

-- Arithmetic operations (should be mutated by arithmetic operators)
def add (a b : Nat) : Nat := a + b
def subtract (a b : Nat) : Nat := a - b
def multiply (a b : Nat) : Nat := a * b
def divide (a b : Nat) : Nat := a / b

-- Comparison operations (should be mutated by comparison operators)
def isEqual (a b : Nat) : Bool := a == b
def isNotEqual (a b : Nat) : Bool := a != b
def isLessThan (a b : Nat) : Bool := a < b
def isLessOrEqual (a b : Nat) : Bool := a <= b
def isGreaterThan (a b : Nat) : Bool := a > b
def isGreaterOrEqual (a b : Nat) : Bool := a >= b

-- Boolean operations (should be mutated by boolean-and-or)
def bothTrue (a b : Bool) : Bool := a && b
def eitherTrue (a b : Bool) : Bool := a || b

-- Numeric literals (should be mutated by numeric-boundary)
def zero : Nat := 0
def one : Nat := 1
def ten : Nat := 10

-- String literals (should be mutated by string-literal)
def greeting : String := "Hello"
def empty : String := ""

-- A more complex function to test nested mutations
def isEven (n : Nat) : Bool := n % 2 == 0

def abs (n : Int) : Int :=
  if n < 0 then -n else n

def max (a b : Nat) : Nat :=
  if a > b then a else b

def min (a b : Nat) : Nat :=
  if a < b then a else b

-- Tests for the sample functions
#guard alwaysTrue == true
#guard alwaysFalse == false
#guard add 2 3 == 5
#guard subtract 5 3 == 2
#guard multiply 3 4 == 12
#guard isEqual 5 5 == true
#guard isLessThan 3 5 == true
#guard isEven 4 == true
#guard isEven 3 == false
#guard max 3 5 == 5
#guard min 3 5 == 3
