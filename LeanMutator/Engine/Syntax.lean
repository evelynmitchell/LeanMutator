/-
  LeanMutator - Syntax Tree Traversal & Manipulation

  This module provides utilities for:
  - Parsing Lean files to syntax trees
  - Traversing syntax trees to find mutation points
  - Applying mutations and generating modified source
-/

import Lean
import LeanMutator.Mutator.Operators

namespace LeanMutator.Engine.Syntax

open Lean
open LeanMutator.Mutator

/-- Result of finding mutation points in a file -/
structure MutationPoint where
  /-- The syntax node that can be mutated -/
  stx : Lean.Syntax
  /-- The operator that matched -/
  op : MutationOperator
  /-- Position in the original source (byte index) -/
  positionIdx : Nat
  /-- The original source text for this node -/
  originalText : String
  deriving Inhabited

/-- Context for syntax traversal -/
structure TraversalContext where
  /-- Original source code -/
  source : String
  /-- File path -/
  file : System.FilePath
  /-- Available mutation operators -/
  operators : Array MutationOperator
  /-- Current mutation ID counter -/
  nextId : IO.Ref Nat

/-- Create a new traversal context -/
def TraversalContext.new (source : String) (file : System.FilePath)
    (operators : Array MutationOperator) : IO TraversalContext := do
  let nextId ← IO.mkRef 0
  return { source, file, operators, nextId }

/-- Get next mutation ID -/
def TraversalContext.freshId (ctx : TraversalContext) : IO Nat := do
  let id ← ctx.nextId.get
  ctx.nextId.set (id + 1)
  return id

/-- Extract source text for a syntax node -/
def extractSourceText (source : String) (s : Lean.Syntax) : String :=
  -- Get the position range from syntax
  match s.getPos?, s.getTailPos? with
  | some startPos, some endPos =>
    let startIdx := startPos.byteIdx
    let endIdx := endPos.byteIdx
    if startIdx < source.length && endIdx <= source.length && startIdx < endIdx then
      -- Extract using character positions
      let chars := source.toList
      String.ofList (chars.drop startIdx |>.take (endIdx - startIdx))
    else
      s.prettyPrint.pretty
  | _, _ => s.prettyPrint.pretty

/-- Pretty print syntax back to source -/
def syntaxToString (s : Lean.Syntax) : String :=
  s.prettyPrint.pretty

/-- Traverse syntax tree and find all mutation points -/
partial def findMutationPoints (ctx : TraversalContext) (s : Lean.Syntax)
    : IO (Array MutationPoint) := do
  let mut points : Array MutationPoint := #[]

  -- Check each operator against this node
  for op in ctx.operators do
    if op.canMutate s then
      let posIdx := match s.getPos? with
        | some pos => pos.byteIdx
        | none => 0
      let originalText := extractSourceText ctx.source s
      points := points.push {
        stx := s
        op := op
        positionIdx := posIdx
        originalText := originalText
      }

  -- Recursively process children
  match s with
  | .node _ _ args =>
    for child in args do
      let childPoints ← findMutationPoints ctx child
      points := points ++ childPoints
  | _ => pure ()

  return points

/-- Generate all mutations from mutation points -/
def generateMutations (ctx : TraversalContext) (points : Array MutationPoint)
    : IO (Array Mutation) := do
  let mut mutations : Array Mutation := #[]

  for point in points do
    let mutatedSyntaxes := point.op.mutate point.stx
    for (mutatedStx, desc) in mutatedSyntaxes do
      let id ← ctx.freshId
      let mutatedText := syntaxToString mutatedStx
      let loc : SourceLocation := {
        file := ctx.file
        startLine := 0  -- TODO: compute from FileMap
        startCol := point.positionIdx
        endLine := 0
        endCol := point.positionIdx + point.originalText.length
      }
      mutations := mutations.push {
        file := ctx.file
        location := loc
        original := point.originalText
        mutated := mutatedText
        operator := s!"{point.op.name}: {desc}"
        id := id
      }

  return mutations

/-- Apply a mutation to source code, returning the modified source -/
def applyMutation (source : String) (mutation : Mutation) : String :=
  -- Simple string replacement based on byte positions
  let startIdx := mutation.location.startCol
  let endIdx := mutation.location.endCol
  if startIdx < source.length && endIdx <= source.length then
    let chars := source.toList
    let before := String.ofList (chars.take startIdx)
    let after := String.ofList (chars.drop endIdx)
    before ++ mutation.mutated ++ after
  else
    -- Fallback: try simple find-replace
    source.replace mutation.original mutation.mutated

/-- Parse a Lean file and return the syntax tree -/
def parseFile (path : System.FilePath) : IO (Except String Lean.Syntax) := do
  -- Read the file
  let contents ← IO.FS.readFile path

  -- Use Lean's parser
  let inputCtx := Parser.mkInputContext contents path.toString
  let (header, parserState, messages) ← Parser.parseHeader inputCtx

  -- Check for errors
  if messages.hasErrors then
    let mut errStrs : Array String := #[]
    for msg in messages.toList do
      if msg.severity == .error then
        let msgStr ← msg.data.toString
        errStrs := errStrs.push msgStr
    return .error s!"Parse errors:\n{String.intercalate "\n" errStrs.toList}"

  -- Parse the rest of the file using a simpler approach
  -- For now, just return the header as we can still find mutations in it
  return .ok header

/-- Parse source string and return syntax tree -/
def parseSource (source : String) (fileName : String := "<input>")
    : IO (Except String Lean.Syntax) := do
  let inputCtx := Parser.mkInputContext source fileName
  let (header, _parserState, messages) ← Parser.parseHeader inputCtx

  if messages.hasErrors then
    let mut errStrs : Array String := #[]
    for msg in messages.toList do
      if msg.severity == .error then
        let msgStr ← msg.data.toString
        errStrs := errStrs.push msgStr
    return .error s!"Parse errors:\n{String.intercalate "\n" errStrs.toList}"

  return .ok header

/-- Replace a specific syntax node in a tree -/
partial def replaceSyntax (tree : Lean.Syntax) (target : Lean.Syntax)
    (replacement : Lean.Syntax) : Lean.Syntax :=
  -- Simple identity check based on positions
  if tree.getPos? == target.getPos? && tree.getTailPos? == target.getTailPos? then
    replacement
  else
    match tree with
    | .node info kind args =>
      .node info kind (args.map (replaceSyntax · target replacement))
    | _ => tree

/-- Get all top-level commands from a file syntax -/
def getCommands (s : Lean.Syntax) : Array Lean.Syntax :=
  match s with
  | .node _ _ args => args
  | _ => #[s]

end LeanMutator.Engine.Syntax
