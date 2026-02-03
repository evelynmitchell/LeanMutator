/-
  LeanMutator - Source-Level Mutation Detection

  This module provides source-level pattern matching for mutation points.
  It complements the syntax tree approach by directly scanning source code
  for operators that the parser might not recognize as infix notation.
-/

import LeanMutator.Mutator.Operators

namespace LeanMutator.Engine.SourceMutator

open LeanMutator.Mutator

/-- A source-level mutation pattern -/
structure SourcePattern where
  /-- Pattern to search for in source -/
  pattern : String
  /-- Replacement patterns with descriptions -/
  replacements : Array (String × String)
  /-- Operator name -/
  operatorName : String
  deriving Repr, Inhabited

/-- Arithmetic operator patterns -/
def arithmeticPatterns : Array SourcePattern := #[
  { pattern := " + ", replacements := #[(" - ", "+ → -")], operatorName := "arithmetic-add-sub" },
  { pattern := " - ", replacements := #[(" + ", "- → +")], operatorName := "arithmetic-add-sub" },
  { pattern := " * ", replacements := #[(" / ", "* → /")], operatorName := "arithmetic-mul-div" },
  { pattern := " / ", replacements := #[(" * ", "/ → *")], operatorName := "arithmetic-mul-div" },
  { pattern := " % ", replacements := #[(" / ", "% → /")], operatorName := "arithmetic-mod" }
]

/-- Comparison operator patterns -/
def comparisonPatterns : Array SourcePattern := #[
  { pattern := " == ", replacements := #[(" != ", "== → !=")], operatorName := "comparison-equality" },
  { pattern := " != ", replacements := #[(" == ", "!= → ==")], operatorName := "comparison-equality" },
  { pattern := " < ", replacements := #[(" <= ", "< → <="), (" > ", "< → >")], operatorName := "comparison-relational" },
  { pattern := " <= ", replacements := #[(" < ", "<= → <"), (" >= ", "<= → >=")], operatorName := "comparison-relational" },
  { pattern := " > ", replacements := #[(" >= ", "> → >="), (" < ", "> → <")], operatorName := "comparison-relational" },
  { pattern := " >= ", replacements := #[(" > ", ">= → >"), (" <= ", ">= → <=")], operatorName := "comparison-relational" }
]

/-- Logical operator patterns -/
def logicalPatterns : Array SourcePattern := #[
  { pattern := " && ", replacements := #[(" || ", "&& → ||")], operatorName := "boolean-and-or" },
  { pattern := " || ", replacements := #[(" && ", "|| → &&")], operatorName := "boolean-and-or" },
  { pattern := " ∧ ", replacements := #[(" ∨ ", "∧ → ∨")], operatorName := "boolean-and-or" },
  { pattern := " ∨ ", replacements := #[(" ∧ ", "∨ → ∧")], operatorName := "boolean-and-or" }
]

/-- All source-level patterns -/
def allPatterns : Array SourcePattern :=
  arithmeticPatterns ++ comparisonPatterns ++ logicalPatterns

/-- Find all occurrences of a pattern in source -/
def findPatternOccurrences (source : String) (pattern : String) : Array Nat := Id.run do
  let mut positions : Array Nat := #[]
  let mut pos := 0
  while pos < source.length do
    let rest := source.drop pos
    if rest.startsWith pattern then
      positions := positions.push pos
      pos := pos + pattern.length
    else
      pos := pos + 1
  positions

/-- Convert byte position to line number and column -/
def positionToLineCol (source : String) (pos : Nat) : (Nat × Nat) := Id.run do
  let chars := source.toList.take pos
  let mut line := 1
  let mut col := 1
  for c in chars do
    if c == '\n' then
      line := line + 1
      col := 1
    else
      col := col + 1
  (line, col)

/-- Find source-level mutations in a file -/
def findSourceMutations (source : String) (file : System.FilePath) (nextId : IO.Ref Nat)
    : IO (Array Mutation) := do
  let mut mutations : Array Mutation := #[]

  for pattern in allPatterns do
    let occurrences := findPatternOccurrences source pattern.pattern
    for pos in occurrences do
      let (line, col) := positionToLineCol source pos

      for (replacement, desc) in pattern.replacements do
        let id ← nextId.get
        nextId.set (id + 1)

        let loc : SourceLocation := {
          file := file
          startLine := line
          startCol := col
          endLine := line
          endCol := col + pattern.pattern.length
        }

        mutations := mutations.push {
          file := file
          location := loc
          original := pattern.pattern
          mutated := replacement
          operator := s!"{pattern.operatorName}: {desc}"
          id := id
        }

  return mutations

/-- Apply a source-level mutation -/
def applySourceMutation (source : String) (mutation : Mutation) : String := Id.run do
  -- Find the position in source based on line/col
  let mut currentLine := 1
  let mut currentCol := 1
  let mut bytePos := 0

  for c in source.toList do
    if currentLine == mutation.location.startLine && currentCol == mutation.location.startCol then
      break
    if c == '\n' then
      currentLine := currentLine + 1
      currentCol := 1
    else
      currentCol := currentCol + 1
    bytePos := bytePos + 1

  -- Apply replacement
  let before := (source.take bytePos).toString
  let after := (source.drop (bytePos + mutation.original.length)).toString
  before ++ mutation.mutated ++ after

end LeanMutator.Engine.SourceMutator
