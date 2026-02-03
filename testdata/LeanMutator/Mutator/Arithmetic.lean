/-
  LeanMutator - Arithmetic Mutation Operators

  Operators for mutating arithmetic expressions:
  - + ↔ - ↔ * ↔ /
  - n → n+1, n → n-1, n → 0
-/

import Lean
import LeanMutator.Mutator.Operators

namespace LeanMutator.Mutator.Arithmetic

open Lean

/-- Arithmetic operators we recognize -/
def arithmeticOps : Array String := #["+", "-", "*", "/", "%"]

/-- Check if an atom is an arithmetic operator -/
def isArithmeticOp (val : String) : Bool :=
  arithmeticOps.contains val

/-- Check if syntax contains an arithmetic operator at the top level -/
def hasArithmeticOp (stx : Syntax) : Bool :=
  match stx with
  | .node _ _ args =>
    -- Check if any child is an arithmetic operator
    args.any fun arg =>
      match arg with
      | .atom _ val => isArithmeticOp val
      | _ => false
  | .atom _ val => isArithmeticOp val
  | _ => false

/-- Get the arithmetic operator from a binary expression -/
def getArithmeticOp (stx : Syntax) : Option String :=
  match stx with
  | .node _ _ args =>
    args.findSome? fun arg =>
      match arg with
      | .atom _ val => if isArithmeticOp val then some val else none
      | _ => none
  | .atom _ val => if isArithmeticOp val then some val else none
  | _ => none

/-- Replace an arithmetic operator in syntax -/
partial def replaceArithOp (stx : Syntax) (oldOp newOp : String) : Syntax :=
  match stx with
  | .atom info val =>
    if val == oldOp then .atom info newOp else stx
  | .node info kind args =>
    .node info kind (args.map (replaceArithOp · oldOp newOp))
  | _ => stx

/-- Arithmetic operator swap: + ↔ - -/
def arithmeticAddSubOperator : MutationOperator := {
  name := "arithmetic-add-sub"
  description := "Swap addition and subtraction: + ↔ -"
  canMutate := fun stx =>
    match getArithmeticOp stx with
    | some "+" => true
    | some "-" => true
    | _ => false
  mutate := fun stx =>
    match getArithmeticOp stx with
    | some "+" => #[(replaceArithOp stx "+" "-", "+ → -")]
    | some "-" => #[(replaceArithOp stx "-" "+", "- → +")]
    | _ => #[]
}

/-- Arithmetic operator swap: * ↔ / -/
def arithmeticMulDivOperator : MutationOperator := {
  name := "arithmetic-mul-div"
  description := "Swap multiplication and division: * ↔ /"
  canMutate := fun stx =>
    match getArithmeticOp stx with
    | some "*" => true
    | some "/" => true
    | _ => false
  mutate := fun stx =>
    match getArithmeticOp stx with
    | some "*" => #[(replaceArithOp stx "*" "/", "* → /")]
    | some "/" => #[(replaceArithOp stx "/" "*", "/ → *")]
    | _ => #[]
}

/-- Arithmetic operator mutations: all swaps -/
def arithmeticAllSwapOperator : MutationOperator := {
  name := "arithmetic-swap"
  description := "Swap all arithmetic operators: +, -, *, /"
  canMutate := hasArithmeticOp
  mutate := fun stx =>
    match getArithmeticOp stx with
    | some "+" => #[
        (replaceArithOp stx "+" "-", "+ → -"),
        (replaceArithOp stx "+" "*", "+ → *")
      ]
    | some "-" => #[
        (replaceArithOp stx "-" "+", "- → +"),
        (replaceArithOp stx "-" "/", "- → /")
      ]
    | some "*" => #[
        (replaceArithOp stx "*" "/", "* → /"),
        (replaceArithOp stx "*" "+", "* → +")
      ]
    | some "/" => #[
        (replaceArithOp stx "/" "*", "/ → *"),
        (replaceArithOp stx "/" "-", "/ → -")
      ]
    | some "%" => #[
        (replaceArithOp stx "%" "*", "% → *"),
        (replaceArithOp stx "%" "/", "% → /")
      ]
    | _ => #[]
}

/-- Check if syntax is a numeric literal -/
def isNumericLiteral (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind _ =>
    kind.toString.startsWith "num" ||
    kind.toString.startsWith "Num"
  | .atom _ val =>
    -- Check if it's a number (all digits, possibly with decimal)
    !val.isEmpty && val.all (fun c => c.isDigit || c == '.')
  | _ => false

/-- Get the numeric value from a literal -/
def getNumericValue (stx : Syntax) : Option Int :=
  match stx with
  | .atom _ val => val.toInt?
  | .node _ _ args =>
    args.findSome? fun arg =>
      match arg with
      | .atom _ val => val.toInt?
      | _ => none
  | _ => none

/-- Create a numeric literal syntax -/
def mkNumLit (n : Int) : Syntax :=
  Syntax.atom SourceInfo.none (toString n)

/-- Replace numeric value in syntax -/
partial def replaceNumericValue (stx : Syntax) (newVal : Int) : Syntax :=
  match stx with
  | .atom info val =>
    if val.toInt?.isSome then
      .atom info (toString newVal)
    else
      stx
  | .node info kind args =>
    .node info kind (args.map (replaceNumericValue · newVal))
  | _ => stx

/-- Boundary mutation: n → n+1, n → n-1, n → 0 -/
def numericBoundaryOperator : MutationOperator := {
  name := "numeric-boundary"
  description := "Boundary mutations: n → n+1, n → n-1, n → 0"
  canMutate := isNumericLiteral
  mutate := fun stx =>
    match getNumericValue stx with
    | some n =>
      let mutations := #[
        (replaceNumericValue stx (n + 1), s!"{n} → {n + 1}"),
        (replaceNumericValue stx (n - 1), s!"{n} → {n - 1}")
      ]
      -- Add n → 0 if n is not already 0
      if n != 0 then
        mutations.push (replaceNumericValue stx 0, s!"{n} → 0")
      else
        mutations
    | none => #[]
}

/-- All arithmetic mutation operators -/
def allOperators : Array MutationOperator := #[
  arithmeticAddSubOperator,
  arithmeticMulDivOperator,
  arithmeticAllSwapOperator,
  numericBoundaryOperator
]

end LeanMutator.Mutator.Arithmetic
