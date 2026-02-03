/-
  LeanMutator - Core Library Exports

  This module re-exports all the main components of LeanMutator.
-/

-- Mutation operators
import LeanMutator.Mutator.Operators
import LeanMutator.Mutator.Boolean
import LeanMutator.Mutator.Arithmetic
import LeanMutator.Mutator.Comparison
import LeanMutator.Mutator.Literals

-- Engine components
import LeanMutator.Engine.Syntax
import LeanMutator.Engine.Runner
import LeanMutator.Engine.Scheduler
import LeanMutator.Engine.SourceMutator

-- Reporting
import LeanMutator.Report.Console
import LeanMutator.Report.Json
import LeanMutator.Report.Html

namespace LeanMutator

open Mutator

/-- Get all built-in mutation operators -/
def allOperators : Array MutationOperator :=
  Boolean.allOperators ++
  Arithmetic.allOperators ++
  Comparison.allOperators ++
  Literals.allOperators

/-- Create a registry with all built-in operators -/
def defaultRegistry : OperatorRegistry :=
  allOperators.foldl (init := OperatorRegistry.empty) (·.register ·)

end LeanMutator
