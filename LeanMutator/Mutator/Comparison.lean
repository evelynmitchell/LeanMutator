/-
  LeanMutator - Comparison Mutation Operators

  Operators for mutating comparison expressions:
  - = ↔ ≠
  - < ↔ ≤ ↔ > ↔ ≥
  - Boundary: < → =, etc.
-/

import Lean
import LeanMutator.Mutator.Operators

namespace LeanMutator.Mutator.Comparison

open Lean

/-- Comparison operators we recognize -/
def comparisonOps : Array String := #[
  "=", "==", "≠", "!=", "/=",
  "<", "<=", "≤",
  ">", ">=", "≥"
]

/-- Check if a string is a comparison operator -/
def isComparisonOp (val : String) : Bool :=
  comparisonOps.contains val

/-- Check if syntax contains a comparison operator -/
def hasComparisonOp (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind args =>
    args.any fun arg =>
      match arg with
      | .atom _ val => isComparisonOp val
      | .ident _ _ name _ => isComparisonOp name.toString
      | _ => false
  | .atom _ val => isComparisonOp val
  | _ => false

/-- Get the comparison operator from syntax -/
def getComparisonOp (stx : Syntax) : Option String :=
  match stx with
  | .node _ _ args =>
    args.findSome? fun arg =>
      match arg with
      | .atom _ val => if isComparisonOp val then some val else none
      | .ident _ _ name _ =>
        let s := name.toString
        if isComparisonOp s then some s else none
      | _ => none
  | .atom _ val => if isComparisonOp val then some val else none
  | _ => none

/-- Replace a comparison operator in syntax -/
partial def replaceCompOp (stx : Syntax) (oldOp newOp : String) : Syntax :=
  match stx with
  | .atom info val =>
    if val == oldOp then .atom info newOp else stx
  | .ident info rawVal name preresolved =>
    if name.toString == oldOp then
      .ident info newOp.toSubstring (Name.mkSimple newOp) preresolved
    else
      stx
  | .node info kind args =>
    .node info kind (args.map (replaceCompOp · oldOp newOp))
  | _ => stx

/-- Normalize comparison operator to a standard form -/
def normalizeCompOp (op : String) : String :=
  match op with
  | "==" => "="
  | "!=" => "≠"
  | "/=" => "≠"
  | "<=" => "≤"
  | ">=" => "≥"
  | _ => op

/-- Equality operator swap: = ↔ ≠ -/
def equalityOperator : MutationOperator := {
  name := "comparison-equality"
  description := "Swap equality operators: = ↔ ≠, == ↔ !="
  canMutate := fun stx =>
    match getComparisonOp stx with
    | some op => normalizeCompOp op == "=" || normalizeCompOp op == "≠"
    | none => false
  mutate := fun stx =>
    match getComparisonOp stx with
    | some op =>
      let norm := normalizeCompOp op
      if norm == "=" then
        -- Try to use the same style (== vs =)
        let newOp := if op == "==" then "!=" else "≠"
        #[(replaceCompOp stx op newOp, s!"{op} → {newOp}")]
      else if norm == "≠" then
        let newOp := if op == "!=" || op == "/=" then "==" else "="
        #[(replaceCompOp stx op newOp, s!"{op} → {newOp}")]
      else
        #[]
    | none => #[]
}

/-- Relational operator mutations: < ↔ ≤, > ↔ ≥ -/
def relationalOperator : MutationOperator := {
  name := "comparison-relational"
  description := "Mutate relational operators: < ↔ ≤, > ↔ ≥"
  canMutate := fun stx =>
    match getComparisonOp stx with
    | some op => ["<", "<=", "≤", ">", ">=", "≥"].contains op
    | none => false
  mutate := fun stx =>
    match getComparisonOp stx with
    | some "<" => #[
        (replaceCompOp stx "<" "≤", "< → ≤"),
        (replaceCompOp stx "<" ">", "< → >")
      ]
    | some "<=" => #[
        (replaceCompOp stx "<=" "<", "<= → <"),
        (replaceCompOp stx "<=" ">=", "<= → >=")
      ]
    | some "≤" => #[
        (replaceCompOp stx "≤" "<", "≤ → <"),
        (replaceCompOp stx "≤" "≥", "≤ → ≥")
      ]
    | some ">" => #[
        (replaceCompOp stx ">" "≥", "> → ≥"),
        (replaceCompOp stx ">" "<", "> → <")
      ]
    | some ">=" => #[
        (replaceCompOp stx ">=" ">", ">= → >"),
        (replaceCompOp stx ">=" "<=", ">= → <=")
      ]
    | some "≥" => #[
        (replaceCompOp stx "≥" ">", "≥ → >"),
        (replaceCompOp stx "≥" "≤", "≥ → ≤")
      ]
    | _ => #[]
}

/-- Boundary mutations: < → =, > → =, etc. -/
def boundaryOperator : MutationOperator := {
  name := "comparison-boundary"
  description := "Boundary mutations: < → =, > → =, ≤ → =, ≥ → ="
  canMutate := fun stx =>
    match getComparisonOp stx with
    | some op => ["<", "<=", "≤", ">", ">=", "≥"].contains op
    | none => false
  mutate := fun stx =>
    match getComparisonOp stx with
    | some op =>
      if ["<", "<=", "≤", ">", ">=", "≥"].contains op then
        #[(replaceCompOp stx op "=", s!"{op} → =")]
      else
        #[]
    | none => #[]
}

/-- All comparison mutation operators -/
def allOperators : Array MutationOperator := #[
  equalityOperator,
  relationalOperator,
  boundaryOperator
]

end LeanMutator.Mutator.Comparison
