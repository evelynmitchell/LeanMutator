/-
  LeanMutator - Literal Mutation Operators

  Operators for mutating literals:
  - String literals: "" → "mutated", swap characters
  - Number literals: handled in Arithmetic.lean
-/

import Lean
import LeanMutator.Mutator.Operators

namespace LeanMutator.Mutator.Literals

open Lean

/-- Check if syntax is a string literal -/
def isStringLiteral (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind _ =>
    kind.toString.startsWith "str" || kind.toString.startsWith "Str"
  | .atom _ val =>
    -- String literals start and end with quotes
    val.length >= 2 && val.front == '"' && val.back == '"'
  | _ => false

/-- Get the string value from a literal (without quotes) -/
def getStringValue (stx : Syntax) : Option String :=
  match stx with
  | .atom _ val =>
    if val.length >= 2 && val.front == '"' && val.back == '"' then
      -- Remove first and last characters (quotes)
      let inner := val.toList.drop 1
      let inner := inner.dropLast
      some (String.mk inner)
    else
      none
  | .node _ _ args =>
    args.findSome? fun arg =>
      match arg with
      | .atom _ val =>
        if val.length >= 2 && val.front == '"' && val.back == '"' then
          let inner := val.toList.drop 1
          let inner := inner.dropLast
          some (String.mk inner)
        else
          none
      | _ => none
  | _ => none

/-- Create a string literal syntax -/
def mkStrLit (s : String) : Syntax :=
  Syntax.atom SourceInfo.none s!"\"{s}\""

/-- Replace string value in syntax -/
partial def replaceStringValue (stx : Syntax) (newVal : String) : Syntax :=
  match stx with
  | .atom info val =>
    if val.length >= 2 && val.front == '"' && val.back == '"' then
      .atom info s!"\"{newVal}\""
    else
      stx
  | .node info kind args =>
    .node info kind (args.map (replaceStringValue · newVal))
  | _ => stx

/-- String literal mutations -/
def stringLiteralOperator : MutationOperator := {
  name := "string-literal"
  description := "Mutate string literals: replace with empty or sentinel value"
  canMutate := isStringLiteral
  mutate := fun stx =>
    match getStringValue stx with
    | some s =>
      let mutations := #[
        (replaceStringValue stx "", s!"\"{s}\" → \"\""),
        (replaceStringValue stx "MUTATED", s!"\"{s}\" → \"MUTATED\"")
      ]
      -- If not empty, also offer empty mutation
      if s.isEmpty then
        #[(replaceStringValue stx "non-empty", "\"\" → \"non-empty\"")]
      else
        mutations
    | none => #[]
}

/-- Check if syntax is a character literal -/
def isCharLiteral (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind _ =>
    kind.toString.startsWith "char" || kind.toString.startsWith "Char"
  | .atom _ val =>
    -- Char literals use single quotes: 'x'
    val.length >= 3 && val.front == '\'' && val.back == '\''
  | _ => false

/-- Get the character from a literal -/
def getCharValue (stx : Syntax) : Option Char :=
  match stx with
  | .atom _ val =>
    if val.length == 3 && val.front == '\'' && val.back == '\'' then
      val.toList[1]?
    else
      none
  | .node _ _ args =>
    args.findSome? fun arg =>
      match arg with
      | .atom _ val =>
        if val.length == 3 && val.front == '\'' && val.back == '\'' then
          val.toList[1]?
        else
          none
      | _ => none
  | _ => none

/-- Replace character in syntax -/
partial def replaceCharValue (stx : Syntax) (newVal : Char) : Syntax :=
  match stx with
  | .atom info val =>
    if val.length == 3 && val.front == '\'' && val.back == '\'' then
      .atom info s!"'{newVal}'"
    else
      stx
  | .node info kind args =>
    .node info kind (args.map (replaceCharValue · newVal))
  | _ => stx

/-- Character literal mutations -/
def charLiteralOperator : MutationOperator := {
  name := "char-literal"
  description := "Mutate character literals"
  canMutate := isCharLiteral
  mutate := fun stx =>
    match getCharValue stx with
    | some c =>
      let mutations := #[]
      -- Change to space
      let mutations := if c != ' ' then
        mutations.push (replaceCharValue stx ' ', s!"'{c}' → ' '")
      else mutations
      -- Change to 'a' or 'z'
      let mutations := if c != 'a' then
        mutations.push (replaceCharValue stx 'a', s!"'{c}' → 'a'")
      else if c != 'z' then
        mutations.push (replaceCharValue stx 'z', s!"'{c}' → 'z'")
      else mutations
      -- Change to '0'
      let mutations := if c.isAlpha then
        mutations.push (replaceCharValue stx '0', s!"'{c}' → '0'")
      else mutations
      mutations
    | none => #[]
}

/-- All literal mutation operators -/
def allOperators : Array MutationOperator := #[
  stringLiteralOperator,
  charLiteralOperator
]

end LeanMutator.Mutator.Literals
