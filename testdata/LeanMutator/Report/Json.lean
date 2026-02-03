/-
  LeanMutator - JSON Output

  Machine-readable JSON output for CI/CD integration.
-/

import Lean.Data.Json
import LeanMutator.Mutator.Operators
import LeanMutator.Engine.Scheduler

namespace LeanMutator.Report.Json

open Lean Json
open LeanMutator.Mutator
open LeanMutator.Engine.Scheduler

/-- Convert MutationStatus to JSON string -/
def statusToJson (status : MutationStatus) : String :=
  match status with
  | .pending => "pending"
  | .killed => "killed"
  | .survived => "survived"
  | .timeout => "timeout"
  | .error => "error"

/-- Convert SourceLocation to JSON -/
def locationToJson (loc : SourceLocation) : Json :=
  Json.mkObj [
    ("file", Json.str loc.file.toString),
    ("startLine", Json.num loc.startLine),
    ("startCol", Json.num loc.startCol),
    ("endLine", Json.num loc.endLine),
    ("endCol", Json.num loc.endCol)
  ]

/-- Convert Mutation to JSON -/
def mutationToJson (m : Mutation) : Json :=
  Json.mkObj [
    ("id", Json.num m.id),
    ("file", Json.str m.file.toString),
    ("location", locationToJson m.location),
    ("original", Json.str m.original),
    ("mutated", Json.str m.mutated),
    ("operator", Json.str m.operator)
  ]

/-- Convert MutationResult to JSON -/
def resultToJson (r : MutationResult) : Json :=
  Json.mkObj [
    ("mutation", mutationToJson r.mutation),
    ("status", Json.str (statusToJson r.status)),
    ("duration", Json.num r.duration),
    ("message", Json.str r.message)
  ]

/-- Convert MutationStats to JSON -/
def statsToJson (s : MutationStats) : Json :=
  -- Convert Float score to a numeric string representation
  let scoreStr := toString s.score
  Json.mkObj [
    ("total", Json.num s.total),
    ("killed", Json.num s.killed),
    ("survived", Json.num s.survived),
    ("timedOut", Json.num s.timedOut),
    ("errors", Json.num s.errors),
    ("score", Json.str scoreStr),
    ("totalTime", Json.num s.totalTime)
  ]

/-- Generate full JSON report -/
def generateReport (results : Array MutationResult) (stats : MutationStats) : Json :=
  Json.mkObj [
    ("version", Json.str "1.0"),
    ("generator", Json.str "LeanMutator"),
    ("stats", statsToJson stats),
    ("mutations", Json.arr (results.map resultToJson))
  ]

/-- Generate JSON report as string -/
def generateReportString (results : Array MutationResult) (stats : MutationStats)
    (pretty : Bool := true) : String :=
  let json := generateReport results stats
  if pretty then
    json.pretty
  else
    json.compress

/-- Write JSON report to file -/
def writeReport (path : System.FilePath) (results : Array MutationResult)
    (stats : MutationStats) : IO Unit := do
  let content := generateReportString results stats true
  IO.FS.writeFile path content

/-- Generate summary JSON (just stats, no mutation details) -/
def generateSummary (stats : MutationStats) : String :=
  (statsToJson stats).pretty

end LeanMutator.Report.Json
