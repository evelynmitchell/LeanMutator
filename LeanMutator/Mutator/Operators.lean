/-
  LeanMutator - Mutation Operators Registry

  This module defines the core mutation operator abstraction and registry.
-/

import Lean

namespace LeanMutator.Mutator

open Lean

/-- Represents a location in source code -/
structure SourceLocation where
  file : System.FilePath
  startLine : Nat
  startCol : Nat
  endLine : Nat
  endCol : Nat
  deriving Repr, Inhabited, BEq

/-- Convert a Lean SourceInfo to our SourceLocation -/
def SourceLocation.fromSourceInfo? (file : System.FilePath) (info : SourceInfo) : Option SourceLocation :=
  match info with
  | .original leading pos trailing endPos =>
    -- Get position info from the FileMap would require the map
    -- For now we use a simplified version based on positions
    some {
      file := file
      startLine := 0  -- Will be filled in during traversal
      startCol := pos.byteIdx
      endLine := 0
      endCol := endPos.byteIdx
    }
  | .synthetic pos endPos _ =>
    some {
      file := file
      startLine := 0
      startCol := pos.byteIdx
      endLine := 0
      endCol := endPos.byteIdx
    }
  | .none => none

/-- A mutation represents a single code change -/
structure Mutation where
  /-- File containing the mutation -/
  file : System.FilePath
  /-- Location in the source -/
  location : SourceLocation
  /-- Original source text -/
  original : String
  /-- Mutated source text -/
  mutated : String
  /-- Name of the operator that created this mutation -/
  operator : String
  /-- Unique ID for this mutation -/
  id : Nat := 0
  deriving Repr, Inhabited

/-- Status of a mutation after testing -/
inductive MutationStatus where
  | pending   : MutationStatus  -- Not yet tested
  | killed    : MutationStatus  -- Test failed (good!)
  | survived  : MutationStatus  -- Test passed (bad - weak test)
  | timeout   : MutationStatus  -- Test exceeded time limit
  | error     : MutationStatus  -- Build or runtime error
  deriving Repr, Inhabited, BEq

instance : ToString MutationStatus where
  toString s := match s with
    | .pending => "pending"
    | .killed => "killed"
    | .survived => "survived"
    | .timeout => "timeout"
    | .error => "error"

/-- Result of testing a mutation -/
structure MutationResult where
  mutation : Mutation
  status : MutationStatus
  duration : Nat  -- milliseconds
  message : String := ""
  deriving Repr, Inhabited

/-- A mutation operator that can be applied to Lean syntax.

  Mutation operators are the core abstraction for defining what kinds of
  mutations LeanMutator can apply. Each operator specifies:
  - A name for identification and filtering
  - A predicate to match applicable syntax nodes
  - A function to generate mutated alternatives
-/
structure MutationOperator where
  /-- Unique name identifying this operator -/
  name : String
  /-- Description of what this operator does -/
  description : String
  /-- Check if this operator applies to the given syntax -/
  canMutate : Syntax → Bool
  /-- Generate all possible mutations for the given syntax.
      Returns an array of (mutated syntax, description) pairs. -/
  mutate : Syntax → Array (Syntax × String)
  deriving Inhabited

/-- Registry of all available mutation operators -/
structure OperatorRegistry where
  operators : Array MutationOperator
  deriving Inhabited

/-- Create an empty operator registry -/
def OperatorRegistry.empty : OperatorRegistry :=
  { operators := #[] }

/-- Register a new operator -/
def OperatorRegistry.register (reg : OperatorRegistry) (op : MutationOperator) : OperatorRegistry :=
  { operators := reg.operators.push op }

/-- Get all operators -/
def OperatorRegistry.all (reg : OperatorRegistry) : Array MutationOperator :=
  reg.operators

/-- Get operators by name (supports comma-separated list) -/
def OperatorRegistry.getByNames (reg : OperatorRegistry) (names : Array String) : Array MutationOperator :=
  if names.isEmpty then
    reg.operators
  else
    reg.operators.filter (fun op => names.contains op.name)

/-- List all operator names -/
def OperatorRegistry.listNames (reg : OperatorRegistry) : Array String :=
  reg.operators.map (·.name)

end LeanMutator.Mutator
