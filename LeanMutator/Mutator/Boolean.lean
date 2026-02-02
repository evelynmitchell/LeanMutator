/-
  LeanMutator - Boolean Mutation Operators

  Operators for mutating boolean expressions:
  - true ↔ false
  - ∧ ↔ ∨
  - ¬p → p
-/

import Lean
import LeanMutator.Mutator.Operators

namespace LeanMutator.Mutator.Boolean

open Lean

/-- Check if syntax is a boolean literal `true` -/
def isTrue (stx : Syntax) : Bool :=
  stx.isIdent && stx.getId == `true

/-- Check if syntax is a boolean literal `false` -/
def isFalse (stx : Syntax) : Bool :=
  stx.isIdent && stx.getId == `false

/-- Check if syntax is a boolean literal -/
def isBoolLiteral (stx : Syntax) : Bool :=
  isTrue stx || isFalse stx

/-- Create `true` syntax -/
def mkTrue : Syntax :=
  Syntax.ident SourceInfo.none "true".toRawSubstring `true []

/-- Create `false` syntax -/
def mkFalse : Syntax :=
  Syntax.ident SourceInfo.none "false".toRawSubstring `false []

/-- Boolean literal flip operator: true ↔ false -/
def booleanFlipOperator : MutationOperator := {
  name := "boolean-flip"
  description := "Flip boolean literals: true → false, false → true"
  canMutate := isBoolLiteral
  mutate := fun stx =>
    if isTrue stx then
      #[(mkFalse, "true → false")]
    else if isFalse stx then
      #[(mkTrue, "false → true")]
    else
      #[]
}

/-- Check if syntax is an `And` (∧) node -/
def isAnd (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind args =>
    -- Check for various forms of And
    kind.toString.startsWith "And" ||
    (args.size >= 2 && args.any (fun a => a.isOfKind `«&&» || a.isOfKind `And))
  | .atom _ val => val == "&&" || val == "∧"
  | _ => false

/-- Check if syntax is an `Or` (∨) node -/
def isOr (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind args =>
    kind.toString.startsWith "Or" ||
    (args.size >= 2 && args.any (fun a => a.isOfKind `«||» || a.isOfKind `Or))
  | .atom _ val => val == "||" || val == "∨"
  | _ => false

/-- Replace And with Or in syntax -/
partial def replaceAndWithOr (stx : Syntax) : Syntax :=
  match stx with
  | .atom info val =>
    if val == "&&" then .atom info "||"
    else if val == "∧" then .atom info "∨"
    else stx
  | .ident info _ name preresolved =>
    if name == `And then .ident info "Or".toRawSubstring `Or preresolved
    else stx
  | .node info kind args =>
    .node info kind (args.map replaceAndWithOr)
  | _ => stx

/-- Replace Or with And in syntax -/
partial def replaceOrWithAnd (stx : Syntax) : Syntax :=
  match stx with
  | .atom info val =>
    if val == "||" then .atom info "&&"
    else if val == "∨" then .atom info "∧"
    else stx
  | .ident info _ name preresolved =>
    if name == `Or then .ident info "And".toRawSubstring `And preresolved
    else stx
  | .node info kind args =>
    .node info kind (args.map replaceOrWithAnd)
  | _ => stx

/-- Boolean And/Or swap operator: ∧ ↔ ∨ -/
def booleanAndOrOperator : MutationOperator := {
  name := "boolean-and-or"
  description := "Swap boolean operators: && ↔ ||, ∧ ↔ ∨"
  canMutate := fun stx => isAnd stx || isOr stx
  mutate := fun stx =>
    if isAnd stx then
      #[(replaceAndWithOr stx, "∧ → ∨")]
    else if isOr stx then
      #[(replaceOrWithAnd stx, "∨ → ∧")]
    else
      #[]
}

/-- Check if syntax is a negation (¬ or !) -/
def isNegation (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind args =>
    kind.toString.startsWith "not" ||
    kind.toString.startsWith "Not" ||
    (args.size >= 1 && args.any (fun a =>
      match a with
      | .atom _ val => val == "!" || val == "¬" || val == "not"
      | _ => false))
  | .atom _ val => val == "!" || val == "¬"
  | _ => false

/-- Remove negation from expression -/
def removeNegation (stx : Syntax) : Option Syntax :=
  match stx with
  | .node _ _ args =>
    if args.size >= 2 then
      -- Try to find the operand (usually the last significant arg)
      args.findSome? fun arg =>
        match arg with
        | .node _ _ _ => some arg
        | .ident _ _ _ _ => some arg
        | _ => none
    else
      none
  | _ => none

/-- Boolean negation removal operator: ¬p → p -/
def booleanNegationOperator : MutationOperator := {
  name := "boolean-negation"
  description := "Remove negation: ¬p → p, !x → x"
  canMutate := isNegation
  mutate := fun stx =>
    match removeNegation stx with
    | some inner => #[(inner, "¬p → p")]
    | none => #[]
}

/-- All boolean mutation operators -/
def allOperators : Array MutationOperator := #[
  booleanFlipOperator,
  booleanAndOrOperator,
  booleanNegationOperator
]

end LeanMutator.Mutator.Boolean
